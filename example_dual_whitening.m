%EXAMPLE_DUAL_WHITENING

close all force;
clear;
clc;

%% Choose parameters
TANK = 'Max_2024_06_21';
BLOCK = 11;
EXPERIMENT = sprintf('%s_A_EXT_%d',TANK,BLOCK);
MY_FILE = fullfile('C:\Data\TMSi\Max\Max_2024_06_21',sprintf('%s.poly5',EXPERIMENT));
LINE_VERTICAL_OFFSET = 35; % microvolts
HORIZONTAL_SCALE = 0.050; % seconds
SAMPLE_RATE_RECORDING = 4000;
REMAP = textile_8x8_uni2grid_mapping();
HPF = struct;
[HPF.b,HPF.a] = butter(1,100/(SAMPLE_RATE_RECORDING/2),'high');
N_DROP = 2;
N_COMPONENT = 2;
EPSILON = 15; % microvolts
EXTENSION_FACTOR = 400;
BAD_CH = [25, 33,34,35,36,37];
CHANNEL_VIEW = floor(EXTENSION_FACTOR/2):EXTENSION_FACTOR:(63*EXTENSION_FACTOR+floor(EXTENSION_FACTOR/2));

%% Load data
tic;
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');

% Get some samples into the buffer to initialize filter state
samples = read_next_n_blocks(poly5, 40);
zi = zeros(1,64);
[~,zi] = filter(HPF.b,HPF.a,samples(REMAP,:),zi,2);

% Now read and filter the actual data "chunk"
samples = read_next_n_blocks(poly5, 80); % Will be 110 * 80 = 8800 samples
[data,zi] = filter(HPF.b,HPF.a,samples(REMAP,:),zi,2);
data(BAD_CH,:) = 0;
X = fast_extend(data,EXTENSION_FACTOR); % Will be 8800 + 400 - 1 samples

%% Apply dual-whitening to extended array
[Pw, V, lambda] = dual_whitening(X, N_DROP, N_COMPONENT, EPSILON);

%% Get new samples, project
samples = read_next_n_blocks(poly5,20);
[data,zi] = filter(HPF.b,HPF.a,samples(REMAP,:),zi,2);
data(BAD_CH,:) = 0;
X = fast_extend(data,EXTENSION_FACTOR);
Xw = Pw * X; 

% Compute gain to match original per-channel amplitudes
std_orig = std(X(CHANNEL_VIEW,:), 0, 2);  % original RMS per channel
std_white = std(Xw(CHANNEL_VIEW,:), 0, 2);  % whitened RMS per channel

% Avoid divide-by-zero
gain = std_orig ./ max(std_white,EPSILON);
toc;

%% Plot data
t = 0:(1/SAMPLE_RATE_RECORDING):((size(X,2)-1)/SAMPLE_RATE_RECORDING);
fig = figure('Color','w','Name','Whitened Samples', ...
    'Position',[147   289   998   469]);
L = tiledlayout(fig,1,2);
title(L, ...
    sprintf("Dual-Whitening Comparison: L = %d | Drop = %d | Keep = %d | \\epsilon = %.1f \\muV", ...
       EXTENSION_FACTOR,N_DROP,N_COMPONENT,EPSILON), ...
    'FontName', 'Tahoma', 'Color', 'k');
subtitle(L, strrep(EXPERIMENT,"_", "\_"), 'FontName', 'Tahoma', 'Color', [0.65 0.65 0.65]);
ax = gobjects(2,1);
ax(1) = nexttile(L);
set(ax(1),'NextPlot','add','FontName','Tahoma','ColorOrder',[winter(32);spring(32)],'YColor','none','XColor','k');
title(ax(1),"HPF-Only", 'FontName', 'Tahoma', "Color", 'k');
xlabel(ax(1),'Time (s)', 'FontName', 'Tahoma', 'Color', 'k');

ax(2) = nexttile(L);
set(ax(2),'NextPlot','add','FontName','Tahoma','ColorOrder',[winter(32);spring(32)],'YColor','none','XColor','k');
title(ax(2),"HPF + Whitening", 'FontName', 'Tahoma', "Color", 'k');
xlabel(ax(2),'Time (s)', 'FontName', 'Tahoma', 'Color', 'k');

for iCh = 1:64
    plot(ax(1), t, X(CHANNEL_VIEW(iCh),:)' + (iCh-1)*LINE_VERTICAL_OFFSET, 'LineWidth', 0.75, 'ButtonDownFcn', @(src,~)fprintf(1,'\t->\tChannel-%02d\n',iCh));
    plot(ax(2), t, (Xw(CHANNEL_VIEW(iCh),:).*gain(iCh))' + (iCh-1)*LINE_VERTICAL_OFFSET, 'LineWidth', 0.75, 'ButtonDownFcn', @(src,~)fprintf(1,'\t->\tChannel-%02d\n',iCh));
end

linkaxes(ax,'xy');