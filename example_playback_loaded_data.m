%EXAMPLE_PLAYBACK_LOADED_DATA  Playback pre-loaded data from prior recording(s)
clear;
close all force;
clc;

% DATA_ROOT = string(pwd);
DATA_ROOT = "C:/MyRepos/MetaLocal/Data/MCP01_2024_04_12/Gestures GUI";
MY_FILES = [fullfile(DATA_ROOT,"Wrist Extension","1712945861.4286742_dev2_-20240412_141741.poly5"); ...
            fullfile(DATA_ROOT,"Wrist Flexion","1712945596.6765876_dev2_-20240412_141316.poly5")];
% MY_FILES = [fullfile(pwd,"MCP01_2024_04_12_A_FLX_4.poly5"); ...
            % fullfile(pwd,"MCP01_2024_04_12_A_FLX_2.poly5")];
MY_FILES = strrep(MY_FILES,"\","/");
UNI_CH = {2:65; 2:65};
TRIGS_CH = [71; 71];
COUNTER_CH = [73; 73];
TRIGGER_BIT = 0;
MY_TITLE = "SAGA-5 (EXT)";

LINE_VERTICAL_OFFSET = 25; % microvolts
HORIZONTAL_SCALE = 0.5; % seconds
% SAMPLE_RATE_RECORDING = 4000;
SAMPLE_RATE_RECORDING = 2000;
MIN_CHANNELWISE_RMS = 0.1; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 7.5;
N_FACTOR = 4;
FC_BPF = [20,50]; % Bandpass for envelope
FC_HPF = 100;
FC_LOW = 1;

%% Open file and estimate scaling/offsets
all_data = [];
first_sample = 0;
for ii = 1:numel(MY_FILES)
    tmp = TMSiSAGA.Poly5.read(MY_FILES(ii));
    tmp_samples = tmp.samples(UNI_CH{ii}, :);
    tmp_samples = [tmp_samples; ii*bitand(tmp.samples(TRIGS_CH(ii),:),2^TRIGGER_BIT)/2^TRIGGER_BIT]; %#ok<*AGROW>
    tmp_samples = [tmp_samples; tmp.samples(COUNTER_CH(ii),:)];
    tmp_samples(end,:) = tmp_samples(end,:) + first_sample - tmp_samples(end,1) + 1;
    first_sample = tmp_samples(end,end);
    all_data = [all_data, tmp_samples]; 
end

%% Setup graphics
% Estimate how long to pause between each read iteration:
h_scale = round(SAMPLE_RATE_RECORDING * HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',[150   50   720   750]);
L = tiledlayout(fig,6,1);
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


title(ax, MY_TITLE,'FontName','Tahoma','Color','k');
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

factors_ax = nexttile(L,5,[1 1]);
set(factors_ax,'NextPlot','add','FontName','Tahoma');
title(factors_ax,'Factors','FontName','Tahoma','Color','k');

sync_ax = nexttile(L,6,[1 1]);
set(sync_ax,'NextPlot','add','FontName','Tahoma','YLim',[-0.1, numel(MY_FILES)+0.1],'YTick',[]);
title(sync_ax,'Sync','FontName','Tahoma','Color','k');
h_sync = line(sync_ax,1:h_scale,nan(1,h_scale),'Color','k','LineStyle','-','LineWidth',1.5);

%% Get filter coefficients
load('2024-04-16_Extensor-NMFs.mat','W'); % Load weights
Hpast = zeros(size(W,2),19);
% set(factors_ax,'YLim',[0,size(W,2)*2+5]);
set(factors_ax,'YLim',[0,2.5]);
h_factor_bars = bar(factors_ax,1:size(W,2),zeros(size(W,2),1),'EdgeColor','none','FaceColor','k');
zi_bpf = zeros(6,64);
[b_bpf,a_bpf] = butter(3,FC_BPF./(SAMPLE_RATE_RECORDING/2),"bandpass");
zi_hpf = zeros(3,64);
[b_hpf,a_hpf] = butter(3,FC_HPF./(SAMPLE_RATE_RECORDING/2),'high');
% zi_lpf = zeros(3,size(W,2));
zi_lpf = zeros(3,64);
[b_lpf,a_lpf] = butter(3,FC_LOW/(SAMPLE_RATE_RECORDING/2),'low');
all_data(1:64,:) = filtfilt(b_hpf,a_hpf,all_data(1:64,:)')';

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
nTotal = size(all_data,2);
step_size = round(h_scale * 0.1);
sample_vec = 1:step_size;
i_blank = (rms(all_data(1:64,:),2) < 1) | (rms(all_data(1:64,:),2) > 100);
% i_blank = 1:18;

while isvalid(fig)
    samples = all_data(:, sample_vec);
    if needs_initial_ts
        ts0 = samples(end,1)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    iVec = rem(samples(end,:)-1,h_scale)+1;
    [hpf_data,zi_hpf] = filter(b_hpf,a_hpf,samples(1:64,:)',zi_hpf,1);
    hpf_data(:,i_blank) = missing;
    hpf_data = reshape(hpf_data,[],8,8);
    % for ii = 1:size(hpf_data,1)
    %     hpf_data(ii,:,:) = fillmissing2(squeeze(hpf_data(ii,:,:)),'linear');
    % end
    hpf_data = reshape(del2(hpf_data),[],64);
    for iH = 1:64
        h(iH).YData(iVec) = hpf_data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    h_sync.YData(iVec) = samples(65,:);
    [lpf_data,zi_lpf] = filter(b_lpf,a_lpf,abs(hpf_data)',zi_lpf,2);
    H = lsqnonneg_matrix(lpf_data,W);
    set(h_factor_bars,'YData',mean(H,2)*1e3);
    drawnow();
    sample_vec = rem(sample_vec + step_size - 1, nTotal) + 1;
end