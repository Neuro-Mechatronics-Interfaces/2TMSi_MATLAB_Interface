%TEST_SAGA_EMG_RMS_REACTIONS Test script to check on polling synchronously from 2 TMSi-SAGA + converting SAGA polling into emulated control commands based on EMG RMS.
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
%% Set global variables
global BAD_CH SPIKE_HISTORY DEBOUNCE_HISTORY THRESHOLD_GAIN MUAP_THRESH SELECTED_CHANNEL RISING_THRESH FALLING_THRESH RMS_ALPHA RMS_BETA DEBOUNCE_LOOP_ITERATIONS %#ok<GVMIS>

%% Initialize values of global variables
SELECTED_CHANNEL = 101;
RISING_THRESH = 2.1;
FALLING_THRESH = 3.5;
RMS_ALPHA = 0.25;
RMS_BETA = 1 - RMS_ALPHA;
DEBOUNCE_LOOP_ITERATIONS = 25;
THRESHOLD_GAIN = 1;
DEBOUNCE_HISTORY = 10;
SPIKE_HISTORY = zeros(128, DEBOUNCE_HISTORY);
MUAP_THRESH = getfield(load('configurations/decoding/MUAP_Reaction_Parameters.mat', 'MUAP_THRESH'), 'MUAP_THRESH');
BAD_CH = [];

%% Name output files
SAVE_FOLDER = fullfile(pwd,'.local-tests');
SAVE_DATA = true;
SUBJ = "Max";
BLOCK = 30;
MAX_TIME_SECONDS = 600; % Acquisition will not last longer than this (please only set to integer values)
BATCH_SIZE_SECONDS = 0.010; % Each acquisition cycle grabs sample batches of this duration (sample count depends on sample rate).
TEENSY_PORT = "COM6"; % REQUIRED to have Teensy plugged in on USB COM port!
dt = datetime();
s = sprintf('%s_%04d_%02d_%02d',SUBJ,year(dt), month(dt), day(dt));

%% Open library and connect to device

lib = TMSiSAGA.Library();
device = lib.getDevices('usb', 'electrical', 2, 2);
if numel(device) < 2
    error("Only detected %d devices!", numel(device));
end
connect(device);

%% Configure devices and channels
config_file = parameters('config_stream_service_plus');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT, SAGA, config_device, config_channels] = parse_main_config(config_file);
setDeviceTag(device, SN, TAG);
en_ch = horzcat({device.channels});
enableChannels(device, en_ch);
for ii = 1:numel(device)
    setSAGA(device(ii).channels, device(ii).tag);
    configStandardMode(device(ii), config_channels.(device(ii).tag), config_device);
    fprintf(1,'\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ...
        ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
end
channelOrder = textile_8x8_uni2grid_mapping();
if strcmpi(device(1).tag, "B") % Always puts "B" channels second (in online part)
    channelOrder = [channelOrder+numel(device(1).getActiveChannels()), channelOrder];
    iTrigger =find(device(2).getActiveChannels().isTrigger,1,'first') + numel(device(1).getActiveChannels()); % Get TRIGGERS from "A"
else
    channelOrder = [channelOrder, channelOrder+numel(device(1).getActiveChannels())];
    iTrigger = find(device(1).getActiveChannels().isTrigger,1,'first'); % Get TRIGGERS from "A"
end
fs = double(device(1).sample_rate); % Should both be the same sample rate
ch = device.getActiveChannels();
all_ch = active_channels_2_sync_channels(ch, 'CursorChannels', false);

%% Initialize filter and state buffers
batch_samples = fs * BATCH_SIZE_SECONDS;
batch_chunk = ones(1,batch_samples); % Pre-allocate a "chunk" of ones to multiply "stepped" values by.
ticks_per_second = round(1/BATCH_SIZE_SECONDS);
max_clock_cycles = ticks_per_second * MAX_TIME_SECONDS;
[b_hpf,a_hpf] = butter(3,100/(fs/2),'high');
z_hpf = zeros(3,128);
[b_env,a_env] = butter(1,1.5/(fs/2),'low');
z_env = zeros(1,128);
[b_p,a_p] = butter(1,6/(fs/2),'low');
z_p = zeros(1,128);

%% Create tcpclient which will transmit the commands
% conn = tcpclient("127.0.0.1", 6053);
vigem_gamepad(1);

%% Create poly5 files to write to
buttonState = false;
inDebounce = false;
debounceIterations = 0;

if exist(SAVE_FOLDER,'dir')==0
    mkdir(SAVE_FOLDER);
end
if SAVE_DATA
    POLY5_OUTPUT_FILE = strrep(fullfile(SAVE_FOLDER,string(sprintf("%s_Synchronized_%d.poly5", s, BLOCK))),'\','/');
    p5 = TMSiSAGA.Poly5(POLY5_OUTPUT_FILE, fs, all_ch, 'w');
else
    fprintf(1,'<strong>No data will be saved</strong>! `SAVE_DATA` is currently `false`.\n');
end
[fig, teensy] = init_microcontroller_listener_fig('SerialDevice', TEENSY_PORT); % Controls sync pulse emission (REQUIRED!)
drawnow();
[muap_fig, muap_img, muap_cbar, ch_txt] = init_muap_heatmap('Subject', SUBJ, 'Block', BLOCK);
pause(0.005);
switch getenv("COMPUTERNAME")
    case 'MAX_LENOVO'
        r = groot();
        if size(r.MonitorPositions,1) > 1
            if r.MonitorPositions(1,1) < 0 % This is how the "big screen" is configured on Max Laptop
                set(muap_fig,'Position',[-536        2119         900         420]);
                fig.Position = [-3.5   20    5.0000    0.7500];
            end
        end
    otherwise %Do nothing
        disp("Not Max Laptop - unsure of monitor configurations.");
end

i_start = start_sync(device, teensy); % This is blocking; click the opened microcontroller uifigure and press '1' (or corresponding trigger key)
fprintf(1,'device(1) starting COUNTER sample: %d\n', i_start(1));
fprintf(1,'device(2) starting COUNTER sample: %d\n', i_start(2));
% Now devices should be synchronized at least in terms of how many samples
% there are in each array.
iCount = 1;
iMax = 1;

startTick = datetime();
averageTime = 0;
uni_rates_s = zeros(128,1);
uni_prev = zeros(128, batch_samples);
buttonData = zeros(1, batch_samples);
required_loop_ticks = 1;
teensy_state = false;
teensy.write(char(teensy_state+48),'char');

mainTic = tic();
while isvalid(fig) && isvalid(muap_fig)
    data = sample_sync(device, batch_samples); % Poll in batches of 10-ms (2kHz assumed)
    batch_toc = toc(mainTic);
    [uni,z_hpf] = filter(b_hpf,a_hpf,data(channelOrder,:),z_hpf,2);
    uni(BAD_CH,:) = randn(numel(BAD_CH),batch_samples);
    uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
    [uni_e,z_env] = filter(b_env,a_env,abs(uni_s),z_env,2);
    uni_rates_s = RMS_ALPHA * sum(uni_s > (MUAP_THRESH.*THRESHOLD_GAIN),2) + RMS_BETA * uni_rates_s;
    
    
    try %#ok<TRYNC>
        muap_img.CData = reshape(uni_rates_s, 8, 16);
        ch_txt(SELECTED_CHANNEL).String = sprintf("%.1f", round(uni_rates_s(SELECTED_CHANNEL),1));
    end
    if inDebounce
        debounceIterations = debounceIterations + 1;
        inDebounce = debounceIterations < DEBOUNCE_LOOP_ITERATIONS;
        if buttonState
            SPIKE_HISTORY = [SPIKE_HISTORY(:,2:end), uni_rates_s > FALLING_THRESH];
        else
            SPIKE_HISTORY = [SPIKE_HISTORY(:,2:end), uni_rates_s > RISING_THRESH];
        end
    else
        if buttonState % If button is pressed, check if we should un-press it.
            SPIKE_HISTORY = [SPIKE_HISTORY(:,2:end), uni_rates_s > FALLING_THRESH];
            trig_val = any(SPIKE_HISTORY(SELECTED_CHANNEL,:));
            if ~trig_val
                % writeline(conn, 'a1'); % Release the button
                % simulate_keypress('A',0); % Release the "A" key
                vigem_gamepad(3, 0x0000); % Release all gamepad buttons
                buttonState = false;
                buttonData(end) = false;
                inDebounce = true;
                disp("Released 'A' button.");
                set(muap_fig,'Color',[1 1 1]);
            else
                buttonData = ones(1,batch_samples);
            end
        else
            SPIKE_HISTORY = [SPIKE_HISTORY(:,2:end), uni_rates_s > RISING_THRESH];
            trig_val = any(SPIKE_HISTORY(SELECTED_CHANNEL,:));
            if trig_val
                % writeline(conn, 'a0'); % Press the button
                % simulate_keypress('A',1); % Press the "A" key and hold
                vigem_gamepad(3, 0x1000); % Press and hold gamepad button-index 0
                buttonState = true;
                buttonData(end) = 1;
                disp("Pressed 'A' button.");
                set(muap_fig,'Color',[0.3 0.3 0.9]);
                inDebounce = true;
            else
                buttonData = zeros(1,batch_samples);
            end
        end
    end
    teensyData = teensy_state.*batch_chunk;
    if iCount == required_loop_ticks 
        teensy_state = ~teensy_state;
        teensy.write(char(teensy_state + 48),'char'); % +48 to ascii-encode
        % fprintf(1,'Average loop: %0.3f s\n', round(averageTime,2));
        required_loop_ticks = required_loop_ticks +1;
        iCount = 0;
    end
    tsData = batch_toc.*batch_chunk;
    % Should be: 
    %   [samples;
    %    Teensy (OUT); (teensyDataData)
    %    ViGEm Gamepad Commands (OUT); (buttonData)
    %    acquisition batch timestamps (tsData)];
    combined_data = [data; buttonData; teensyData; tsData];
    if SAVE_DATA
        p5.append(combined_data);
    end
    curTick = datetime();
    % delta_t = seconds(curTick - startTick);
    % averageTime = ((iCount-1)*averageTime + delta_t)/iCount; 
    
    if iMax == max_clock_cycles
        fprintf(1,'Time-limit reached. Ending acquisition.\n');
        break;
    end
    iCount = iCount + 1;
    iMax = iMax + 1;
    startTick = curTick;
end
delete(fig);
delete(teensy);
delete(muap_fig);
stop(device);
if SAVE_DATA
    p5.close();
    fprintf(1,"Closed test file: %s\n", POLY5_OUTPUT_FILE);
    delete(p5);
    BLOCK = BLOCK + 1;
else
    fprintf(1,'<strong>No data saved</strong>. `SAVE_DATA` is currently `false`.\n'); %#ok<*UNRCH>
end