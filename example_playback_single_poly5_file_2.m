%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_2
clear;
close all force;
clc;

MY_FILE = fullfile(pwd,'Max_2024_03_30_B_22.poly5');
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
MIN_SAMPLE_DELAY = 0.030; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 25; % microvolts
HORIZONTAL_SCALE = 0.5; % seconds
SAMPLE_RATE_RECORDING = 4000;
MIN_CHANNELWISE_RMS = 0.1; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 7.5;
N_FACTOR = 4;
FC_BPF = [20,50]; % Bandpass for envelope
FC_HPF = 100;
FC_LOW = 1;

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');

% Estimate how long to pause between each read iteration:
sample_delay = max(poly5.header.num_samples_per_block*2/poly5.header.sample_rate-ALGORITHMIC_LATENCY_ESTIMATE, MIN_SAMPLE_DELAY);
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
past_samples = zeros(64,1);

factors_ax = nexttile(L,5,[1 1]);
% set(factors_ax,'NextPlot','add','FontName','Tahoma','XLim',[0,h_scale]);
set(factors_ax,'NextPlot','add','FontName','Tahoma');
title(factors_ax,'Factors','FontName','Tahoma','Color','k');
% h_factor = gobjects(N_FACTOR,1);
% factor_colors = jet(N_FACTOR);
% for iH = 1:N_FACTOR
%     h_factor(iH) = line(factors_ax,(1:h_scale),nan(1,h_scale), ...
%         'Color',factor_colors(iH,:), ...
%         'LineWidth', 0.75, 'LineStyle','-');
% end

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

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;

while isvalid(fig)
    samples = read_next_n_blocks(poly5, 2);
    if needs_initial_ts
        ts0 = samples(end,1)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    iVec = rem(samples(end,:)-1,h_scale)+1;
    [hpf_data,zi_hpf] = filter(b_hpf,a_hpf,samples(2:65,:)',zi_hpf,1);
    hpf_data = reshape(del2(reshape(hpf_data,[],8,8)),[],64);
    for iH = 1:64
        h(iH).YData(iVec) = hpf_data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    % [bpf_data,zi_bpf] = filter(b_bpf,a_bpf,samples(2:65,:)',zi_bpf,1);
    % H = movmean(movvar([Hpast,lsqnonneg_matrix(hpf_data',W)]*1e5,13,0,2,"includemissing"),7,2,"includemissing");
    % H = lsqnonneg_matrix(abs(bpf_data'),W);
    % H = lsqnonneg_matrix(abs(hpf_data'),W);
    % [lpf_data,zi_lpf] = filter(b_lpf,a_lpf,H,zi_lpf,2);
    % for iH = 1:N_FACTOR
        % h_factor(iH).YData(iVec) = H(iH,20:end) + iH*2-1;
        % h_factor(iH).YData(iVec) = H(iH,:)*1e5 + iH*2-1;
        % h_factor(iH).YData(iVec) = lpf_data(iH,:)*1e5 + iH*2-1;
    % end
    % Hpast = H(:,(end-18):end);

    [lpf_data,zi_lpf] = filter(b_lpf,a_lpf,abs(hpf_data)',zi_lpf,2);
    H = lsqnonneg_matrix(lpf_data,W);
    set(h_factor_bars,'YData',mean(H,2)*1e3);
    drawnow();
end
poly5.close();