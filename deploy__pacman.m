%DEPLOY__GESTURES2_GUI  Deploys v2 Gesture GUI
clc;
if exist('device', 'var')~=0
    disconnect(device);
end
    
if exist('lib', 'var')~=0
    lib.cleanUp();
end

if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all; %#ok<*CLALL>
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

%% Load/configure parameters
config = load_gestures_config();
SAVE_DATA = true;
SUBJ = config.Default.Subject;
BLOCK = config.Default.Block;
SAVE_FOLDER = config.Default.Folder;
BATCH_SIZE_SECONDS = config.Default.Batch_Duration; % Each acquisition cycle grabs sample batches of this duration (sample count depends on sample rate).

%% Set global variables
global BAD_CH SELECTED_CHANNEL RISING_THRESH FALLING_THRESH RMS_ALPHA RMS_BETA DEBOUNCE_LOOP_ITERATIONS %#ok<GVMIS>

%% Initialize values of global variables
SELECTED_CHANNEL = 101;
RISING_THRESH = 2.1;
FALLING_THRESH = 3.5;
RMS_ALPHA = 0.25;
RMS_BETA = 1 - RMS_ALPHA;
DEBOUNCE_LOOP_ITERATIONS = 2;
BAD_CH = [];
% BETA = [];
BETA = getfield(load('C:\Data\TMSi\MCP05\MCP05_2025_02_12\MCP05_2025_02_12_MODEL.mat','BETA'),'BETA');

%% Connect/setup TMSi Devices
[lib, device, meta] = initializeTMSiDevices(config, ...
    'MegaChannel', true, ...
    'TeensyChannel', false, ...
    'CursorChannels', false, ...
    'ContactileChannels', false, ...
    'GamepadButtonChannel', false, ...
    'AssertionChannel', true, ...
    'StateChannel', true, ...
    'LoopTimestampChannel', true);
batch_samples = round(meta.fs * BATCH_SIZE_SECONDS);
batch_chunk = ones(1,batch_samples);
[b_hpf,a_hpf] = butter(3,100/(meta.fs/2),'high');
z_hpf = zeros(3,128);
[b_env,a_env] = butter(1,1.5/(meta.fs/2),'low');
z_env = zeros(1,128);
uni_e_s = zeros(128,1);

%% Initialize microcontrollers
mega = connect_mega2560(config.Gestures.Peripherals.MEGA2560);
teensy = connect_teensy(config.Gestures.Peripherals.Teensy41);

%% Pre-load the desired gesture set
gestureList = ["Wrist Extension", "Wrist Flexion", "Radial Deviation", "Ulnar Deviation"];
gestureImages = loadGestureImages("Gestures", gestureList, 'Mirror', false);

% Example to also load gestures for opposite arm:
% gestureImages = [gestureImages; loadGestureImages("Gestures", gestureList,"Mirror",true)];
% gestureList = repmat(gestureList,1,2);

% Example to shuffle around the gesture presentation order:
% idx = randsample(1:numel(gestureList),numel(gestureList),false);
% gestureList = gestureList(idx);
% gestureImages = gestureImages(idx);

%%
channelList = [22, 52, 82, 107];

close all force;
if SAVE_DATA
    [p5, p5_name, p5_folder] = initializePoly5File(SUBJ, BLOCK, ...
        meta.channels, meta.fs, 'OutputRoot', SAVE_FOLDER);
end
asserting = false;
wasPaused = true;

instruction_fig = init_instruction_gui2( ...
    'MEGA2560',mega, ...
    'GestureImages', gestureImages, ...
    'InstructionList', gestureList, ...
    'ChannelList', channelList, ...
    'SkinColor', 'White');
[rms_fig, rms_img, rms_cbar, ch_txt] = init_rms_heatmap( ...
    'Subject', SUBJ, 'Block', BLOCK);
main_tic = tic();

start_sync(device, teensy);
while isvalid(instruction_fig)
    loopTic = tic();
    batch_toc = toc(main_tic);
    try
        data = sample_sync(device, batch_samples); % Poll in fixed-size batches
        [uni,z_hpf] = filter(b_hpf,a_hpf,data(meta.order,:),z_hpf,2);
        uni(BAD_CH,:) = randn(numel(BAD_CH),batch_samples);
        uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
        [uni_e,z_env] = filter(b_env,a_env,abs(uni_s),z_env,2);
        uni_e_s = RMS_ALPHA * rms(uni_e,2) + RMS_BETA * uni_e_s;
        % [~,~,btn] = WinJoystickMex(0);
        % asserting = btn==1;
        if isempty(BETA)
            asserting = decode_rms_assertion(uni_e_s(SELECTED_CHANNEL), asserting, FALLING_THRESH, RISING_THRESH);
        else
            Y_pred = ([1;uni_e_s]')*BETA;
            if Y_pred(1) < 0.5
                [~,asserting] = max(Y_pred(2:end));
            else
                asserting = 0;
            end
        end
        updateGestureState(instruction_fig, asserting, config.Gestures.Animation, loopTic);
        rms_img.CData = reshape(uni_e_s, 8, 16);
        if instruction_fig.UserData.Paused && ~wasPaused
            wasPaused = true;
            teensy.write('1','c');
        elseif ~instruction_fig.UserData.Paused && wasPaused
            wasPaused = false;
            teensy.write('0','c');
        end
        
        if SAVE_DATA
            mega_data = (instruction_fig.UserData.Active*instruction_fig.UserData.CurrentGesture).*batch_chunk;
            assertion_data = asserting .* batch_chunk;
            state_data = instruction_fig.UserData.State .* batch_chunk;
            tsData = batch_toc.*batch_chunk;
            combined_data = [data(meta.logging_order,:); mega_data; assertion_data; state_data; tsData];
            p5.append(combined_data);
        end
        pause(0.001); % Pause to allow other callbacks to happen
    catch me 
        if ~strcmpi(me.identifier,'MATLAB:class:InvalidHandle') % Don't throw if we closed it on purpose
            disp(me);
        end
        break;
    end
end
mega.write(48,'c'); % Be sure to clear at the end.

