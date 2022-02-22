% Script that enables sampling from two devices. Assumption is that the
% first device receives Sync In via the DIGI channel and that the second
% device sends Sync Out signals using the Sync Out Waveform.
%
% Best practice is to first stop sampling from the second device, as this
% can be reflected clearly in the STATUS channel of the first device as
% well (as no Sync In data is obtained when sampling has stopped on the
% second device). 
clc;
if exist('device', 'var')~=0
    disconnect(device);
end

if exist('lib', 'var')~=0
    lib.cleanUp();
end

if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all;
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

% Set base parameters.
SUBJ = 'TEST';
run_date = datestr(datetime('now'), 'yyyy_mm_dd');
run_time = datestr(datetime('now'), 'HH-MM-SS');
% Middle "%s" reserved for `device_tags(k)`
IMPEDANCE_FILE_EXPR = sprintf('%s_%s_%s_%%d - %s_%s.%s', ....
    SUBJ, run_date, '%s', 'impedances', run_time, 'mat'); % added
DATA_FILE_EXPR = sprintf('%s_%s_%s_%%d - %s_%s.%s', ...
    SUBJ, run_date, '%s', 'data', run_time, 'poly5');
START_INDEX = -1;
TOTAL_SETS_DESIRED = 4000 * 5;  % 5 seconds of data.
TANK = 'R:\NMLShare\raw_data\primate\TEST\TEST_2021_12_01';


% Configure two devices.
tank_info = strsplit(TANK, filesep);
block = tank_info{end};

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

%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();

% Code within the try-catch to ensure that all devices are stopped and 
% closed properly in case of a failure.
device = lib.getDevices({'usb'}, {'electrical'});  
connect(device);

%%
% device(1).setDeviceConfig(config_device1); 
device(1).tag = "B";
if device(1).docking_station.serial_number ~= 1005210029
    error('Double-check that this is device NHP-B so that records match!');
end
device(1).impedance_file_expr = IMPEDANCE_FILE_EXPR;
device(1).data_file_expr = DATA_FILE_EXPR;
% device(2).setDeviceConfig(config_device2); 
device(2).tag = "A";
if device(2).docking_station.serial_number ~= 1005210028
    error('Double-check that this is device NHP-A so that records match!');
end
device(2).impedance_file_expr = IMPEDANCE_FILE_EXPR;
device(2).data_file_expr = DATA_FILE_EXPR;
getDeviceInfo(device);
enableChannels(device, horzcat({device.channels}));
updateDeviceConfig(device);   
device(1).setChannelConfig(channel_config_device1);   
device(2).setChannelConfig(channel_config_device2); 
device(1).recording_index = START_INDEX;
device(2).recording_index = START_INDEX;

trig_channel = nan(size(device));
for k = 1:2
   trig_channel(k) = find(contains(getName(device(k).getActiveChannels()), "TRIGGERS"), 1, 'first'); 
end

n_sets_total = zeros(size(device));

%% Create POLY5 FILES
% Create a data object for storage to memory and a RealTimePlot object
% for device 1
poly5_file = cell(size(device));

%% Measure IMPEDANCES
[data_file_name, imp_file_name] = get_new_names(device);
test_and_save_impedances(device, fullfile(TANK, 'impedances', imp_file_name));
device(1).setDeviceConfig(config_device1); 
device(2).setDeviceConfig(config_device2); 

%%
b1 = string(sprintf('%s_%s_%d', block, device(1).tag, device(1).recording_index));
poly5_file{1} = TMSiSAGA.Poly5(fullfile(TANK, b1, data_file_name(1)), ...
        device(1).sample_rate, device(1).getActiveChannels());
b2 = string(sprintf('%s_%s_%d', block, device(1).tag, device(1).recording_index));
poly5_file{2} = TMSiSAGA.Poly5(fullfile(TANK, b2, data_file_name(2)), ...
    device(2).sample_rate, device(2).getActiveChannels());   
try
    while true
        start(device);
        while any(~[device.is_recording])
            disp('Awaiting START signal.');
            for k = 1:numel(device)
               [samples, num_sets] = device(k).sample();

               if num_sets > 0
                   trigs = samples(trig_channel(k), :);
                   if any(~(bitand(trigs, 2^10)==2^10))
                       disp('START signal received!');
                       fprintf(1, '\t->\tVALUE: %d\n', unique(trigs));
                       device(k).is_recording = true;
                   end
               end
            end
        end

        while any([device.is_recording])
            for k = 1:numel(device)
                if device(k).is_sampling
                    [samples, num_sets] = device(k).sample();   
                    if num_sets > 0  
                        poly5_file{k}.append(samples, num_sets);
                        if any(bitand(trigs, 2^10)==2^10)
                            device(k).stop();
                        end
                    end
                end
            end
        end

        % Close Poly5 files.
        poly5_file{1}.close();
        poly5_file{2}.close();

        [~, data_file_name] = get_new_names(device);
        b1 = string(sprintf('%s_%s_%d', block, device(1).tag, device(1).recording_index));
        poly5_file{1} = TMSiSAGA.Poly5(fullfile(TANK, b1, data_file_name(1)), ...
            device(1).sample_rate, ...
            device(1).getActiveChannels());  
        pause(0.25);
        b2 = string(sprintf('%s_%s_%d', block, device(2).tag, device(2).recording_index));
        poly5_file{2} = TMSiSAGA.Poly5(fullfile(TANK, b2, data_file_name(2)), ...
            device(2).sample_rate, ...
            device(2).getActiveChannels());   
    end
catch me
    % Disconnect both devices.
    disconnect(device);     


    lib.cleanUp();
    disp('Exited script successfully!');
    disp(me);
end
