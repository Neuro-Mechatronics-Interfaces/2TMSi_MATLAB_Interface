%EXAMPLE__TMSI_STREAM_SERVICE
% Script that enables sampling from multiple devices, and streams data from
% those devices to a server continuously.
%
% NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS! Each of these steps
%       should be started in a separate MATLAB session, possibly using
%       different machines on the same network switch.
%
%   1. On a local network computer (probably the one running TMSiSAGA
%       devices), you will first run `example__tmsi_controller_service.m`
%
%       This will start the control server. The control server broadcasts
%       to UDP ports 3030 ("state"), 3031 ("name"), 3032 ("extra"), and
%       3034 ("data"). 
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
%       The "data" port is where the actual data streams get passed along
%       to the data handler server.
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

%% Handle some basic startup stuff.
clc;
if exist('server', 'var')~=0
    delete(dev_server);
end

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

%% SET PARAMETERS
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

SN = [1005210029; 1005210028];
TAG = ["B"; "A"];
N_CLIENT = numel(TAG);


%% Setup device configurations.
config_device = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
                        'Triggers', true, ...
                        'BaseSampleRate', 4000, ...
                        'RepairLogging', false, ...
                        'ImpedanceMode', false, ...
                        'AutoReferenceMethod', false, ...
                        'ReferenceMethod', 'common',...
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);
config_channels = struct('uni', 1:64, ...
                         'bip', 1:4, ...
                         'dig', 0, ...
                         'acc', 0);

%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();
try
    % Code within the try-catch to ensure that all devices are stopped and 
    % closed properly in case of a failure.
    device = lib.getDevices({'usb'}, {'electrical'});  
    connect(device); 
catch e
    % In case of an error close all still active devices and clean up
    lib.cleanUp();  
        
    % Rethrow error to ensure you get a message in console
    rethrow(e)
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.
    setDeviceTag(device, SN, TAG);
    info = getDeviceInfo(device);
    enableChannels(device, horzcat({device.channels}));
    updateDeviceConfig(device);   
    device.setChannelConfig(config_channels);
    device.setDeviceConfig(config_device); 
catch e
    disconnect(device);
    lib.cleanUp();
    rethrow(e);
end

%% Create TMSi stream client + udpport
uReceiver = udpport("byte", "LocalPort", UDP_STATE_BROADCAST_PORT, "EnablePortSharing", true);
client = tcpclient(SERVER_ADDRESS, SERVER_PORT_DATA);
ch = device.getActiveChannels();
ch = horzcat(ch{:});

%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    start(device);
    state = "idle";
    BUF_SZ = 10000;
    sample_buffer = zeros(144, BUF_SZ);
    iSel = BUF_SZ;
    vec = {1:72, 73:144};
    while ~strcmpi(state, "quit")
        while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit"))
            [samples, num_sets] = device.sample();
            n = min(cellfun(@(c)size(c, 2), samples));
            if n >= 10000
                for ii = 1:numel(device)
                    sample_buffer(vec{ii}, :) = samples{ii, 1:BUF_SZ};
                    samples{ii}(:, BUF_SZ) = [];
                end
            end
            pause(0.25);
            if uReceiver.NumBytesAvailable > 0
                state = readline(uReceiver);
            end
        end
        if uReceiver.NumBytesAvailable > 0
            state = readline(uReceiver);
        end
    end
    stop(device);
    state = "idle";
catch me
    % Stop both devices.
    stop(device);
    warning(me.message);
%     lib.cleanUp();
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
