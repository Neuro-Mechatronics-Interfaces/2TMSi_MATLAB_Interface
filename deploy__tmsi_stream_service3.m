%DEPLOY__TMSI_STREAM_SERVICE3  Try using LSL for this

clc;
addpath(genpath('C:\Users\nml\Documents\MyRepos\LSL\LSL\liblsl-Matlab'));

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

%% SET PARAMETERS
config_file = parameters('config');
fprintf(1, "[TMSi]::Loading configuration file (%s, in 2TMSi_MATLAB_Interface repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);

%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();
try
    % Code within the try-catch to ensure that all devices are stopped and 
    % closed properly in case of a failure.
    device = lib.getDevices('usb', config.Default.Interface, 2, 2); 
    connect(device); 
    setDeviceTag(device, SN, TAG);
catch e
    % In case of an error close all still active devices and clean up
    lib.cleanUp();  
        
    % Rethrow error to ensure you get a message in console
    rethrow(e)
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.
    
    getDeviceInfo(device);
    configStandardMode(device);
    for ii = 1:numel(device)
        fprintf(1,'[TMSi]\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
    end
    if numel(device) ~= N_CLIENT
        fprintf(1,'[TMSi]\t->\tWrong number of devices returned. Something went wrong with hardware connections.\n');
    end
catch e
    disconnect(device);
    lib.cleanUp();
    rethrow(e);
end

%% Create TMSi stream client + udpport
ordered_tags = strings(size(device));
ch = struct();
for ii = 1:numel(ordered_tags)
    ordered_tags(ii) = string(device(ii).tag);
    ch.(ordered_tags(ii)) = device(ii).getActiveChannels();
    setSAGA(ch.(ordered_tags(ii)), ordered_tags(ii));
end

%%
% make a new stream outlet
disp('Creating a new streaminfo...');
info = lsl_streaminfo(lib,'TMSi','EMG',68,4000,'cf_float32','sdfwerr32432');

name = {'SAGAA'; 'SAGAB'};

for ii = 1:numel(name)
    info = lsl_streaminfo(lib,'TMSi','EMG',74,4000,'cf_float32','SAGA_A');
    chns = info.desc().append_child('channels');
    for label = {'C3','C4','Cz','FPz','POz','CPz','O1','O2'}
        ch = chns.append_child('channel');
        ch.append_child_value('label',label{1});
        ch.append_child_value('unit','microvolts');
        ch.append_child_value('type','EEG');
    end
    info.desc().append_child_value('manufacturer','SCCN');
    cap = info.desc().append_child('cap');
    cap.append_child_value('name','EasyCap');
    cap.append_child_value('size','54');
    cap.append_child_value('labelscheme','10-20');
    
    disp('Opening an outlet...');
    outlet = lsl_outlet(info);
end

% send data into the outlet
disp('Now transmitting chunked data...');
while true
    
    pause(0.5);
end