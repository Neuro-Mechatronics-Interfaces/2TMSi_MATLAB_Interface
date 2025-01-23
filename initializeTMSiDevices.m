function [lib, device, metadata] = initializeTMSiDevices(config, options)
%INITIALIZETMSIDEVICES  Initializes 2 TMSi Devices based on provided config

arguments
    config
    options.AssertionChannel (1,1) logical = false;
    options.CursorChannels (1,1) logical = true; % Shorthand, if set false, JoystickChannels, JoystickPredictionChannels, and CenterOutChannels are all overriden to false.
    options.JoystickChannels (1,1) logical = false;
    options.CenterOutChannels (1,1) logical = false;
    options.JoystickPredictionChannels (1,1) logical = false;
    options.MegaChannel (1,1) logical = false; % Indicates commands sent to MEGA2560
    options.MegaSerialNumber (1,1) {mustBeNumeric} = -1;
    options.TeensyChannel (1,1) logical = true; % Indicates commands sent to Teensy
    options.TeensySerialNumber (1,1) {mustBeNumeric} = -1;
    options.ContactileChannels (1,1) logical = false;
    options.NumContactileSensors (1,1) {mustBeInteger, mustBeInRange(options.NumContactileSensors, 1, 10)} = 6;
    options.GamepadButtonChannel (1,1) logical = false;  % Indicates emulated gamepad kernel commands
    options.StateChannel (1,1) logical = false;
    options.LoopTimestampChannel (1,1) logical = true; % Indicates timestamp of current sample loop batch
end

lib = TMSiSAGA.Library();
device = lib.getDevices('usb', config.Default.Interface, 2, 2);
metadata = struct;
connect(device);
setDeviceTag(device, config.Device.SerialNumber, config.Device.Tag);
en_ch = horzcat({device.channels});
enableChannels(device, en_ch);
for ii = 1:numel(device)
    setSAGA(device(ii).channels, device(ii).tag);
    configStandardMode(device(ii), config.Device.ChannelConfig.(device(ii).tag), config.Device.DeviceConfig);
    fprintf(1,'\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ...
        ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
end
channelOrder = textile_8x8_uni2grid_mapping();
if strcmpi(device(1).tag, "B") % Always puts "B" channels second (in online part)
    nB = numel(device(1).getActiveChannels());
    nA = numel(device(2).getActiveChannels());
    overallOrder = [channelOrder+nB, (nB+65):(nB+nA), channelOrder, (65:nB)];
    channelOrder = [channelOrder+nB, channelOrder];
    iTrigger =find(device(2).getActiveChannels().isTrigger,1,'first') + nB; % Get TRIGGERS from "A"
else
    nB = numel(device(2).getActiveChannels());
    nA = numel(device(1).getActiveChannels());
    overallOrder = [channelOrder, (65:nA), channelOrder+nA, ((nA+65):(nB+nA))];
    channelOrder = [channelOrder, channelOrder+nA];
    iTrigger = find(device(1).getActiveChannels().isTrigger,1,'first'); % Get TRIGGERS from "A"
end
ch = device.getActiveChannels();

% Create output metadata
metadata.order = channelOrder;
metadata.logging_order = overallOrder;
metadata.trigger = iTrigger;
metadata.fs = double(device(1).sample_rate); % Should both be the same sample rate
metadata.channels = active_channels_2_sync_channels(ch, ...
    'AssertionChannel', options.AssertionChannel, ...
    'MegaChannel', options.MegaChannel, ...
    'TeensyChannel', options.TeensyChannel, ...
    'CursorChannels', options.CursorChannels, ...
    'ContactileChannels', options.ContactileChannels, ...
    'GamepadButtonChannel', options.GamepadButtonChannel, ...
    'LoopTimestampChannel', options.LoopTimestampChannel, ...
    'NumContactileSensors', options.NumContactileSensors, ...
    'MegaSerialNumber', options.MegaSerialNumber, ...
    'TeensySerialNumber',options.TeensySerialNumber, ...
    'CenterOutChannels', options.CenterOutChannels, ...
    'JoystickChannels', options.JoystickChannels, ...
    'StateChannel', options.StateChannel, ...
    'JoystickPredictionChannels', options.JoystickPredictionChannels);
metadata.channels(1:(nA+nB)) = metadata.channels(overallOrder);
end