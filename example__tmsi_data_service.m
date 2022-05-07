%EXAMPLE__TMSI_DATA_SERVICE  Create and run the data server.


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

%% Channels configuration struct
channels = struct('A', struct('CREF', 1,  'UNI', 2:65, 'BIP', 66:69, 'TRIG', 70, 'STAT', 71, 'COUNT', 72), ...
                  'B', struct('CREF', 73, 'UNI', 74:138, 'BIP', 138:141, 'TRIG', 142, 'STAT', 143, 'COUNT', 144));

%% Create TMSi DATA server
if exist('server', 'var')~=0
    if ~iscell(server)
        delete(server);
    end
    clear server;
end
server = tcpserver(SERVER_ADDRESS, SERVER_PORT_DATA, ...
    "ConnectionChangedFcn", @server__DATA_connection_changed_cb);
server.UserData = struct('samples', [], 'channels', channels);
configureCallback(server, "terminator", @(src, evt)server__DATA_read_data_cb(src, evt, channels));


