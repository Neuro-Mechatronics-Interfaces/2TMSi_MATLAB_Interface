%EXAMPLE_LSL_SINUSOID Example showing playback for force-ramping GUI
clear;
close all force;
clc;

%% Parameters
FREQ = 1; % Frequency of sinusoid
AMP = 0.4; % Amplitude of sinusoid
OFFSET = 0.5;
NOISE_AMP = 0.05;
SAMPLE_RATE = 2000; % Samples per second
LOOP_DELAY = 0.10; % Seconds
STREAM_NAME = 'FORCE'; % ** MUST BE CHAR FOR LSL!!! **

chunk_sz = round(SAMPLE_RATE*LOOP_DELAY);

%% Open file and estimate scaling/offset
% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Units', 'inches', ...
    'MenuBar','none',...
    'ToolBar','none',...
    'Position',[3.5, 3, 6.25, 0.75]);
ax = axes(fig,'NextPlot','add','XColor','none','YColor','none','YLim',[-0.5,0.5],'XLim',[-0.5,0.5]);
text(ax,0,0,"CLOSE TO EXIT LSL PLAYBACK",'FontWeight','bold','FontSize',24,'FontName','Tahoma','Color','k','HorizontalAlignment','center','VerticalAlignment','middle');

%% Load the LSL library
lslMatlabFolder = parameters('liblsl_folder');
addpath(genpath(lslMatlabFolder)); % Adds liblsl-Matlab
lib_lsl = lsl_loadlib();

%% Initialize the LSL stream information and outlets
fprintf(1,'Opening raw data outlet...\n');
info.raw = lsl_streaminfo(lib_lsl, ...
    STREAM_NAME, ...       % Name
    'EMG', ...    % Type
    1, ....       % ChannelCount
    1/LOOP_DELAY, ...                % NominalSrate
    'cf_float32', ...               % ChannelFormat
    STREAM_NAME);      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
chns = info.raw.desc().append_child('channels');
for iCh = 1:1
    c = chns.append_child('channel');
    c.append_child_value('name', 'Sinusoid');
    c.append_child_value('label', sprintf('Sinusoid-%.1fHz',FREQ));
    c.append_child_value('unit', 'a.u.');
    c.append_child_value('type', 'aux');
end    
outlet.raw = lsl_outlet(info.raw);

%% Run loop while figure is open.
N = SAMPLE_RATE*FREQ;
theta = linspace(0,2*pi,N);
Y = sin(theta)*AMP + OFFSET;

chunk_vec = 0;
disp("Running main sample loop...");
while isvalid(fig)
    chunk_vec = rem(chunk_vec(end):(chunk_vec(end)+chunk_sz-1),N)+1;
    y = Y(1,chunk_vec) + randn(size(chunk_vec)).*NOISE_AMP;
    outlet.raw.push_chunk(y);

    pause(LOOP_DELAY);
end

% Cleanup outlets and library at the end.
f = fieldnames(outlet);
for iF = 1:numel(f)
    delete(outlet.(f{iF}));
    delete(info.(f{iF}));
end
% delete(lib_lsl.on_cleanup);
disp("Cleanup completed successfully.");