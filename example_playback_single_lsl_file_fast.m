%EXAMPLE_PLAYBACK_SINGLE_LSL_FILE_FAST Example showing fast playback and broadcast of LSL file
clear;
close all force;
clc;

%% Parameters
SUBJ = "Max";
YYYY = 2024;
MM = 5;
DD = 29;
BLOCK = 1;

LOOP_DELAY = 0.030; % Seconds
UNI_CHANNELS = [1:64,75:138];
SAMPLE_RATE = 4000;


%% Load data
tank_name = sprintf("%s_%04d_%02d_%02d",SUBJ,YYYY,MM,DD);
block_name = sprintf("%s_%03d",tank_name,BLOCK);
fprintf(1,'Please wait, loading %s...\n', block_name);
data_in = io.load_tmsi(SUBJ, YYYY, MM, DD, "*", BLOCK, "lsl", "C:/Data/LSL/Gestures");
fprintf(1,'Training classifier...\n');
% [net,classes,features,targets,env_data] = train_LSL_envelope_classifier(data_in);
[mdl,classes,XTest,YTest,targets,env_data] = train_LSL_envelope_classifier(data_in);

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
    'SAGACombined_Raw', ...       % Name
    'EMG', ...    % Type
    numel(data_in.channels), ....   % ChannelCount
    SAMPLE_RATE, ...                % NominalSrate
    'cf_float32', ...               % ChannelFormat
    sprintf('%s_Raw_Playback',block_name));      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
chns = info.raw.desc().append_child('channels');
for iCh = 1:numel(data_in.channels)
    c = chns.append_child('channel');
    c.append_child_value('name', char(data_in.channels(iCh).name));
    c.append_child_value('label', char(data_in.channels(iCh).label));
    c.append_child_value('unit', char(data_in.channels(iCh).unit));
    if isfield(data_in.channels(iCh),'type')
        if ~ischar(data_in.channels(iCh).type) && ~isstring(data_in.channels(iCh).type)
            c.append_child_value('type', TMSiSAGA.TMSiUtils.toChannelTypeString(data_in.channels(iCh).type));
        else
            c.append_child_value('type',char(data_in.channels(iCh).type));
        end
    end
end    
info.raw.desc().append_child_value('manufacturer', 'NML');
info.raw.desc().append_child_value('layout', '2xGrid_8_x_8');
outlet.raw = lsl_outlet(info.raw);

% % % % Setup outlet for ENVELOPE playback % % %
% fprintf(1,'Opening envelope data outlet...\n');
% info.env = lsl_streaminfo(lib_lsl, ...
%     'SAGACombined_Envelope', ...       % Name
%     'EMG', ...    % Type
%     numel(UNI_CHANNELS), ....   % ChannelCount
%     1/LOOP_DELAY, ...                     % NominalSrate
%     'cf_float32', ...             % ChannelFormat
%     sprintf('%s_Envelope_Playback',block_name));      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
% chns = info.env.desc().append_child('channels');
% for ii = 1:numel(UNI_CHANNELS)
%     iCh = UNI_CHANNELS(ii);
%     c = chns.append_child('channel');
%     c.append_child_value('name', char(data_in.channels(iCh).name));
%     c.append_child_value('label', char(data_in.channels(iCh).label));
%     c.append_child_value('unit', char(data_in.channels(iCh).unit));
%     if isfield(data_in.channels(iCh),'type')
%         if ~ischar(data_in.channels(iCh).type) && ~isstring(data_in.channels(iCh).type)
%             c.append_child_value('type', TMSiSAGA.TMSiUtils.toChannelTypeString(data_in.channels(iCh).type));
%         else
%             c.append_child_value('type',char(data_in.channels(iCh).type));
%         end
%     end
% end    
% info.env.desc().append_child_value('manufacturer', 'NML');
% info.env.desc().append_child_value('layout', '2xGrid_8_x_8');
% outlet.env = lsl_outlet(info.env);

% % % Setup outlet for GESTURE playback % % %
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

% % % Setup outlet for PREDICTION LABEL playback % % %
fprintf(1,'Opening predicted gesture predictions outlet...\n');
info.predict = lsl_streaminfo(lib_lsl, ...
    'GesturePredictions', ...       % Name
    'Marker', ...    % Type
    numel(classes), ....   % ChannelCount
    1/LOOP_DELAY, ...                     % NominalSrate
    'cf_float32', ...             % ChannelFormat
    sprintf('%s_Prediction_Playback',block_name));      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
chns = info.predict.desc().append_child('channels');
for iCh = 1:numel(classes)
    c = chns.append_child('channel');
    c.append_child_value('name', classes{iCh});
    c.append_child_value('label', classes{iCh});
    c.append_child_value('type', 'Predicted Gesture');
end
outlet.predict = lsl_outlet(info.predict);

% % % % Setup outlet for PREDICTION ACTIVATIONS playback % % %
% fprintf(1,'Opening predicted gesture activations outlet...\n');
% info.activation = lsl_streaminfo(lib_lsl, ...
%     'GestureActivation', ...
%     'Activation', ...
%     numel(classes), ...
%     1/LOOP_DELAY, ...
%     'cf_float32', ...
%     sprintf('%s_Gesture_Activations', block_name));
% chns = info.activation.desc().append_child('channels');
% for iCh = 1:numel(classes)
%     c = chns.append_child('channel');
%     c.append_child_value('name', classes{iCh});
%     c.append_child_value('label', classes{iCh});
%     c.append_child_value('type','Gesture');
% end    
% info.activation.desc().append_child_value('classifier', 'trainSoftMaxLayer');
% outlet.activation = lsl_outlet(info.activation);

%% Get/set timing/indexing info
t = data_in.t(1,:);
tCur = 0;
tMax = t(end);
tGesture = data_in.markers.gesture.Time;
gesture = data_in.markers.gesture.Gesture;

%% Run loop while figure is open.
[b_hpf,a_hpf] = butter(3,100/(SAMPLE_RATE/2),'high');
[b_env,a_env] = butter(3,5/(SAMPLE_RATE/2),'low');
z_hpf = zeros(3,numel(UNI_CHANNELS));
z_env = zeros(3,numel(UNI_CHANNELS));
prevPredicted = 1;
iInstructed = [1; 0; 0; 0; 0];

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
    raw_data = double(data_in.samples(:,chunk_mask));
    outlet.raw.push_chunk(raw_data);
    
    % Filter data and push average (binned) envelope sample
    [data_hpf,z_hpf] = filter(b_hpf,a_hpf,raw_data(UNI_CHANNELS,:)',z_hpf,1);
    [data_env,z_env] = filter(b_env,a_env,abs(data_hpf),z_env,1);
    env_sample = mean(data_env,1);
    % outlet.env.push_sample(env_sample');

    % % Predict the output class based on the trained classifier
    % pred_sample = net(env_sample);
    % outlet.activation.push_sample(pred_sample);
    % 
    % [~,curPredicted] = max(pred_sample);
    % iPredicted = zeros(size(classes));
    % iPredicted(curPredicted) = 1;
    % outlet.predict.push_sample(iPredicted);
    curPredicted = predict(mdl,env_sample);
    iPredicted = zeros(size(classes));
    iPredicted(curPredicted) = 1;
    outlet.predict.push_sample(iPredicted);
    if curPredicted ~= prevPredicted
        fprintf(1,'Updated gesture prediction: %s\n', classes{curPredicted});
        prevPredicted = curPredicted;
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