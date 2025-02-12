%EXAMPLE_ANALYZE_PACMAN_BINARIES  Analyze Pacman binaries for playback.
close all force;
clear;
clc;

%% Set parameters
%#ok<*UNRCH>
INPUT_FILE ='C:\Program Files (x86)\Steam\userdata\74719047\236450\remote\pce.sav.stmp';
PLAYBACK_FRAMES = false;

%%
% Open the file in binary mode
fid = fopen(INPUT_FILE, 'rb');

% Read the entire file into a vector of unsigned 32-bit integers
data = fread(fid, inf, '*uint8');

% Close the file
fclose(fid);

%% Parse "words" using [203,202] delimiter prior
d = strfind(data',[203,202]);
w = cell(size(d));
for iW = 1:(numel(d)-1)
    w{iW} = data((d(iW)+2):(d(iW+1)-1));
end
w{end} = data(d(end):end);
nBytesPerWord = cellfun(@numel,w);

iTimestamp = find(nBytesPerWord==6);
ts = NaT(numel(iTimestamp),1);
for ii = 1:numel(iTimestamp)
    ts(ii) = datetime(str2double(strjoin(string(w{iTimestamp(ii)}'),""))/1e5,'ConvertFrom','posixtime');
end

%%
% Path to the binary log file
% filename = "C:/Data/TaskLogs/pacman/log_2025-01-27_18-46-19.bin";
filename = "C:/Data/TaskLogs/pacman/Max_2025-01-29_18-29-16.bin";

% Read the log data
logData = io.readPacmanLog(filename);
%% Playback logData
close all force;
fig = figure('Color','w','Name','Frame Playback');
ax = axes(fig,'NextPlot','add','YDir','reverse'); 
ylabel(ax,'Vertical Position (pixel)','FontName','Tahoma','Color','k');
xlabel(ax,'Horizontal Position (pixel)', 'FontName','Tahoma','Color','k');
xlim(ax,[0  1280]);
ylim(ax,[0, 720]);
h = scatter(ax, logData.X(1), logData.Y(1), 'MarkerFaceColor', 'y', 'MarkerEdgeColor','k','Marker','o','SizeData',16);
h_ghost = scatter(ax, nan(1,logData.Properties.UserData.nGhosts), nan(1,logData.Properties.UserData.nGhosts), ...
    'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'r', 'Marker', 'o', 'SizeData', 24);
txt = title(ax,sprintf('%05.2f s: Score = %d',0.0,logData.Score(1)), ...
    'FontName','Tahoma','Color','k');
subtxt = subtitle(ax, sprintf('Bombs = %d | Lives = %d', logData.Bombs(1), logData.Lives(1)), ...
    'FontName','Tahoma','Color',[0.65 0.65 0.65]);
delta_t = mean(diff(logData.Timestamp));
for ii = 1:size(logData,1)
    set(h,'XData',logData.X(ii),'YData',logData.Y(ii));
    % mask = ones(1,logData.Properties.UserData.nGhosts);
    % mask(logData.GhostVisible(ii,:)) = nan;
    set(h_ghost,'XData',logData.GhostX(ii,:),'YData',logData.GhostY(ii,:));
    pause(delta_t); 
    set(txt,'String',sprintf('%05.2f s: Score = %d',logData.Timestamp(ii),logData.Score(ii)));
    set(subtxt,'String',sprintf('Bombs = %d | Lives = %d', logData.Bombs(ii), logData.Lives(ii)));
    drawnow();
end

%%
pattern_length = 162; % Hypothesized size of repeated segments
iStart = 1;
iEnd = floor(length(data(iStart:end))/pattern_length)*pattern_length + iStart - 1;
frames = reshape(data(iStart:iEnd), pattern_length, []);
frame_std = std(double(frames),[],2);

%% Plot full time-series
fig = figure('Color','w');
ax = axes(fig,'NextPlot','add','FontName','Tahoma','FontSize',14);
plot(ax, data, 'Color', 'r', 'LineWidth', 1.25);
xlabel(ax, 'Integer Count', 'FontName','Tahoma','Color','k');
ylabel(ax, 'Encoded Value', 'FontName','Tahoma','Color','k');
title(ax, 'Byte Encoding', 'FontName','Tahoma','Color','k');

%% Plot the "word" timestamps

%% Plot cross-frame standard deviation
fig = figure('Color','w');
ax = axes(fig,"NextPlot",'add');
plot(ax,1:pattern_length,frame_std);
xlabel(ax,"Frame Byte Index");
ylabel(ax,"Cross-Frame Standard Deviation");

%% Playback frames
if PLAYBACK_FRAMES
    fig = figure('Color','w','Name','Frame Playback');
    ax = axes(fig,'NextPlot','add');
    h = line(ax,1:pattern_length,frames(:,1),'Color','k','LineWidth',1.25);
    txt = title(ax,'0%');
    for ii = 1:size(frames,2)
        h.YData = frames(:,ii);
        pause(0.005); drawnow;
        set(txt,'String',sprintf("%d%%",round(100*ii/size(frames,2))));
    end

end