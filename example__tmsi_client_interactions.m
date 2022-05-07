%EXAMPLE__TMSI_CLIENT_INTERACTIONS
%
% Example of how to interact with the TMSi stream server(s) via the CONTROL
% server, once everything is running on the computer hosting some arbitrary
% number of TMSi SAGA devices supposed to sample from the same subject
% (relatively) simultaneously.

BROADCAST_ADDRESS = "10.0.0.255";
SERVER_ADDRESS = "10.0.0.128";
UDP_STATE_BROADCAST_PORT = 3030;    % UDP port: state
UDP_NAME_BROADCAST_PORT = 3031;     % UDP port: name
UDP_EXTRA_BROADCAST_PORT = 3032;    % UDP port: extra
UDP_DATA_BROADCAST_PORT  = 3034;    % UDP port: data
UDP_CONTROLLER_RECV_PORT = 3035;    % UDP port: receiver (controller)
SERVER_PORT_CONTROLLER = 5000;           % Server port for CONTROLLER
SERVER_PORT_DATA       = 5001;           % Server port for DATA
DEFAULT_DATA_SHARE = "R:\NMLShare\raw_data\primate";
DEFAULT_SUBJ = "Test";