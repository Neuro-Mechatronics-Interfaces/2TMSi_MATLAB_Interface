%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE
clear;
close all force;
clc;

MY_FILE = fullfile(pwd,'Max_2024_03_30_B_22.poly5');
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
MIN_SAMPLE_DELAY = 0.030; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 25; % microvolts
HORIZONTAL_SCALE = 1.0; % seconds
SAMPLE_RATE_RECORDING = 4000;
MIN_CHANNELWISE_RMS = 0.1; % microvolts
RMS_Y_LIM = [0 5];
MIN_PK_HEIGHT = 7.5;

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
% 
% ax = nexttile(L,5,[1 1]);
% set(ax,'NextPlot','add','FontName','Tahoma','YLim',RMS_Y_LIM);
% hb = bar(ax,1:64,zeros(1,64),'EdgeColor','none','FaceColor','r');
% title(ax,'RMS','FontName','Tahoma');

clus_ax = nexttile(L,5,[1 1]);
set(clus_ax,'NextPlot','add','FontName','Tahoma','YLim',[0,20],'XLim',[0,h_scale]);
title(clus_ax,'Sorted','FontName','Tahoma','Color','k');
hs = gobjects(20,1);
clus_cols = jet(20);
for iH = 1:20
    hs(iH) = scatter(clus_ax,[],[],32,clus_cols(iH,:),"Marker","|","MarkerEdgeColor",clus_cols(iH,:),'LineWidth',1.5);
end

%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
[b,a] = butter(3,0.25,'high');
zi = zeros(3,64);
% iCh = [1,2,3,4,5,6,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38,41,42,43,45,46,47,50,54,55,56,57,58,59,61,62,63];
% iExc = setdiff(1:64,iCh);
iExc = [8, 40, 52];
iCh = [1,2,3,4,5,6,9,10,11,12,13,14,15,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,33,34,35,36,37,38,41,42,43,45,46,47,50,54,55,56,57,58,59,61,62,63];
load('2024-04-04_Extensor-Softmax-Test.mat','net');
warning('off','signal:findpeaks:largeMinPeakHeight');
cols = jet(20);
locs = cell(64,1);
while isvalid(fig)
    samples = read_next_n_blocks(poly5, 2);
    if needs_initial_ts
        ts0 = samples(end,1)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    iVec = rem(samples(end,:)-1,h_scale)+1;
    % plot_data = [past_samples, samples(2:65,:)];
    % diff_data = plot_data(:,2:end) -plot_data(:,1:(end-1));
    % diff_data = diff_data - median(diff_data,1);
    [data,zi] = filter(b,a,samples(2:65,:)',zi,1);
    % data(:,rms(data,1)<MIN_CHANNELWISE_RMS) = nan;
    data(:,iExc) = nan;
    data = reshape(del2(reshape(data,[],8,8)),[],64);
    for iH = 1:64
        h(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        % [~,locs] = findpeaks(data(:,iH),'MinPeakHeight', MIN_PK_HEIGHT);
        locs{iH} = find(abs(data(:,iH)) > MIN_PK_HEIGHT);
        h(iH).MarkerIndices = setdiff(h(iH).MarkerIndices, iVec);
        if ~isempty(locs{iH})
            locs{iH} = locs{iH}([true; diff(locs{iH})>1]);
            h(iH).MarkerIndices = [h(iH).MarkerIndices, iVec(locs{iH})];
        end
    end
    all_locs = unique(vertcat(locs{:}));
    [~,clus] = max(net(data(all_locs,iCh)'),[],1);
    for iH = 1:20
        i_remove = ismember(hs(iH).XData,iVec);
        i_cur = all_locs(clus==iH);
        % hs(iH).XData(i_remove) = [];
        % hs(iH).YData(i_remove) = [];
        % x = hs(iH).XData;
        % y = hs(iH).YData;
        % delete(hs(iH));
        % hs(iH) = scatter(clus_ax, [x, iVec(i_cur)], [y, ones(1,numel(i_cur)).*iH], ...
        %     64, 'Marker', '|', 'MarkerEdgeColor', clus_cols(iH,:), 'LineWidth', 1.5);
        set(hs(iH),...
            'XData',hs(iH).XData(~i_remove), ...
            'YData',hs(iH).YData(~i_remove));
        set(hs(iH),'XData',[hs(iH).XData, iVec(i_cur)], ...
            'YData',[hs(iH).YData, ones(1,numel(i_cur)).*iH]);
    end
    % hb.YData = rms(data,1);
    drawnow();
    % past_samples = samples(2:65,end);
    % pause(sample_delay);
end
warning('on','signal:findpeaks:largeMinPeakHeight');
poly5.close();