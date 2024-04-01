function config = load_spike_server_config()
%LOAD_SPIKE_SERVER_CONFIG  Shortcut to load the configuration struct for spike server version of TMSi stream service, suppressing verbose command line output.
%
% Syntax:
%   config = load_spike_server_config();
%
% Output:
%   config - Struct with fields: 
%               * 'SAGA' (sub-fields 'A', 'B' are structs with fields 
%                         indicating device status, identity, and channel
%                         assignments.)
%               * 'Default' (default values of parameters, particularly
%                            used in the "..._plus..." version of the SAGA
%                            device handler state machine code.)
%               * 'UDP' (struct with UDP target address and port info)
%               * 'TCP' (struct with TCP server address and port info)
%
% See also: Contents, parameters, parse_main_config

[config_file, saga_file] = parameters(...
    'config_stream_service_plus', ...
    'saga_file');
config = parse_main_config(...
    config_file, ...
    saga_file, ...
    'Verbose', false);

end