%EXAMPLE__TMSI_STREAM_SERVICE
% Script that enables sampling from multiple devices, and streams data from
% those devices to a server continuously.

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
SERVER_ADDRESS = '10.0.0.128';
SERVER_PORT_START = 5000; % Server port

SN = [1005210029; 1005210028];
TAG = ["B"; "A"];
N_CLIENT = numel(TAG);
DEFAULT_DATA_SHARE = "R:\NMLShare\raw_data\primate";
DEFAULT_SUBJ = "Test";

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

%% Create TMSi device server(s)
devtag = cellfun(@(c)c.tag, info); % Get the actual indexed assignments.
[~,hostname] = system('hostname');
hostname = string(strtrim(hostname));
fprintf(1, 'Starting server on <strong>%s</strong> at <strong>%s</strong>\n\n', ...
    hostname, SERVER_ADDRESS);
if exist('dev_server', 'var')~=0
    if ~iscell(dev_server)
        delete(dev_server);
    end
    clear server;
end
dev_server = cell(N_CLIENT, 1);

port = nan(N_CLIENT, 1);
for ii = 1:N_CLIENT
    
    port(ii) = SERVER_PORT_START + ii;
    dev_server{ii} = tcpserver(SERVER_ADDRESS, port(ii), ...
        "ConnectionChangedFcn", @server__DEV_connection_changed_cb);
    dev_server{ii}.UserData = struct(...
        'name', sprintf("SAGA-%s", SAGA(ii)), ...
        'tag', SAGA(ii), ...
        'k', -1, ...
        'samples', zeros(31, 31), ...
        'index', 1);
    
    configureCallback(dev_server{ii}, "byte", 7688, @(src, evt)server__DEV_read_data_cb(src, evt));
    fprintf(1, "\t\t->\tServer created and running at <strong>%s:%d</strong>\n", ...
        dev_server{ii}.ServerAddress, dev_server{ii}.ServerPort);
    pause(0.25);
end
pause(0.75);
dev_server = vertcat(dev_server{:});
fprintf(1, "\t->\tServer objects created and running at <strong>%s:%d</strong>\n", dev_server.ServerAddress, dev_server.ServerPort);

%% Create TMSi CONTROLLER server
if exist('server', 'var')~=0
    if ~iscell(server)
        delete(server);
    end
    clear server;
end
server = tcpserver(SERVER_ADDRESS, SERVER_PORT_START, ...
    "ConnectionChangedFcn", @server__CON_connection_changed_cb);
% Set the server properties that we care about, here:
tank = string(sprintf("%s_%04d_%02d_%02d", DEFAULT_SUBJ, year(today), month(today), day(today)));
server.UserData = struct(...
    'state', "idle", ...
    'datashare', DEFAULT_DATA_SHARE, ...
    'tank', tank, ...
    'block', "0", ...
    'file', fullfile(DEFAULT_SUBJ, tank, sprintf("%s_0", tank)));
configureCallback(server, "terminator", @(src, evt)server__CON_read_data_cb(src, evt));

%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    start(device);
    while ~strcmpi(server.UserData.state, "quit")
        while true
            [samples, num_sets] = device.sample();

            pause(0.25); % Wait 250-ms then go again.
        end
    end
    stop(device);
catch
    % Disconnect both devices.
    disconnect(device);     
    lib.cleanUp();
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
