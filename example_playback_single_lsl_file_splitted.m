%EXAMPLE_PLAYBACK_SINGLE_LSL_FILE_SPLITTED Example showing fast playback and broadcast of LSL file into two SAGA components
clear;
close all force;
clc;

%% Parameters
SUBJ = "Dailyn";
YYYY = 2024;
MM = 5;
DD = 31;
BLOCK = 2;

LOOP_DELAY = 0.030; % Seconds
UNI_CHANNELS = [1:64;75:138];
SAMPLE_RATE = 4000;

%% Load data
tank_name = sprintf("%s_%04d_%02d_%02d",SUBJ,YYYY,MM,DD);
block_name = sprintf("%s_%03d",tank_name,BLOCK);
fprintf(1,'Please wait, loading %s...\n', block_name);
data_in = io.load_tmsi(SUBJ, YYYY, MM, DD, "*", BLOCK, "lsl", "C:/Data/LSL/Gestures");
fprintf(1,'Training classifier...\n');
% [net,classes,features,targets,env_data] = train_LSL_envelope_classifier(data_in);
% [mdl,classes,XTest,YTest,targets,env_data] = train_LSL_envelope_classifier(data_in);

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
config = load_spike_server_config();
info = struct;
outlet = struct;

fprintf(1,'Opening raw data outlets...\n');
info.A = lsl_streaminfo(lib_lsl, ...
    sprintf('%s',config.SAGA.A.Unit),...
    'EMG', ...
    64, ...
    4000, ...
    'cf_float32', ...
    sprintf('%s',config.SAGA.A.Unit));
chns = info.A.desc().append_child('channels');
for iCh = 1:64
    c = chns.append_child('channel');
    c.append_child_value('name', sprintf('UNI %02d %s', iCh,config.SAGA.A.Array.Location));
    c.append_child_value('label', sprintf('UNI %02d %s', iCh,config.SAGA.A.Array.Location));
    c.append_child_value('type','EMG');
end
outlet.A = lsl_outlet(info.A);

info.B = lsl_streaminfo(lib_lsl, ...
    sprintf('%s',config.SAGA.B.Unit),...
    'EMG', ...
    64, ...
    4000, ...
    'cf_float32', ...
    sprintf('%s',config.SAGA.B.Unit));
chns = info.B.desc().append_child('channels');
for iCh = 1:64
    c = chns.append_child('channel');
    c.append_child_value('name', sprintf('UNI %02d %s', iCh,config.SAGA.B.Array.Location));
    c.append_child_value('label', sprintf('UNI %02d %s', iCh,config.SAGA.B.Array.Location));
    c.append_child_value('type','EMG');
end
outlet.B = lsl_outlet(info.B);

% % % Setup outlet for GESTURE playback % % %
[~,classes] = findgroups(data_in.markers.gesture.Gesture);
fprintf(1,'Opening instructed gesture outlet...\n');
info.gesture = lsl_streaminfo(lib_lsl, ...
    'GestureInstructions', ...       % Name
    'Marker', ...    % Type
    numel(classes), ....   % ChannelCount
    1/LOOP_DELAY, ...                     % NominalSrate
    'cf_float32', ...             % ChannelFormat
    sprintf('%s_Instruction_Playback',block_name));      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
chns = info.gesture.desc().append_child('channels');
for iCh = 1:numel(classes)
    c = chns.append_child('channel');
    c.append_child_value('name', classes{iCh});
    c.append_child_value('label', classes{iCh});
    c.append_child_value('type', 'Instructed Gesture');
end
outlet.gesture = lsl_outlet(info.gesture);

%% Get/set timing/indexing info
t = data_in.t(1,:);
tCur = 0;
tMax = t(end);
tGesture = data_in.markers.gesture.Time;
gesture = data_in.markers.gesture.Gesture;

%% Run loop while figure is open.
iInstructed = [1; 0; 0; 0; 0];
tag = {'A','B'};
disp("Running main sample loop...");
while isvalid(fig)
    % If any gesture instruction was issued, indicate this.
    iGesture = find((tGesture >= tCur) & (tGesture < (tCur + LOOP_DELAY)), 1, 'first');
    if isempty(iGesture)
        outlet.gesture.push_sample(iInstructed);
    else
        iInstructed = double(strcmpi(classes,gesture{iGesture}));
        fprintf(1,'Instructed gesture: %s\n', gesture{iGesture});
        outlet.gesture.push_sample(iInstructed);
    end

    % Get an indexing mask for the raw sample chunk to use for this iter.
    chunk_mask = (t >= tCur) & (t < (tCur + LOOP_DELAY));
    for ii = 1:2
        raw_data = double(data_in.samples(UNI_CHANNELS(ii,:),chunk_mask));
        outlet.(tag{ii}).push_chunk(raw_data);
    end

    % Increment time, allowing loop back. Then delay for next chunk.
    tCur = rem(tCur + LOOP_DELAY, tMax); 
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