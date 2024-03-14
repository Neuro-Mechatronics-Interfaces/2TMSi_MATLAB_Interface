function config = load_spike_server_config()
%LOAD_SPIKE_SERVER_CONFIG  Loads configuration struct for spike server version of TMSi stream service.
%
% Syntax:
%   config = load_spike_server_config();

[config_file, saga_file] = parameters('config_stream_service_plus', 'saga_file');
config = parse_main_config(config_file, saga_file, 'Verbose', false);

end