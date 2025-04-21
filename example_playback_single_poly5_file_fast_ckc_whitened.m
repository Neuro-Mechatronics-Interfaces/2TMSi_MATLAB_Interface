%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_FAST_CKC_WHITENED Example showing fast playback and broadcast of MUAPs from Poly5 file, using whitening of extended data matrix to project back onto non-extended channel layout.
clear;
close all force;
clc;

TANK = 'Max_2024_06_21';
BLOCK = 11;
EXPERIMENT = sprintf('%s_A_EXT_%d',TANK,BLOCK);
MY_FILE = fullfile('C:\Data\TMSi\Max\Max_2024_06_21',sprintf('%s.poly5',EXPERIMENT));
MY_CALIBRATION = fullfile('C:\Data\TMSi\Max\Max_2024_06_21', sprintf('%s_Calibrations_%d.mat', TANK, BLOCK));
TRIGS_CH = 73;
LINE_VERTICAL_OFFSET = 35; % microvolts
HORIZONTAL_SCALE = 0.050; % seconds
SAMPLE_RATE_RECORDING = 4000;
N_LOOP_MAX = 2000;
REMAP = textile_8x8_uni2grid_mapping();

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');
% load(MY_CALIBRATION, 'P', 'gamma', 'extFact', 'windowingVector');
extFact = 18;
windowingVector = flattopwin(extFact);
I = eye(64*extFact);
W = zeros(64,extFact*64);
for iCh = 1:64
    vec = (iCh-1)*extFact + (1:extFact);
    W(iCh,vec) = windowingVector;
end
% P = I; % Initially
% R = I; % Also, initially
gamma_schedule = linspace(3e9,15,50);

h_scale = round(poly5.header.sample_rate*HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Units', 'inches', ...
    'Position', [2 2 10 7.5], ...
    'ToolBar', 'none', ...
    'MenuBar','none');
L = tiledlayout(fig,5,4);

ax = nexttile(L,1,[4 4]);
set(ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XTick', [], 'YTick', [], ...
    'XLim',[-10, 17.1*(h_scale+h_spacing)], ...
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
h_muaps = gobjects(64,1);
cmapdata_muaps = spring(64);
for iH = 1:64
    h_muaps(iH) = line(ax,(1:h_scale)+(9+floor((iH-1)/8))*(h_scale+h_spacing), ...
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
                    'MarkerIndices', [], ...
                    'HitTest', 'off');
end

trigs_ax = nexttile(L,17,[1 4]);
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
                    'MarkerIndices', [], ...
                    'HitTest', 'off');
ylim(trigs_ax,[0,1030]);
title(trigs_ax,'Triggers','FontName','Tahoma','Color','k');

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
hpf = struct;
[hpf.b,hpf.a] = butter(3,100/(SAMPLE_RATE_RECORDING/2),'high');
zi = zeros(3,64);

warning('off','signal:findpeaks:largeMinPeakHeight');

prev_data = zeros(extFact,64);
timingData = zeros(N_LOOP_MAX,1);
loopIteration  = 0;
dataBuffer = zeros(64,h_scale);
profile on;
while isvalid(fig) && loopIteration < N_LOOP_MAX
    loopIteration = loopIteration + 1;
    % if loopIteration <= 50
    %     gamma = gamma_schedule(loopIteration);
    %     if loopIteration == 50
    %         disp("Gamma converged to final scheduled value.");
    %     end
    % end
    samples = read_next_n_blocks(poly5, 2);
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

    [data,zi] = filter(hpf.b,hpf.a,samples(REMAP,:)',zi,1);
    % data = apply_del2_textiles(data')';
    % data(:,[40 52]) = randn(n_samples,2).*15;
    cat_data = [prev_data; data];

    loopTic = tic;

    % This way takes ~ 13.9 +/- 1.4 milliseconds on Max LENOVO Laptop:
    edata = fast_extend(cat_data', extFact);
    % % % Commented part: for case of iterative covariance estimate % % %
    % n_ext_samples = extFact + n_samples+extFact-1;
    % S = eye(n_ext_samples)*gamma^6 + edata' * (P + I*gamma^2) * edata;
    % Cholesky decomposition of S
    % C = chol(S);  % Cholesky factorization of S
    % intermediate = C \ (edata' * P);  % Solve C * intermediate = edata' * P
    % P = P - P * (intermediate' * intermediate);  % Update P without pinv

    zdata = fast_proj_eig_dr(edata, extFact, 5, 8, 1);

    % zdata =  W * P * edata(:,(extFact+1):(end-extFact+1));

    timingData(loopIteration) = toc(loopTic);
    prev_data = cat_data((end-extFact+1):end,:);
    % prev_data = cat_data(:,(end-extFact+1):end);
    % dataBuffer(:,iVec) = zdata;
    % set(h_rms,'CData',0.25*interp2(X0,Y0,reshape(rms(zdata,2),8,8),Xg,Yg)+0.75*h_rms.CData);
    for iMuap = 1:64
        h_muaps(iMuap).YData(iVec) = zdata((iMuap-1)*extFact + 1,:)+LINE_VERTICAL_OFFSET*rem((iMuap-1),8);
    end
    for iH = 1:64
        h_orig(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    % 
    h_trigs.YData(iVec) = samples(TRIGS_CH,:);
    drawnow limitrate;
end
profile off;
profile viewer;
warning('on','signal:findpeaks:largeMinPeakHeight');
poly5.close();

figure('Color','w'); 
histogram(timingData.*1e3); 
ylabel("Number of Loop Iterations");
xlabel('Calculation Time (ms)');
title(sprintf("%2.1f \\pm %2.1f ms",mean(timingData.*1e3),std(timingData.*1e3)));

% %% Callbacks
%     function handle_new_channel_selection(src, ~) 
%         src.UserData.has_new_channel = true;
%     end