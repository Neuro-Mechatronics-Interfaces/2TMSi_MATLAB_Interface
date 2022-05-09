%EXAMPLE__TMSI_CONTROLLER_SERVICE
%
% Starts up the TMSi controller server AND the TMSi data server.
%
% NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS! Each of these steps
%       should be started in a separate MATLAB session, possibly using
%       different machines on the same network switch.
%
%   1. On a local network computer (probably the one running TMSiSAGA
%       devices), you will first run `example__tmsi_controller_service.m`
%
%       This will start the control server. The control server broadcasts
%       to UDP ports 3030 ("state"), 3031 ("name"), and 3032 ("extra").
%       -> Technically there is also a `data` UDP at 3033, but that is not
%           a 
%
%       The "state" port allows you to move the state machine between:
%       "idle", "run", "record", and "quit" states (as of 5/7/22). 
%
%       The "name" port broadcasts the current filename to any udp 
%       receivers listening on that port within the local network. 
%
%           For example, a common local network is "10.0.0.x" for devices 
%           network, or "192.168.1.x" or "192.168.0.x" for devices 
%           connected to a network router or switch respectively. The 
%           broadcast address for a network is "a.b.c.255" network device
%           "a.b.c.x".
%
%       The "extra" port is just a loopback that broadcasts whatever was
%       sent to the control server as a string as it was received (e.g.
%       "set.tank.random/random_3025_01_02" for subject "random" and date
%       "3025-01-02"). 
%
%   2. Start the TMSi data server. Fortunately, this is technically done in
%       the same script as the control server so you really don't need to
%       worry about this.
%
%   3. Once the TMSi control/data servers are running, next start
%       another MATLAB session and run the `example__tmsi_stream_service.m`
%       to open communication with the TMSi SAGA device(s) then run a set
%       of nested blocking loops which handle sampling from those devices
%       and querying the control server state. 
%
%   3. Once steps 1-3 are completed, you should be able to access

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

%% Create TMSi CONTROLLER server
if exist('serv__controller', 'var')~=0
    if ~iscell(serv__controller)
        delete(serv__controller);
    end
    clear serv__controller;
end
serv__controller = tcpserver(SERVER_ADDRESS, SERVER_PORT_CONTROLLER, ...
    "ConnectionChangedFcn", @server__CON_connection_changed_cb);

% Set the server properties that we care about, here:
tank = string(sprintf("%s_%04d_%02d_%02d", DEFAULT_SUBJ, year(today), month(today), day(today)));
port_list = struct(...
    'state', UDP_STATE_BROADCAST_PORT, ...
    'name', UDP_NAME_BROADCAST_PORT, ...
    'extra', UDP_EXTRA_BROADCAST_PORT, ...
    'data', UDP_DATA_BROADCAST_PORT, ...
    'recv', UDP_CONTROLLER_RECV_PORT );

serv__controller.UserData = struct(...
    'state', "idle", ...
    'datashare', DEFAULT_DATA_SHARE, ...
    'tank', tank, ...
    'udp', udpport("byte", 'EnablePortSharing', true), ...
    'recv', udpport("byte"), ...
    'port', port_list, ...
    'address', BROADCAST_ADDRESS, ...
    'block', "0", ...
    'file', fullfile(DEFAULT_SUBJ, tank, sprintf("%s_0", tank)));
serv__controller.UserData.udp.EnableBroadcast = true;
configureCallback(serv__controller, "terminator", @(src, evt)server__CON_read_data_cb(src, evt));