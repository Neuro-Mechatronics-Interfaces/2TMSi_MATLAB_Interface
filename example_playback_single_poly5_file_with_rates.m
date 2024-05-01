%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_WITH_RATES
clear;
close all force;
clc;

MY_FILE = fullfile(pwd,'Max_2024_03_30_B_22.poly5');
TRIGS_CH = 73;
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
MIN_SAMPLE_DELAY = 0.030; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 50; % microvolts
HORIZONTAL_SCALE = 0.5; % seconds
SAMPLE_RATE_RECORDING = 4000;
MIN_CHANNELWISE_RMS = 0.05; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 5;
TRIGS_LIMIT = [0 1030];
MAX_RATE_SCALE = 5;
ALPHA = 0.15;

%% Load neural net
load('2024-04-15_Extensor-Softmax-Test2.mat','net','meta');
nClusters = net.outputs{1}.size;
[~,finfo,~] = fileparts(MY_FILE);
finfo = strsplit(finfo, "_");
SAGA = finfo{5};

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');
full_rates = nan(nClusters,poly5.header.num_samples);

% Estimate how long to pause between each read iteration:
sample_delay = max(poly5.header.num_samples_per_block*2/poly5.header.sample_rate-ALGORITHMIC_LATENCY_ESTIMATE, MIN_SAMPLE_DELAY);
h_scale = round(poly5.header.sample_rate*HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

%%
% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',[150   50   720   750]);
L = tiledlayout(fig,6,1);
ax = nexttile(L,1,[3 1]);
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
past_samples = zeros(64,1);

clus_ax = nexttile(L,4,[1 1]);
set(clus_ax,'NextPlot','add','FontName','Tahoma','YLim',[0,net.outputs{1}.size],'XLim',[0,h_scale]);
title(clus_ax,'Sorted','FontName','Tahoma','Color','k');
hs = gobjects(nClusters);
clus_cols = jet(nClusters);
for iH = 1:nClusters
    hs(iH) = scatter(clus_ax,[],[],32,clus_cols(iH,:),"Marker","|","MarkerEdgeColor",clus_cols(iH,:),'LineWidth',1.5);
end

rates_ax = nexttile(L,5,[1 1]);
set(rates_ax,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none', ...
    'YLim', [0, nClusters+3]);
h_rates = gobjects(nClusters,1);
for iH = 1:nClusters
    h_rates(iH) = line(rates_ax,(1:h_scale), ...
                    nan(1,h_scale), ...
                    'Color',clus_cols(iH,:),...
                    'LineWidth',1.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
end
title(rates_ax,'MUAP IFR','FontName','Tahoma','Color','k');

trigs_ax = nexttile(L,6,[1 1]);
set(trigs_ax,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none');
h_trigs = line(trigs_ax,(1:h_scale), ...
                    nan(1,h_scale), ...
                    'Color','m',...
                    'LineWidth',1.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
ylim(trigs_ax,TRIGS_LIMIT);
title(trigs_ax,'Triggers','FontName','Tahoma','Color','k');

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
[b,a] = butter(3,0.25,'high');
[b_rate,a_rate] = butter(3,0.05,'low');
z_rate = zeros(nClusters,3);
zi = zeros(3,64);

warning('off','signal:findpeaks:largeMinPeakHeight');
cols = jet(20);
locs = cell(64,1);
config = load_spike_server_config();
muap_server = tcpserver("0.0.0.0",config.TCP.MUAPServer.Port);
past_rates = zeros(nClusters,1);
samplesPrior = 0;
new_rates = zeros(nClusters,1);
iClus = 1:nClusters;
while isvalid(fig)
    samples = read_next_n_blocks(poly5, 2);
    if needs_initial_ts
        index0 = samples(end,1);
        ts0 = index0/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    sampleCount = samples(end,:)-index0+1;
    iVec = rem(sampleCount-1,h_scale)+1;
    if any(iVec == 0)
        iVec(iVec == 0) = max(iVec);
    end

    [data,zi] = filter(b,a,samples(2:65,:)',zi,1);
    data(:,meta.channels.exclude_pre) = nan;
    data = reshape(del2(reshape(data,[],8,8)),[],64);
    for iH = 1:64
        h(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        % [~,locs] = findpeaks(data(:,iH),'MinPeakHeight', MIN_PK_HEIGHT);
        if ismember(iH, meta.channels.keep_post)
            locs{iH} = find(data(:,iH) > MIN_PK_HEIGHT);
            h(iH).MarkerIndices = setdiff(h(iH).MarkerIndices, iVec);
            if ~isempty(locs{iH})
                locs{iH} = locs{iH}([true; diff(locs{iH})>1]);
                h(iH).MarkerIndices = [h(iH).MarkerIndices, iVec(locs{iH})];
            end
        end
    end
    h_trigs.YData(iVec) = samples(TRIGS_CH,:);
    all_locs = unique(vertcat(locs{:}));
    nSamples = size(data,1);
    [~,clus] = max(net(data(all_locs,meta.channels.keep_post)'),[],1);
    session_rates = zeros(nClusters,1);
    for iH = 1:nClusters
        i_remove = ismember(hs(iH).XData,iVec);
        i_cur = all_locs(clus==iH);
        set(hs(iH),...
            'XData',hs(iH).XData(~i_remove), ...
            'YData',hs(iH).YData(~i_remove));
        set(hs(iH),'XData',[hs(iH).XData, iVec(i_cur)], ...
            'YData',[hs(iH).YData, ones(1,numel(i_cur)).*iClus(iH)]);
        new_rates(iH) = ALPHA * sqrt(sum(clus==iH)/(nSamples/4000)) + (1-ALPHA)*past_rates(iH,1);
        rate_update = interp1([sampleCount(1)-1, sampleCount(end)], ...
            [past_rates(iH,1),new_rates(iH)],[sampleCount(1)-1,sampleCount],'pchip');
        [rate_update, z_rate(iH,:)] = filter(b_rate, a_rate, rate_update((end-nSamples+1):end), z_rate(iH,:));
        h_rates(iH).YData(iVec) = rate_update./MAX_RATE_SCALE + (iClus(iH)-1);
        full_rates(iH,sampleCount) = rate_update;
        past_rates(iH,1) = rate_update(end);
        session_rates(iH) = median(h_rates(iH).YData(~isnan(h_rates(iH).YData))-iClus(iH));
    end
    samplesPrior = sampleCount(end);
    % [~,iClus] = sort(session_rates,'ascend');
    % hb.YData = rms(data,1);
    drawnow();
    if muap_server.Connected
        packet = struct('n', nSamples, 'SAGA', SAGA, 'sample', all_locs, 'cluster', clus);
        writeline(muap_server, jsonencode(packet));
    end
    % past_samples = samples(2:65,end);
    % pause(sample_delay);
end
warning('on','signal:findpeaks:largeMinPeakHeight');
poly5.close();

%% Plot full session rates
full_rates(:,any(isnan(full_rates),1)) = [];
t_full = (0:(size(full_rates,2)-1))./4000;
fig = figure('Color','w','Name','Full Session Rates'); 
ax = axes(fig,'NextPlot','add','ColorOrder',clus_cols,'FontName','Tahoma'); 
% plot(ax,t_full, zscore(full_rates',0,1)-mean(zscore(full_rates',0,1),2)); 
plot(ax,t_full, movstd(full_rates',4001,0,1)); 
title(ax,'Full Session Rate Estimates','FontName','Tahoma','Color','k'); 
ylabel(ax,'Rate (Z-Score)'); 
xlabel(ax, 'Time (s)');