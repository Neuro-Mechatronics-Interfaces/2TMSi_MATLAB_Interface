%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE
clear;
close all force;
clc;

MY_FILE = 'Max_2024_03_30_B_22.poly5';
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
MIN_SAMPLE_DELAY = 0.030; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 200; % microvolts
HORIZONTAL_SCALE = 0.25; % seconds
SAMPLE_RATE_RECORDING = 4000;

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

ax = axes(fig,'NextPlot','add', ...
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
                    'LineStyle','-');
end
past_samples = zeros(64,1);

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
    plot_data = [past_samples, samples(2:65,:)];
    diff_data = plot_data(:,2:end) -plot_data(:,1:(end-1));
    diff_data = diff_data - median(diff_data,1);
    for iH = 1:64
        h(iH).YData(iVec) = diff_data(iH,:)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    drawnow();
    past_samples = samples(2:65,end);
    pause(sample_delay);
end
poly5.close();