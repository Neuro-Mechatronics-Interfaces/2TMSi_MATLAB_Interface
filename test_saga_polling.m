
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

lib = TMSiSAGA.Library();
device = lib.getDevices('usb', 'electrical', 2, 2);
connect(device);

%% Name output files
SUBJ = "Max";
BLOCK = 0;
MAX_TIME_SECONDS = 120; % Acquisition will not last longer than this (please only set to integer values)
BATCH_SIZE_SECONDS = 0.010; % Each acquisition cycle grabs sample batches of this duration (sample count depends on sample rate).
BETA = getfield(load('Default_PLS_Coefficients_RH.mat','beta'),'beta');
GAIN = 1;
USE_JOYSTICK = false;
TEENSY_PORT = "COM6"; % REQUIRED to have Teensy plugged in on USB COM port!

dt = datetime();
s = sprintf('%s_%04d_%02d_%02d',SUBJ,year(dt), month(dt), day(dt));

%% Create poly5 files to write to
config_file = parameters('config_stream_service_plus');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);
setDeviceTag(device, SN, TAG);

ch = device.getActiveChannels();
all_ch = channels_cell_2_sync_channels(ch);
all_ch = add_channel_struct(all_ch, 'BatchTS', 'sec', "T", -1);

if USE_JOYSTICK
    all_ch = add_channel_struct(all_ch, 'JoyPx', '-', "X", -1); %#ok<*UNRCH>
    all_ch = add_channel_struct(all_ch, 'JoyPy', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'JoyVx', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'JoyVy', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'JoyAx', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'JoyAy', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'JoyBtn','-', "X", -1);
    
    all_ch = add_channel_struct(all_ch, 'Target','-', "G", -1);
    all_ch = add_channel_struct(all_ch, 'Score', '-', "G", -1);
    all_ch = add_channel_struct(all_ch, 'Trial', '-', "G", -1);
    
    all_ch = add_channel_struct(all_ch, 'PredPx', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'PredPy', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'PredVx', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'PredVy', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'PredAx', '-', "X", -1);
    all_ch = add_channel_struct(all_ch, 'PredAy', '-', "X", -1);
end
fs = device(1).sample_rate; % Should both be the same sample rate
batch_samples = fs * BATCH_SIZE_SECONDS;
ticks_per_second = round(1/BATCH_SIZE_SECONDS);
max_clock_cycles = ticks_per_second * MAX_TIME_SECONDS;
[b_hpf,a_hpf] = butter(3,100/(fs/2),'high');
z_hpf = zeros(3,128);
[b_env,a_env] = butter(1,1.5/(fs/2),'low');
z_env = zeros(1,128);
[b_p,a_p] = butter(1,6/(fs/2),'low');
z_p = zeros(1,128);
channelOrder = textile_8x8_uni2grid_mapping();
channelOrder = [channelOrder+70, channelOrder];

%%
mainTic = tic();
POLY5_OUTPUT_FILE = string(sprintf("%s_Synchronized_%d.poly5", s, BLOCK));
p5 = TMSiSAGA.Poly5(POLY5_OUTPUT_FILE, fs, all_ch, 'w');

[fig, teensy] = init_microcontroller_listener_fig('SerialDevice', TEENSY_PORT); % Controls sync pulse emission (REQUIRED!)
drawnow();
pause(0.005);

i_start = start_sync(device, 1, TEENSY_PORT, 115200, '1', '0', teensy); % This is blocking; click the opened microcontroller uifigure and press '1' (or corresponding trigger key)
fprintf(1,'device(1) starting COUNTER sample: %d\n', i_start(1));
fprintf(1,'device(2) starting COUNTER sample: %d\n', i_start(2));
% Now devices should be synchronized at least in terms of how many samples
% there are in each array.
iCount = 1;

if USE_JOYSTICK
    cObj = cursor.Cursor('BufferSamples', batch_samples, 'MainTick', mainTic);
    cObj.setLogging(true, strrep(POLY5_OUTPUT_FILE, ".poly5", ".dat"));
end

startTick = datetime();
averageTime = 0;

while isvalid(fig)
    data = sample_sync(device, batch_samples); % Poll in batches of 10-ms (2kHz assumed)
    batch_toc = toc(mainTic);
    [uni,z_hpf] = filter(b_hpf,a_hpf,data(channelOrder,:),z_hpf,2);
    uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
    [uni_e,z_env] = filter(b_env,a_env,abs(uni_s),z_env,2);
    combined_data = [data; ones(1, batch_samples).*batch_toc];
    if USE_JOYSTICK
        state = [ones(batch_samples,1), uni_e'] * BETA * GAIN;
        combined_data = [combined_data; repelem(cObj.StateBuffer(:,(end-3):end),1,5); state'];
    end
    p5.append(combined_data);
    curTick = datetime();
    delta_t = seconds(curTick - startTick);
    averageTime = ((iCount-1)*averageTime + delta_t)/iCount; 
    if rem(iCount,ticks_per_second)==0 % Roughly once per second, print debug info
        cmd = sprintf('%d',randi(5,1)-1);
        try %#ok<TRYNC>
            teensy.write(cmd,'char');
        end
        fprintf(1,'Average loop: %0.3f s\n', round(averageTime,2));
        if iCount == max_clock_cycles
            fprintf(1,'Time-limit reached. Ending acquisition.\n');
            break;
        end
    end
    if USE_JOYSTICK
        cObj.update(mean(state(:,3),1), mean(state(:,4),1), delta_t);
    end
    iCount = iCount + 1;
    startTick = curTick;
end
if USE_JOYSTICK
    delete(cObj);
end
delete(teensy);
delete(fig);
stop(device);
p5.close();
fprintf(1,"Closed test file: %s\n", POLY5_OUTPUT_FILE);
delete(p5);


BLOCK = BLOCK + 1;
