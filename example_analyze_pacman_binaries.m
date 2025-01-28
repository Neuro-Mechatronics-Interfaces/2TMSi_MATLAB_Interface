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
filename = "C:/Data/TaskLogs/pacman/log_2025-01-27_18-51-20.bin";

% Read the log data
logData = io.readPacmanLog(filename);
chunks = vertcat(logData.Chunk);
chunk_sigma = std(double(chunks),[],1);
%% Playback logData
fig = figure('Color','w','Name','Frame Playback');
ax = axes(fig,'NextPlot','add'); % ,'YLim',[-128 128], 'XLim', [-128 128]);
xlim(ax,[-128 128]);
ylim(ax,[-128, 128]);
% h = line(ax,1:numel(logData(1).Chunk),zeros(1,numel(logData(1).Chunk)),'Color','k','LineWidth',1.25);
h = scatter(ax, 0, 0, 'y', 'filled');
txt = title(ax,'0%');
delta_t = mean(diff([logData.Timestamp]));
for ii = 2:numel(logData)
    % h.YData = min(logData(ii).Chunk,ones(numel(logData(ii).Chunk),1));
    % h.YData = logData(ii).Chunk - logData(ii-1).Chunk;
    % h.YData = logData(ii).Chunk;
    % x = double(typecast(logData(ii).Chunk([77 78])','int16'))/1e3;
    % y = double(typecast(logData(ii).Chunk([86 85])','int16'))/1e3;
    % x = bitshift(logData(ii).Chunk(77),-4);
    % y = bitshift(logData(ii).Chunk(85),-4);
    x = logData(ii).Chunk(45);
    y = logData(ii).Chunk(109);
    % fprintf(1,'%s | %s\n', dec2bin(x,8), dec2bin(y,8));
    set(h,'XData',x,'YData',y);
    pause(delta_t); drawnow;
    set(txt,'String',sprintf("%d%%",round(100*ii/numel(logData))));
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