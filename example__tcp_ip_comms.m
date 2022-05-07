%%EXAMPLE__TCP_IP_COMMS  From MATLAB builtin documentation.
% Get basic data about system address, hostname:
if exist('client', 'var')~=0
    if ~iscell(client)
        delete(client);
    end
end
close all force;
clearvars -except server; 
clc;

% Basic parameters.
% SERVER_ADDRESS = '10.0.0.81';
SERVER_ADDRESS = '10.0.0.128';
SERVER_PORT_START = 5000;
N_CLIENT = 8;
SAGA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
GROUP = ["HD-EMG", "BIP", "ACC", "CONTROL"];

%%
[~, hostname] = system('hostname');
LOCAL = strtrim(hostname);
[~, address] = resolvehost(LOCAL);
fprintf(1, '\t->\tTarget server at <strong>%s</strong>\n', SERVER_ADDRESS);
fprintf(1, '\t\t->\tLOCALHOST: <strong>%s</strong> (%s)\n\n', LOCAL, address);

%% (Optionally create local server) and create associated clients
if strcmpi(address, SERVER_ADDRESS)
    if exist('server', 'var')~=0
        if ~iscell(server)
            delete(server);
        end
        clear server;
    end
    server = cell(N_CLIENT, 1);
end
client = cell(N_CLIENT, 1);
port = nan(N_CLIENT, 1);
saga = repelem(SAGA, 1, numel(GROUP));
grp = repmat(GROUP, 1, numel(SAGA));
for ii = 1:N_CLIENT
    port(ii) = SERVER_PORT_START - 1 + ii;
    if strcmpi(address, SERVER_ADDRESS)
        server{ii} = tcpserver(address, port(ii), "ConnectionChangedFcn", @test__connectionFcn);
        server{ii}.UserData = struct('tag', sprintf("SAGA-%s-%s", saga(ii), grp(ii)), ...
            'k', -1, 'samples', zeros(31, 31), 'index', 1, ...
            'figure', [], 'axes', [], 'surface', []);
        configureCallback(server{ii}, "byte", 7688, @(src, evt)test__readDataFcn(src, evt));
        fprintf(1, "\t\t->\tServer created and running at <strong>%s:%d</strong>\n", ...
            server{ii}.ServerAddress, server{ii}.ServerPort);
    end
    client{ii} = tcpclient(SERVER_ADDRESS, port(ii), "Timeout", 5);
    fprintf(1, "\t\t->\tClient running on port <strong>%d</strong>\n", client{ii}.Port);
    pause(0.25);
end
pause(0.75);
if strcmpi(address, SERVER_ADDRESS)
    server = vertcat(server{:});
end
client = vertcat(client{:});

%% Write data to the server.
fig = figure(...
    'Name', 'Placeholder (CLOSE TO STOP LOOP)', ...
    'Color', 'w', ...
    'Units', 'Normalized', ...
    'Position', [0.1 0.8 0.75 0.075]);
annotation(fig, 'textbox', [0 0 1 1], ...
    'String', '(CLOSE TO STOP LOOP)', ...
    'FitBoxToText', 'on', ...
    'FontName', 'Tahoma', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'middle', ...
    'FontSize', 32, ...
    'FontWeight', 'bold', ...
    'EdgeColor', 'none', ...
    'Color', 'k');
while isvalid(fig)
    try
        for ii = 1:N_CLIENT
            write(client(ii), randn(1, 961).*1e-2, "double");
            drawnow limitrate
        end
    catch
        delete(gcf);
        break; 
    end
end
pause(1);
clear client;  % Connection not closed until client is cleared.
% Note that server will still be running in background.