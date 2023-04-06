function deploy__tmsi_tcp_servers()
%DEPLOY__TMSI_TCP_SERVERS  Blocking function, which starts up the TMSi online data visualization server.
%
% See details in README.MD
close all force; 
clc;

config_file = parameters('config');
fprintf(1, 'Reading configuration file: %s\n\n', config_file);
[config, TAG, ~, N_CLIENT] = parse_main_config(config_file);


%% Create TMSi CONTROLLER server
fprintf(1,'Setting up CONTROLLER TCP server...\n');
serv__controller = tcpserver(config.Server.Address.TCP, config.Server.TCP.Controller, ...
    "ConnectionChangedFcn", @callback.serverHandleControllerConnectionChange);

% Set the server properties that we care about, here:
tank = string(sprintf("%s_%04d_%02d_%02d", config.Default.Subject, year(today), month(today), day(today)));

serv__controller.UserData = struct(...
    'state', "idle", ...
    'config', config, ...
    'datashare', config.Default.Folder, ...
    'tank', tank, ...
    'udp', udpport("byte", 'EnablePortSharing', true, "LocalHost", config.Server.Address.UDP), ...
    'recv', udpport("byte", "LocalPort", config.Server.UDP.recv, "LocalHost", config.Server.Address.UDP), ...
    'port', config.Server.UDP, ...
    'address', config.Server.Address.UDP, ...
    'block', "0", ...
    'file', strrep(fullfile(config.Default.Folder, config.Default.Subject, tank, sprintf("%s_%%s_%%d", tank)), "\", "/"));
serv__controller.UserData.udp.EnableBroadcast = true;
configureCallback(serv__controller, "terminator", @callback.serverHandleControllerMessages);

%% Create TMSi ONLINE DATA VISUALIZER server for SAGA-<TAG>
for ii = 1:N_CLIENT
    tag = TAG{ii};
    serv__visualizer.(tag) = tcpserver(...
            config.Server.Address.TCP, ...
            config.Server.TCP.(tag).Viewer, ...
            "ConnectionChangedFcn", @(src,~)callback.handleConnectionChangedIndicator(src,"app","DataConnectionStatusLamp"), ...
            "Timeout", 0.5);    
    serv__visualizer.(tag).UserData = struct(...
                'app', SAGA_GUI(tag, config), ...
                'n', config.SAGA.(tag).Channels.n.samples);
    n_samples = config.SAGA.(tag).Channels.n.samples + 1;
    configureCallback(serv__visualizer.(tag), "byte", 8*(n_samples), ...
        @(src, evt)callback.serverVisualizationCallbackWrapper(src, evt));
    serv__controller.UserData.visualizer.(tag) = serv__visualizer.(tag);
end

%% Create TMSi Worker Server
%   cfg__worker - Array struct, where each element has the fields:
%           'delimiter' - (usually, '.' -- depends on how data is passed to "worker" server)
%           'tag' - "A" or "B"
%           'port' - usually 4000 (A) or 4001 (B)
%           'sync_bit' - Usually this is 9 or 10
%           'type' - Can be ".poly5" or ".mat"
%           'fcn' - The callback function handle
%           'terminator' - Typically "LF" but can be "CR" or "CR/LF"
%               ("LF" - line feed: \n | "CR" - carriage return: \r)
% if config.Default.Use_Worker_Server
%     fprintf(1,'Deploying post-processing WORKER TCP servers...\n');
%     cfg__worker = struct(...
%         'delimiter', {'.'; '.'}, ...
%         'tag', {'A'; 'B'}, ...
%         'address', {config.Server.Address.Worker; config.Server.Address.Worker}, ...
%         'port', {config.Server.TCP.A.Worker; config.Server.TCP.B.Worker}, ...
%         'sync_bit', {config.SAGA.A.Trigger.Bit; config.SAGA.B.Trigger.Bit}, ...
%         'type', {config.SAGA.A.FileType; config.SAGA.B.FileType}, ...
%         'fcn', {@callback.exportFigures; @callback.exportFigures}, ...
%         'terminator', {'LF'; 'LF'});
%     serv__worker = deploy__postprocessing_worker_server(cfg__worker);
%     fprintf(1,'complete\n');
% end

%% Keep application running
fprintf(1,'\n\n\t\t->\t[%s] Running all servers until application windows are closed.\t\t<-\t\n\n\n', string(datetime('now')));
keepBlocking = true;
while (keepBlocking)
    keepBlocking = false;
    for ii = 1:N_CLIENT
        keepBlocking = keepBlocking || isvalid(serv__visualizer.(TAG{ii}).UserData.app); 
    end
    if keepBlocking && (serv__controller.UserData.recv.NumBytesAvailable > 0)
        msg = readline(serv__controller.UserData.recv);
        msg_info = strsplit(msg, '.');
        switch msg_info{1}
            case 'set'
                if ~callback.serverHandleControllerSetterMessage(serv__controller, msg_info{2}, strrep(msg_info{3},'\','/'))
                    fprintf(1, '[UDP recv] Bad `set` message ("%s")\n', msg);
                end
            otherwise
                fprintf(1,'[UDP recv] Unhandled message ("%s")\n', msg);
        end
    end
    pause(1);
end

%% Shutdown servers/ports
try
    delete(serv__controller.UserData.udp);
    fprintf(1,'Closed controller broadcast UDP port successfully.\n');
catch
    fprintf(1,'Error closing controller broadcast UDP port.\n');
end
try
    delete(serv__controller.UserData.recv);
    fprintf(1,'Closed controller message-receiver UDP port successfully.\n');
catch
    fprintf(1,'Error closing controller message-receiver UDP port.\n');
end
for ii = 1:N_CLIENT
    try
        delete(serv__visualizer.(TAG{ii}));
        fprintf(1,'Closed online data visualization TCP-server-%s successfully.\n', TAG{ii});
    catch
        fprintf(1,'Error closing online data visualization TCP-server-%s.\n', TAG{ii});
    end
end
try
    delete(serv__controller);
    fprintf(1,'Successfully closed TMSi controller TCP-server. Hope you did not leave any SAGA device loops running!\n');
catch
    fprintf(1,'Couldn''t close the TMSi controller TCP-server. Hopefully it shut down SAGA devices before this failure!\n');
end
pause(1);

end