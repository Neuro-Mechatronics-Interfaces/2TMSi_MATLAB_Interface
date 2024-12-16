
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
SUBJ = "Test";
BLOCK = 2;
MAX_TIME_SECONDS = 120; % Acquisition will not last longer than this (please only set to integer values)
BATCH_SIZE_SECONDS = 0.010; % Each acquisition cycle grabs sample batches of this duration (sample count depends on sample rate).

dt = datetime();
s = sprintf('%s_%04d_%02d_%02d',SUBJ,year(dt), month(dt), day(dt));

%% Create poly5 files to write to
config_file = parameters('config_stream_service_plus');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);
setDeviceTag(device, SN, TAG);

ch = device.getActiveChannels();
all_ch = channels_cell_2_sync_channels(ch);
all_ch = add_channel_struct(all_ch, 'JoyPx', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyPy', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyVx', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyVy', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyAx', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyAy', '-', "X", -1);
all_ch = add_channel_struct(all_ch, 'JoyBtn','-', "X", -1);

all_ch = add_channel_struct(all_ch, 'Target','-', "G", -1);
all_ch = add_channel_struct(all_ch, 'Score', '-', "G", -1);
all_ch = add_channel_struct(all_ch, 'Trial', '-', "G", -1);

fs = device(1).sample_rate; % Should both be the same sample rate
batch_samples = fs * BATCH_SIZE_SECONDS;
ticks_per_second = round(1/BATCH_SIZE_SECONDS);
max_clock_cycles = ticks_per_second * MAX_TIME_SECONDS;

%%
POLY5_OUTPUT_FILE = string(sprintf("%s_Synchronized_%d.poly5", s, BLOCK));
p5 = TMSiSAGA.Poly5(POLY5_OUTPUT_FILE, fs, all_ch, 'w');

[fig, teensy] = init_microcontroller_listener_fig('SerialDevice', "COM6"); % Controls sync pulse emission
drawnow();
pause(0.005);

i_start = start_sync(device, 1, "COM6", 115200, '1', '0', teensy); % This is blocking; click the opened microcontroller uifigure and press '1' (or corresponding trigger key)
fprintf(1,'device(1) starting COUNTER sample: %d\n', i_start(1));
fprintf(1,'device(2) starting COUNTER sample: %d\n', i_start(2));
% Now devices should be synchronized at least in terms of how many samples
% there are in each array.
iCount = 1;

cObj = cursor.Cursor('BufferSamples', batch_samples);
cObj.setLogging(true, strrep(POLY5_OUTPUT_FILE, ".poly5", ".dat"));
start(cObj);

startTick = datetime();
averageTime = 0;

while isvalid(fig)
    data = sample_sync(device, batch_samples); % Poll in batches of 10-ms (2kHz assumed)
    combined_data = [data; repelem(cObj.StateBuffer(:,(end-3):end),1,5)];
    p5.append(combined_data); % Dump samples to the file
    
    curTick = datetime();
    averageTime = ((iCount-1)*averageTime + milliseconds(curTick - startTick))/iCount; 
    if rem(iCount,ticks_per_second)==0 % Roughly once per second, print debug info
        % cmd = sprintf('%d',randi(5,1)-1);
        % try %#ok<TRYNC>
        %     teensy.write(cmd,'char');
        % end
        fprintf(1,'Average loop: %.2f ms\n', round(averageTime,2));
        if iCount == max_clock_cycles
            fprintf(1,'Time-limit reached. Ending acquisition.\n');
            break;
        end
    end
    iCount = iCount + 1;
    startTick = curTick;
end
stop(cObj);
delete(cObj);
delete(teensy);
delete(fig);
stop(device);
p5.close();
fprintf(1,"Closed test file: %s\n", POLY5_OUTPUT_FILE);
delete(p5);


BLOCK = BLOCK + 1;
