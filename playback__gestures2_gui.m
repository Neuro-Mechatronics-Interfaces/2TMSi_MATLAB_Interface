%PLAYBACK__GESTURES2_GUI  Plays back Gestures v2 GUI recording
clc;


%% Load/configure parameters
config = load_gestures_config();
BATCH_SIZE_SECONDS = 0.020; % Each acquisition cycle grabs sample batches of this duration (sample count depends on sample rate).

SUBJ = 'MCP04';
BLOCK = 13;
YYYY = 2025;
MM = 1;
DD = 23;
TANK = sprintf("%s_%04d_%02d_%02d", SUBJ, YYYY, MM, DD);

POLY5_SYNC_FILE = sprintf('C:/Data/MetaWB/%s/TMSi/%s_Synchronized_%d.poly5', TANK, TANK, BLOCK);
USE_MICROS = false;

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
BETA = [];


%% Open poly5 file
fs = config.Default.Sample_Rate / 2^config.Default.Sample_Rate_Divider;
p5 = TMSiSAGA.Poly5(POLY5_SYNC_FILE,fs,[],'r');
tmp = p5.read_next_n_blocks(1);
reset(p5); % Just want to get the chunk dimensions

%% Connect/setup TMSi Devices
batch_samples = size(tmp,2);
batch_duration = batch_samples / fs;
batch_chunk = ones(1,batch_samples);
iUni = get_saga_channel_masks(p5.channels);
nUni = numel(iUni);
[b_hpf,a_hpf] = butter(3,100/(fs/2),'high');
z_hpf = zeros(3,nUni);
[b_env,a_env] = butter(1,1.5/(fs/2),'low');
z_env = zeros(1,nUni);
uni_e_s = zeros(nUni,1);

%% Initialize microcontrollers
if USE_MICROS
    mega = connect_mega2560(config.Gestures.Peripherals.MEGA2560);
    teensy = connect_teensy(config.Gestures.Peripherals.Teensy41);
else
    mega = [];
    teensy = [];
end

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
asserting = false;
wasPaused = true;

instruction_fig = init_instruction_gui2( ...
    'MEGA2560',mega, ...
    'UseMicros', USE_MICROS, ...
    'GestureImages', gestureImages, ...
    'InstructionList', gestureList, ...
    'ChannelList', channelList, ...
    'SkinColor', 'White');
[rms_fig, rms_img, rms_cbar, ch_txt] = init_rms_heatmap( ...
    'Subject', SUBJ, 'Block', BLOCK);
reset(p5); % Make sure we start from beginning of file. 
main_tic = tic();
while isvalid(instruction_fig)
    loopTic = tic();
    try
        data = p5.read_next_n_blocks(1); % Poll in fixed-size batches
        [uni,z_hpf] = filter(b_hpf,a_hpf,data(iUni,:),z_hpf,2);
        uni(BAD_CH,:) = randn(numel(BAD_CH),batch_samples);
        uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
        [uni_e,z_env] = filter(b_env,a_env,abs(uni_s),z_env,2);
        uni_e_s = RMS_ALPHA * rms(uni_e,2) + RMS_BETA * uni_e_s;
        if wasPaused
            instruction_fig.UserData.State = data(end-1,end);
        end
        asserting = data(end-2,end);
        updateGestureState(instruction_fig, asserting, config.Gestures.Animation, loopTic);
        rms_img.CData = reshape(uni_e_s, 8, 16);
        if USE_MICROS
            if instruction_fig.UserData.Paused && ~wasPaused
                wasPaused = true;
                teensy.write('1','c');
            elseif ~instruction_fig.UserData.Paused && wasPaused
                wasPaused = false;
                teensy.write('0','c');
            end
        end
        % pause(batch_duration - 0.0185); % Pause to allow other callbacks to happen
        while (toc(main_tic) < data(end,end))
            pause(0.0005);
        end
    catch me 
        if ~strcmpi(me.identifier,'MATLAB:class:InvalidHandle') % Don't throw if we closed it on purpose
            disp(me);
        end
        break;
    end
end
if USE_MICROS
    mega.write(48,'c'); %#ok<*UNRCH> % Be sure to clear at the end.
end
close(rms_fig);
