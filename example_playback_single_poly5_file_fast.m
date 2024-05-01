%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_FAST Example showing fast playback and broadcast of MUAPs from Poly5 file
clear;
close all force;
clc;

MY_FILE = fullfile(pwd,'Max_2024_03_30_B_22.poly5');
TRIGS_CH = 73;
% MY_FILE = "C:/Data/TMSi/MCP03/MCP03_2024_04_23/MCP03_2024_04_23_B_DISTEXT_15.poly5";
% MY_FILE = "C:/Data/TMSi/MCP03/MCP03_2024_04_23/trial_15_04232024_MCP03_ExtProx-20240423T145055.DATA.poly5";
% TRIGS_CH = 66;
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
SAMPLE_DELAY_LIM = [0.005, 0.020]; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 50; % microvolts
HORIZONTAL_SCALE = 0.5; % seconds
SAMPLE_RATE_RECORDING = 4000;
MIN_CHANNELWISE_RMS = 0.05; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 5;

%% Load neural net
load('2024-04-15_Extensor-Softmax-Test2.mat','net','meta');
[~,finfo,~] = fileparts(MY_FILE);
finfo = strsplit(finfo, "_");
SAGA = finfo{5};

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');

% Estimate how long to pause between each read iteration:
sample_delay = round(min(max(poly5.header.num_samples_per_block*2/poly5.header.sample_rate-ALGORITHMIC_LATENCY_ESTIMATE, SAMPLE_DELAY_LIM(1)),SAMPLE_DELAY_LIM(2)),3);
h_scale = round(poly5.header.sample_rate*HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',[150   50   720   750]);
L = tiledlayout(fig,5,1);

ax = nexttile(L,1,[4 1]);
set(ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XLim',[-10, 8.1*(h_scale+h_spacing)], ...
    'Clipping', 'off');

line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], [-0.4*LINE_VERTICAL_OFFSET, 0.6*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -1.02*(h_scale+h_spacing), 0.65*LINE_VERTICAL_OFFSET, sprintf('%4.1f\\muV', LINE_VERTICAL_OFFSET), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left', 'VerticalAlignment','bottom');
line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*LINE_VERTICAL_OFFSET,-0.4*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -h_spacing, -0.45*LINE_VERTICAL_OFFSET, sprintf('%4.1fms', round(h_scale/(SAMPLE_RATE_RECORDING*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right','VerticalAlignment','top');

[~,f,~] = fileparts(MY_FILE);
title(ax, sprintf("%s: UNI", strrep(f,'_','\_')),'FontName','Tahoma','Color','k');
time_txt = subtitle(ax, 'T = 0.000s', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
h = gobjects(64,1);
cmapdata = winter(64);
for iH = 1:64
    h(iH) = line(ax,(1:h_scale)+floor((iH-1)/8)*(h_scale+h_spacing), ...
                    nan(1,h_scale), ...
                    'Color',cmapdata(iH,:),...
                    'LineWidth',0.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
end

trigs_ax = nexttile(L,5,[1 1]);
set(trigs_ax,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none');
h_trigs = line(trigs_ax,(1:h_scale), ...
                    nan(1,h_scale), ...
                    'Color','m',...
                    'LineWidth',1.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
ylim(trigs_ax,[0,1030]);
title(trigs_ax,'Triggers','FontName','Tahoma','Color','k');

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
[b,a] = butter(3,0.25,'high');
zi = zeros(3,64);

warning('off','signal:findpeaks:largeMinPeakHeight');
cols = jet(20);
locs = cell(64,1);
config = load_spike_server_config();
muap_server = tcpserver("0.0.0.0",config.TCP.MUAPServer.Port);
muap_server.ConnectionChangedFcn = @reportSocketConnectionChange;
configureCallback(muap_server, "terminator", @handleMUAPserverMessages);
while isvalid(fig)
    samples = read_next_n_blocks(poly5, 2);
    if needs_initial_ts
        ts0 = samples(end,1)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    iVec = rem(samples(end,:)-1,h_scale)+1;
    if any(iVec == 0)
        iVec(iVec == 0) = max(iVec);
    end

    [data,zi] = filter(b,a,samples(2:65,:)',zi,1);
    data(:,meta.channels.exclude_pre) = nan;
    data = reshape(del2(reshape(data,[],8,8)),[],64);
    
    for iH = 1:64
        h(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        if ismember(iH, meta.channels.keep_post)
            locs{iH} = find(data(:,iH) > MIN_PK_HEIGHT);
        end
    end
    
    h_trigs.YData(iVec) = samples(TRIGS_CH,:);
    all_locs = unique(vertcat(locs{:}));
    [~,clus] = max(net(data(all_locs,meta.channels.keep_post)'),[],1);

    drawnow();
    if muap_server.Connected
        packet = struct('N', size(data,1), 'Saga', SAGA, 'Sample', all_locs, 'Cluster', clus);
        writeline(muap_server, jsonencode(packet));
    end
    pause(sample_delay);
end
warning('on','signal:findpeaks:largeMinPeakHeight');
poly5.close();