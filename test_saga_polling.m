

lib = TMSiSAGA.Library();
device = lib.getDevices('usb', 'electrical', 2, 2);
connect(device);

%% Name output files
BLOCK = 0;
dt = datetime();
s = sprintf('%04d-%02d-%02d',year(dt), month(dt), day(dt));

%% Create poly5 files to write to
ch = device.getActiveChannels();
all_ch = channels_cell_2_sync_channels(ch);
fs = device(1).sample_rate; % Should both be the same sample rate

%%
POLY5_OUTPUT_FILE = string(sprintf("%s_Test_%d.poly5", s, BLOCK));
p5 = TMSiSAGA.Poly5(POLY5_OUTPUT_FILE, fs, all_ch, 'w');

[fig, teensy] = init_microcontroller_listener_fig('SerialDevice', "COM6"); % Controls sync pulse emission
drawnow();
pause(0.005);

i_start = start_sync(device, 1, "COM6", 115200, '1', '0', teensy); % This is blocking; click the opened microcontroller uifigure and press '1' (or corresponding trigger key)
fprintf(1,'device(1) starting COUNTER sample: %d\n', i_start(1));
fprintf(1,'device(2) starting COUNTER sample: %d\n', i_start(2));
% Now devices should be synchronized at least in terms of how many samples
% there are in each array.
iCount = 0;
startTick = datetime();
averageTime = 0;
% start(device);
while isvalid(fig)
    data = sample_sync(device, 20); % Poll in batches of 10-ms (2kHz assumed)
    p5.append(data); % Dump samples to the file
    
    iCount = iCount + 1;
    curTick = datetime();
    averageTime = ((iCount-1)*averageTime + milliseconds(curTick - startTick))/iCount; 
    if rem(iCount, 100)==0 % Roughly once per second, print debug info
        cmd = sprintf('%d',randi(5,1)-1);
        try %#ok<TRYNC>
            teensy.write(cmd,'char');
        end
        fprintf(1,'Average loop: %.2f ms\n', round(averageTime,2));
    end
    startTick = curTick;
end
delete(teensy);
stop(device);
p5.close();
fprintf(1,"Closed test file: %s\n", POLY5_OUTPUT_FILE);
delete(p5);
BLOCK = BLOCK + 1;
