function serv = deploy__controller_server(config)
%DEPLOY__CONTROLLER_SERVER  Deploy controller TCP server given config object.
%
% Syntax:
%   serv = deploy__controller_server(config);
%
% Inputs:
%   config - If not provided, parses config from default file specified in
%               `parameters.m`
%
% Output:
%   serv   - tcpserver object, which is the "Controller" for TMSiSAGA
%               recordings.
%
% See also: Contents, deploy__tmsi_tcp_servers, parameters

if nargin < 1
    config = parse_main_config(parameters('config'));
end

serv = tcpserver(config.Server.Address.TCP, config.Server.TCP.Controller, ...
    "ConnectionChangedFcn", @server__CON_connection_changed_cb);

% Set the server properties that we care about, here:
tank = string(sprintf("%s_%04d_%02d_%02d", config.Default.Subject, year(today), month(today), day(today)));

serv.UserData = struct(...
    'state', "idle", ...
    'config', config, ...
    'datashare', config.Default.Folder, ...
    'tank', tank, ...
    'udp', udpport("byte", 'EnablePortSharing', true), ...
    'recv', udpport("byte"), ...
    'port', config.Server.UDP, ...
    'address', config.Server.Address.UDP, ...
    'block', "0", ...
    'file', strrep(fullfile(config.Default.Folder, config.Default.Subject, tank, sprintf("%s_%%s_0", tank)), "\", "/"));
serv.UserData.udp.EnableBroadcast = true;
configureCallback(serv, "terminator", @(src, evt)callback.serverHandleControllerMessages(src, evt));

end