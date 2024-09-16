%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_FAST_CKC Example showing fast playback and broadcast of MUAPs from Poly5 file, using whitening of extended data matrix.
clear;
close all force;
clc;

SAGA_UNIT = 'SAGAB';
EXPERIMENT = 'Max_2024_03_30_B_22';
MY_FILE = fullfile(pwd,sprintf('%s.poly5',EXPERIMENT));
MY_CALIBRATION = fullfile(pwd, sprintf('%s_PInv.mat', EXPERIMENT));
TRIGS_CH = 73;
% MY_FILE = "C:/Data/TMSi/MCP03/MCP03_2024_04_23/MCP03_2024_04_23_B_DISTEXT_15.poly5";
% MY_FILE = "C:/Data/TMSi/MCP03/MCP03_2024_04_23/trial_15_04232024_MCP03_ExtProx-20240423T145055.DATA.poly5";
% TRIGS_CH = 66;
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
SAMPLE_DELAY_LIM = [0.0025, 0.010]; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 25; % microvolts
HORIZONTAL_SCALE = 0.25; % seconds
SAMPLE_RATE_RECORDING = 4000;
MIN_CHANNELWISE_RMS = 0.05; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 10;
N_ITERATIONS_CONCATENATE = 4;
N_ITERATIONS_TARGET = N_ITERATIONS_CONCATENATE - 1;

%% Load neural net
load('2024-04-15_Extensor-Softmax-Test2.mat','net','meta');
[~,finfo,~] = fileparts(MY_FILE);
finfo = strsplit(finfo, "_");
SAGA = finfo{5};

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');
load(MY_CALIBRATION, 'w', 'P', 'extFact', 'threshold');
% threshold = threshold;
threshold = threshold * 10;

% extFact = 12;
extOffset = round(extFact/2);
I = eye(64*extFact);
W = w';
% W = zeros(size(w,2),extFact*64);
% for iW = 1:size(w,2)
%     for iCh = 1:64
%         vec = (iCh-1)*extFact + (1:extFact);
%         W(iW,vec) = w(vec,iW);
%     end
% end
% P = I; % Initially
gamma = 35;
n_muap = size(W,1);
MUAP_VERTICAL_OFFSET = 7*LINE_VERTICAL_OFFSET / (n_muap-1);

% Estimate how long to pause between each read iteration:
sample_delay = round(min(max(poly5.header.num_samples_per_block*2/poly5.header.sample_rate-ALGORITHMIC_LATENCY_ESTIMATE, SAMPLE_DELAY_LIM(1)),SAMPLE_DELAY_LIM(2)),3);
h_scale = round(poly5.header.sample_rate*HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Units', 'inches', ...
    'Position', [2 2 10 7.5], ...
    'ToolBar', 'none', ...
    'MenuBar','none');
L = tiledlayout(fig,5,1);

ax = nexttile(L,1,[4 1]);
set(ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XTick', [], 'YTick', [], ...
    'XLim',[-10, 13.1*(h_scale+h_spacing)], ...
    'Clipping', 'off', ...
    'HitTest', 'off', ...
    'Toolbar', [], ...
    'Interactions', []);

line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], [-0.4*LINE_VERTICAL_OFFSET, 0.6*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -1.02*(h_scale+h_spacing), 0.65*LINE_VERTICAL_OFFSET, sprintf('%4.1f \\muV', LINE_VERTICAL_OFFSET), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left', 'VerticalAlignment','bottom');
line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*LINE_VERTICAL_OFFSET,-0.4*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -h_spacing, -0.45*LINE_VERTICAL_OFFSET, sprintf('%4.1fms', round(h_scale/(SAMPLE_RATE_RECORDING*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right','VerticalAlignment','top');

[~,f,~] = fileparts(MY_FILE);
title(ax, sprintf("%s: UNI", strrep(f,'_','\_')),'FontName','Tahoma','Color','k');
time_txt = subtitle(ax, 'T = 0.000s', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
h_orig = gobjects(64,1);
h_muaps = gobjects(n_muap,1);
cmapdata_muaps = spring(n_muap);
for iH = 1:n_muap
    h_muaps(iH) = line(ax,(1:4:(h_scale*4)) + 9*(h_scale+h_spacing), ...
                        nan(1,h_scale), ...
                        'Color',cmapdata_muaps(iH,:),...
                        'LineWidth',0.5, ...
                        'LineStyle','-', ...
                        'Marker', '*', ...
                        'MarkerEdgeColor', 'r', ...
                        'MarkerIndices', []);
end
cmapdata = winter(64);
for iH = 1:64
    h_orig(iH) = line(ax,(1:h_scale)+floor((iH-1)/8)*(h_scale+h_spacing), ...
                    nan(1,h_scale), ...
                    'Color',cmapdata(iH,:),...
                    'LineWidth',0.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
end

trigs_ax = nexttile(L,5,[1 1]);
set(trigs_ax,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none', ...
                    'HitTest', 'off', ...
                    'Toolbar', [], ...
                    'Interactions', []);
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

% %% Load the LSL library
% lslMatlabFolder = fullfile(pwd, '..', 'liblsl-Matlab');
% if exist(lslMatlabFolder,'dir')==0
%     lslMatlabFolder = parameters('liblsl_folder');
%     if exist(lslMatlabFolder, 'dir')==0
%         disp("No valid liblsl-Matlab repository detected on this device.");
%         fprintf(1,'\t->\tTried: "%s"\n', fullfile(pwd, '..', 'liblsl-Matlab'));
%         fprintf(1,'\t->\tTried: "%s"\n', lslMatlabFolder);
%         disp("Please check parameters.m in the 2TMSi_MATLAB_Interface repository, and try again.");
%         pause(30);
%         error("[TMSi]::Missing liblsl-Matlab repository.");
%     end
% end
% addpath(genpath(lslMatlabFolder)); % Adds liblsl-Matlab
% lib_lsl = lsl_loadlib();

% %% Initialize the LSL stream information and outlets
% 
% lsl_info_obj = lsl_streaminfo(lib_lsl, ...
%     SAGA_UNIT, ...       % Name
%     'EMG', ...           % Type
%     numel(poly5.channels), ....   % ChannelCount
%     4000, ...                     % NominalSrate
%     'cf_float32', ...             % ChannelFormat
%     SAGA_UNIT);      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
% chns = lsl_info_obj.desc().append_child('channels');
% for iCh = 1:numel(poly5.channels)
%     c = chns.append_child('channel');
%     c.append_child_value('name', char(poly5.channels(iCh).name));
%     c.append_child_value('label', char(poly5.channels(iCh).name));
%     c.append_child_value('unit', char(poly5.channels(iCh).unit_name));
%     if isfield(poly5.channels(iCh),'type')
%         c.append_child_value('type', TMSiSAGA.TMSiUtils.toChannelTypeString(poly5.channels(iCh).type));
%     end
% end    
% lsl_info_obj.desc().append_child_value('manufacturer', 'NML');
% lsl_info_obj.desc().append_child_value('layout', 'Grid_8_x_8');
% 
% lsl_outlet_obj = lsl_outlet(lsl_info_obj);


%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
[b,a] = butter(3,0.25,'high');
zi = zeros(3,64);

warning('off','signal:findpeaks:largeMinPeakHeight');
cols = jet(20);
msgId = uint16(0);
locs = cell(64,1);
config = load_spike_server_config();
muap_server = tcpserver("0.0.0.0",config.TCP.MUAPServer.Port);
muap_server.ConnectionChangedFcn = @reportSocketConnectionChange;
squiggles_server = tcpserver("0.0.0.0",config.TCP.SquiggleServer.Port);
squiggles_server.UserData = struct('current_channel',1,'has_new_channel',true);
squiggles_server.ConnectionChangedFcn = @reportSocketConnectionChange;
configureCallback(squiggles_server, "terminator", @handleChannelChangeRequest);
configureCallback(muap_server, "terminator", @handleMUAPserverMessages);
cat_locs = [];
cat_clus = [];
cat_data = [];
cat_n = 0;
cat_iter = 0;
prev_data = zeros(extFact,64);
n_samples_prev = extFact;
extVec = repmat(-extFact:-1,1,64);
N_LOOP_MAX = 1000;
% timingData = zeros(N_LOOP_MAX,1);
loopIteration  = 0;

% profile on;
while isvalid(fig) % && loopIteration < N_LOOP_MAX
    % loopIteration = loopIteration + 1;
    % if squiggles_server.UserData.has_new_channel
    %     fprintf(1,'Broadcasting channel-%02d samples.\n', squiggles_server.UserData.current_channel);
    %     squiggles_server.UserData.has_new_channel = false;
    % end
    samples = read_next_n_blocks(poly5, 1);
    % lsl_outlet_obj.push_chunk(samples);
    n_samples = size(samples,2);
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
    % data(:,[40 52]) = randn(n_samples,2).*15;
    cat_data = [prev_data; data];
    % gamma = 0.9 * gamma + 0.1 * rms(data(:)) * sqrt(n_samples);

    % loopTic = tic;
    % This way takes ~ 11.7 +/- 1.2 milliseconds on Max LENOVO Laptop:
    % edata = circshift(repelem(cat_data,1,extFact),extVec);
    % edata = edata(1:n_samples,:);
    % S = eye(n_samples) + edata * (P + I * gamma) * edata';
    % P = P - P*edata'*pinv(S)*edata*P;
    % wedata = P * edata'; 
    % zdata = wedata(extOffset:extFact:end,:); 
    % zdata = W * P * edata';

    % This way takes ~ 13.9 +/- 1.4 milliseconds on Max LENOVO Laptop:
    % edata = fast_extend(cat_data', extFact);
    edata = ckc.extend(cat_data', extFact);
    % n_ext_samples = n_samples_prev + n_samples+extFact-1;
    % S = eye(n_ext_samples) + edata' * (P + I * gamma) * edata;
    % P = P - P*edata*pinv(S)*edata'*P;
    % wedata = P * edata(:,(n_samples_prev + 1):end);
    % zdata = ckc.retract(wedata,extFact,extOffset);
    zdata = W * edata(:,(n_samples_prev+1):(end-extFact+1));

    % timingData(loopIteration) = toc(loopTic);
    prev_data = cat_data((end-extFact+1):end,:);
    % prev_data = cat_data(:,(end-extFact+1):end);
    for iMuap = 1:n_muap
        h_muaps(iMuap).YData(iVec) = 0.75*MUAP_VERTICAL_OFFSET*(-zdata(iMuap,:)<threshold(iMuap))+MUAP_VERTICAL_OFFSET*(iMuap-1);
    end
    for iH = 1:64
        h_orig(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        % h_orig(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        % if ismember(iH, meta.channels.keep_post)
        %     locs{iH} = find(data(:,iH) > MIN_PK_HEIGHT);
        % end
    end
    % 
    h_trigs.YData(iVec) = samples(TRIGS_CH,:);
    % all_locs = unique(vertcat(locs{:}));
    % [~,clus] = max(net(data(all_locs,meta.channels.keep_post)'),[],1);
    % cat_data = [cat_data; int16(data(:,squiggles_server.UserData.current_channel))*10]; %#ok<AGROW>
    % cat_locs = [cat_locs; all_locs + cat_n]; %#ok<AGROW>
    % cat_clus = [cat_clus, clus]; %#ok<AGROW>
    % cat_n = cat_n + n_samples;
    drawnow limitrate;
    % if muap_server.Connected && (cat_iter == N_ITERATIONS_TARGET)
    %     msgId = rem(msgId + 1,65535);
    %     packet = struct('N', cat_n, 'Saga', SAGA, 'Sample', cat_locs, 'Cluster', cat_clus, 'Id', msgId);
    %     writeline(muap_server, jsonencode(packet));
    % end
    % if squiggles_server.Connected && (cat_iter == N_ITERATIONS_TARGET)
    %     msgId = rem(msgId + 1, 65535);
    %     packet = struct('N', cat_n, 'Saga', SAGA, 'Sample', cat_data, 'Channel', squiggles_server.UserData.current_channel, 'Id', msgId);
    %     % packet.Sample = mat2cell(cat_data,size(cat_data,1),ones(1,size(cat_data,2)));
    %     % packet.Channel = mat2cell(squiggles_server.UserData.current_channel,1,numel(squiggles_server.UserData.current_channel));
    %     writeline(squiggles_server, jsonencode(packet));
    % end
    % cat_iter = rem(cat_iter+1,N_ITERATIONS_CONCATENATE);
    % if cat_iter == 0
    %     cat_n = 0;
    %     cat_data = [];
    %     cat_locs = [];
    %     cat_clus = [];
    % end
    % pause(sample_delay);
end
% profile off;
% profile viewer;
warning('on','signal:findpeaks:largeMinPeakHeight');
poly5.close();

% figure('Color','w'); 
% histogram(timingData.*1e3); 
% ylabel("Number of Loop Iterations");
% xlabel('Calculation Time (ms)');
% title(sprintf("%2.1f \\pm %2.1f ms",mean(timingData.*1e3),std(timingData.*1e3)));

% %% Callbacks
%     function handle_new_channel_selection(src, ~) 
%         src.UserData.has_new_channel = true;
%     end