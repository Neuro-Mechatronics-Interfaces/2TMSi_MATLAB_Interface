%DEPLOY__PACMAN  Deploys v2 Gesture GUI
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
% SUBJ = config.Default.Subject;
SUBJ = "MCP04";
YYYY = 2025;
MM = 2;
DD = 14;
TANK = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
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
BETA = getfield(load(sprintf('C:/Data/MetaWB/%s/TMSi/%s_MODEL.mat',TANK,TANK),'BETA'),'BETA');

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


%%
close all force;
if SAVE_DATA
    [p5, p5_name, p5_folder] = initializePoly5File(SUBJ, BLOCK, ...
        meta.channels, meta.fs, 'OutputRoot', SAVE_FOLDER);
end
vigem_gamepad(1);
asserting = false;
% [rms_fig, rms_img, rms_cbar, ch_txt] = init_rms_heatmap( ...
%     'Subject', SUBJ, 'Block', BLOCK);
main_tic = tic();

start_sync(device, teensy);
mega.write(49,'c'); 
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

        Y_pred = ([batch_chunk;uni_e]')*BETA;
        asserting = mean(Y_pred(:,3),1) > 0.85;
        btn_code = 0x0000;
        if mean(Y_pred(:,2)) > 0.5 % Go UP
            btn_code = btn_code + 0x0001;
        elseif mean(Y_pred(:,2)) < -0.5 % Go DOWN
            btn_code = btn_code + 0x0002;
        end

        if mean(Y_pred(:,1)) > 0.5 % Go RIGHT
            btn_code = btn_code + 0x0008;
        elseif mean(Y_pred(:,1)) < -0.5 % Go LEFT
            btn_code = btn_code + 0x0004;            
        end
        if asserting
            btn_code = btn_code + 0x1000; % Press "A" button
            teensy.write('1','c');
        else
            teensy.write('0','c');
        end
        vigem_gamepad(3,btn_code);
        disp(btn_code);
        % rms_img.CData = reshape(uni_e_s, 8, 16);
        
        if SAVE_DATA
            mega_data = (instruction_fig.UserData.Active*instruction_fig.UserData.CurrentGesture).*batch_chunk;
            assertion_data = asserting .* batch_chunk;
            state_data = btn_code .* batch_chunk;
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

if SAVE_DATA
    BLOCK = BLOCK + 1; % In case we run this section again.
    p5.close();
    delete(p5);
    fprintf(1,"Loop complete. Data saved to %s.\n", p5_name);
else
    fprintf(1,"Loop complete. No data saved (SAVE_DATA==false).\n"); %#ok<*UNRCH>
end
stop(device);
vigem_gamepad(0);