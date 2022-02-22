% Script that enables sampling from two devices. Assumption is that the
% first device receives Sync In via the DIGI channel and that the second
% device sends Sync Out signals using the Sync Out Waveform.
%
% Best practice is to first stop sampling from the second device, as this
% can be reflected clearly in the STATUS channel of the first device as
% well (as no Sync In data is obtained when sampling has stopped on the
% second device). 
if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all;
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

%% Configure two devices.
TOTAL_SETS_DESIRED = 4000 * 5;  % 5 seconds of data.

% Configuration for Device 1 (Digi IN)
config_device1 = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
                        'Triggers', true, ...
                        'BaseSampleRate', 4000, ...
                        'RepairLogging', false, ...
                        'ImpedanceMode', false, ...
                        'AutoReferenceMethod', false, ...
                        'ReferenceMethod', 'common',...
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);
channel_config_device1 = struct('uni', 1:64, 'bip', 0, 'dig', 0, 'acc', 0);

% Configuration for Device 2 (Digi IN)
config_device2 = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
                        'Triggers', true, ...
                        'BaseSampleRate', 4000, ...
                        'ImpedanceMode', false, ...
                        'RepairLogging', false, ...
                        'AutoReferenceMethod', false, ...
                        'ReferenceMethod', 'common', ...
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);
channel_config_device2 = struct('uni', 1:64, 'bip', 0, 'dig', 0, 'acc', 0);

%% 
% Initialize the library
lib = TMSiSAGA.Library();

% Code within the try-catch to ensure that all devices are stopped and 
% closed properly in case of a failure.
device = lib.getDevices({'usb'}, {'electrical'});  
connect(device);
device(1).setDeviceConfig(config_device1);   
device(2).setDeviceConfig(config_device2);  
getDeviceInfo(device);
enableChannels(device, horzcat({device.channels}));
updateDeviceConfig(device);   
device(1).setChannelConfig(channel_config_device1);   
device(2).setChannelConfig(channel_config_device2); 
trig_channel = nan(size(device));
for k = 1:2
   trig_channel(k) = find(contains(getName(device(k).getActiveChannels()), "TRIGGERS"), 1, 'first'); 
end

% Create a data object for storage to memory and a RealTimePlot object
% for device 1
poly5_file = cell(size(device));
poly5{1} = TMSiSAGA.Poly5(['./Samples_Device1_' datestr(datetime('now'),'dd-mm-yyyy_HH.MM.SS') '.poly5'], ...
    device(1).sample_rate, device(1).getActiveChannels());    

% Create a data object for storage to memory and a RealTimePlot object
% for device 2
poly5{2} = TMSiSAGA.Poly5(['./Samples_Device2_' datestr(datetime('now'),'dd-mm-yyyy_HH.MM.SS') '.poly5'], ...
    device(2).sample_rate, device(2).getActiveChannels());    

% Start sampling
start(device);
n_sets_total = zeros(size(device));

while any([device.is_sampling])

    for k = 1:numel(device)
        if n_sets_total(k) < TOTAL_SETS_DESIRED
            % Sample from device 1
            [samples, num_sets] = device(k).sample();    
            poly5{k}.append(samples, num_sets);
            n_sets_total(k) = n_sets_total(k) + num_sets;
        else
            device(k).stop();
        end
    end
end

% Close Poly5 files.
poly5{1}.close();
poly5{2}.close();

% Disconnect both devices.
disconnect(device);     


lib.cleanUp();
disp('Exited script successfully!');
