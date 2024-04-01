%DEPLOY__TMSI_STREAM_SERVICE3  Try using LSL for this

clc;
lslMatlabFolder = fullfile(pwd, '..', 'liblsl-Matlab');
if exist(lslMatlabFolder,'dir')==0
    lslMatlabFolder = parameters('liblsl_folder');
    if exist(lslMatlabFolder, 'dir')==0
        disp("No valid liblsl-Matlab repository detected on this device.");
        fprintf(1,'\t->\tTried: "%s"\n', fullfile(pwd, '..', 'liblsl-Matlab'));
        fprintf(1,'\t->\tTried: "%s"\n', lslMatlabFolder);
        disp("Please check parameters.m in the 2TMSi_MATLAB_Interface repository, and try again.");
        pause(30);
        error("[TMSi]::Missing liblsl-Matlab repository.");
    end
end
addpath(genpath(lslMatlabFolder)); % Adds liblsl-Matlab

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
config_file = parameters('config_lsl');
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

%% Set channel tag
ordered_tags = strings(size(device));
ch = struct();
for ii = 1:numel(ordered_tags)
    ordered_tags(ii) = string(device(ii).tag);
    ch.(ordered_tags(ii)) = device(ii).getActiveChannels();
    setSAGA(ch.(ordered_tags(ii)), ordered_tags(ii));
end

%% Load the LSL library
lib_lsl = lsl_loadlib();

%% Create LSL outlets
% make a new stream outlet
outlet = struct;
% instantiate the LSL library
tag_streams = struct('A', 'rms_dec', 'B', 'EXT');

for iDev = 1:numel(device)
    tag = device(iDev).tag;
    fprintf(1,'Creating LSL streaminfo for SAGA-%s...\n',tag);
    info = lsl_streaminfo(lib_lsl,sprintf('SAGA-%s',tag), ...
        tag_streams.(tag), numel(ch.(tag)), 4000, ...
        'cf_double64', ...
        sprintf('SN%s',num2str(device(iDev).data_recorder.serial_number)));
%     info = lsl_streaminfo(lib_lsl,sprintf('SAGA-%s',tag), ...
%         'EMG', 64, 100, ...
%         'cf_double64', ...
%         sprintf('SN%s',num2str(device(iDev).data_recorder.serial_number)));
    chns = info.desc().append_child('channels');
    for iCh = 1:numel(ch.(tag))
%     for iCh = 2:65
        c = chns.append_child('channel');
        c.append_child_value('label',ch.(tag)(iCh).name);
        c.append_child_value('unit',ch.(tag)(iCh).unit_name);
        c.append_child_value('type','EMG');
        c.append_child_value('subtype', TMSiSAGA.TMSiUtils.toChannelTypeString(ch.(tag)(iCh).type));
    end    
    info.desc().append_child_value('manufacturer', 'NMLVR');
    info.desc().append_child_value('layout', 'Grid_8_x_8');
    disp('Opening outlet...');
    outlet.(tag) = lsl_outlet(info);
end

%% Loop: send data into the outlet
disp('Now transmitting chunked data...');
try
    start(device);
    
%     counter = struct('A', 1:200, 'B', 1:200);
    n = numel(device);
    while true
%         triggers = ones(2,200).*255;  % sum(2^(0:7))
%         triggers(randi(400,2)) = 128; % 255 - 2^7
        for iDev = 1:n
            tag = device(iDev).tag;
%             data = [zeros(1,200); randn(70,200); triggers; counter.(tag)];
%             data = randn(64,50);
%             outlet.(tag).push_chunk(data);
            outlet.(tag).push_chunk(device(iDev).sample());
%             counter.(tag) = counter.(tag) + 200;
        end
        pause(0.050);
    end
catch me
    disp(me);
    stop(device);
end