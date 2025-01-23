function  config = load_gestures_config(version)
%LOAD_GESTURES_CONFIG  Shortcut to load the configuration struct for gesture server.
%
% Syntax:
%   config = load_gestures_config();
%
% Output:
%   config - Struct with fields:
%               * 'SAGA' (sub-fields 'A', 'B' are structs with fields
%                         indicating device status, identity, and channel
%                         assignments.)
%               * 'Gestures' (sub-fields related to GUI/task
%                                   parameterization)
%               * 'Default' (sub-fields related to data acquisition)
%               * 'Device' (sub-fields for device initialization)
%
% See also: Contents, parameters, parse_main_config

arguments
    version (1,1) {mustBePositive, mustBeInteger} = 2;
end

[config_file, saga_file] = parameters(...
    sprintf('config_gestures_v%d', version), ...
    'saga_file');
[config, TAG, SN, N_CLIENT, SAGA, config_device, config_channels] = parse_main_config(...
    config_file, ...
    saga_file, ...
    'Verbose', false);
config.Device = struct(...
    'Tag', TAG, 'SerialNumber', SN, ...
    'N', N_CLIENT, 'SAGA', SAGA, ...
    'DeviceConfig', config_device, ...
    'ChannelConfig', config_channels);
config.Gestures.Animation.Frame_Period = 1/config.Gestures.Animation.Frame_Rate;
end