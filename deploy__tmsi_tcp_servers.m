%DEPLOY__TMSI_TCP_SERVERS
%
% Starts up the TMSi controller server AND the TMSi data server.
%
% --- The README.MD should now be most-current (5/8/22) -----
%
% NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS! Each of these steps
%       should be started in a separate MATLAB session, possibly using
%       different machines on the same network switch.
%
%   1. On a local network computer (probably the one running TMSiSAGA
%       devices), you will first run `deploy__tmsi_tcp_servers.m` (this
%       script).
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
%   2. Once the TMSi control/data servers are running, next start
%       another MATLAB session and run the `example__tmsi_stream_service.m`
%       to open communication with the TMSi SAGA device(s) then run a set
%       of nested blocking loops which handle sampling from those devices
%       and querying the control server state. 
close all force;
% BROADCAST_ADDRESS = "192.168.1.255";
% SERVER_ADDRESS = "128.2.244.60";
BROADCAST_ADDRESS = "127.0.0.255";
SERVER_ADDRESS = "127.0.0.1";
UDP_STATE_BROADCAST_PORT = 3030;    % UDP port: state
UDP_NAME_BROADCAST_PORT = 3031;     % UDP port: name
UDP_EXTRA_BROADCAST_PORT = 3032;    % UDP port: extra
UDP_DATA_BROADCAST_PORT  = 3034;    % UDP port: data
UDP_CONTROLLER_RECV_PORT = 3035;    % UDP port: receiver (controller)
SERVER_PORT_CONTROLLER = 5000;      % Server port for CONTROLLER
SERVER_PORT_DATA = struct('A', 5020, 'B', 5021); % Ports for DATA servers. % Assign by TMSiSAGA tag ('A', 'B', .. etc)
DEFAULT_DATA_SHARE = "R:\NMLShare\raw_data\primate";
DEFAULT_SUBJ = "Test";
TRIGGER_CHANNEL = struct('A', 70, 'B', 70); % In `example__tmsi_stream_service` session, you can do:
% >> find(ch.isTrigger);   
%   That should give you the channel index (first thing returned in that
%   array).
TRIGGER_BIT = struct('A', 9, 'B', 9);
N_SAMPLES_LOOP_BUFFER = 16384;
N_TRIGGERS_RMS = 20; % Number of triggers to average on
RMS_SAMPLE_EPOCH = round(([12.5, 50]).*4); % milliseconds, with 4 kHz sample rate 
FIGURE_POSITION = struct(...
    'A', [50 450 560 420], ...
    'B', [50 100 560 420]);
COLORS = [0 0 0; ...
          0 0 1; ...
          1 0 0; ...
          1 0 1]; 

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

%% Channels configuration struct
channels = struct('A', struct('CREF', 1,  'UNI', 2:65, 'BIP', 66:69, 'AUX', 70:71, 'TRIG', TRIGGER_CHANNEL.A, 'STAT', 72, 'COUNT', 73, 'n', struct('channels', 73, 'samples', N_SAMPLES_LOOP_BUFFER)), ...
                  'B', struct('CREF', 1,  'UNI', 2:65, 'BIP', 66:69, 'TRIG', TRIGGER_CHANNEL.B, 'STAT', 70, 'COUNT', 71, 'n', struct('channels', 71, 'samples', N_SAMPLES_LOOP_BUFFER)));

%% Create TMSi DATA server for SAGA-<TAG>
if exist('serv__data', 'var')~=0
    my_tags = fieldnames(serv__data);
    for ii = 1:numel(my_tags)
        delete(serv__data.(my_tags{ii})); 
    end
    clear serv__data;
end
my_tags = fieldnames(SERVER_PORT_DATA);
fig = struct;
ax_hd = struct;
ax_line = struct;
con = struct;
lab = struct;
h = struct;
L = struct;
serv__data = struct;
xvec = (RMS_SAMPLE_EPOCH(1):RMS_SAMPLE_EPOCH(2))./4;
nsamples_bip = numel(xvec);
for ii = 1:numel(my_tags)
    tag = my_tags{ii};
    fig.(tag) = figure('Name', sprintf('SAGA-%s', tag), ...
        'Color', 'w', 'Position', FIGURE_POSITION.(tag));
    L.(tag) = tiledlayout(fig.(tag),3,3);
    ax_hd.(tag) = nexttile(L.(tag), 1, [2 2]);
    colorbar(ax_hd.(tag));
    set(ax_hd.(tag), ...
        "NextPlot", 'add', "FontName", 'Tahoma', ...
        'XTick', 1:8, 'YTick', 1:8, 'XLim', [0.5 8.5], ...
        'YLim', [0.5 8.5], 'XTickLabel', 1:8:57);
    [~, con.(tag)] = contourf(ax_hd.(tag), 1:8, 1:8, randn(8, 8));
    title(ax_hd.(tag), "HD-EMG Grid", ...
        "FontName", 'Tahoma', 'Color', [0.6 0.6 0.6])
    lab.(tag) = title(L.(tag), sprintf("SAGA-%s::x", tag), ...
        "FontName", 'Tahoma', "Color", 'k', 'FontWeight', 'bold');
    ax_line.(tag) = nexttile(L.(tag), 3, [2 1]);
    set(ax_line.(tag), 'NextPlot', 'add', 'FontName', 'Tahoma', ...
        'XLim', [0 1], 'YLim', [-0.5 4.5], 'XTick', [], 'YTick', 0.5:1:3.5, ...
        'YTickLabel', 1:4, 'YDir', 'reverse');
    title(ax_line.(tag), "Bipolar", 'Color', [0.6 0.6 0.6], 'FontName', 'Tahoma');
    colorbar(ax_line.(tag));
    h.(tag) = line(ax_line.(tag), 'XData', [], 'YData', [], 'LineWidth', 1.5, 'Color', 'k');
    im.(tag) = imagesc(ax_line.(tag), 'XData', [0 1], 'YData', [0 4], 'CData', zeros(4, 1));
    %TODO: Add streaming single-channel option (not ready for 5/12)
    ax_multi.(tag) = nexttile(L.(tag), 7, [1 3]);
    title(ax_multi.(tag), "BIP (time)", 'Color', [0.6 0.6 0.6], 'FontName', 'Tahoma');
    
    set(ax_multi.(tag), 'NextPlot', 'add', 'FontName', 'Tahoma', ...
        'XColor', 'k', 'YColor', 'k', 'LineWidth', 1.5);
    multi_line.(tag) = gobjects(4, 1);
    for iLine = 1:4
        multi_line.(tag)(iLine) = line(ax_multi.(tag), xvec, ...
            zeros(size(xvec)), 'LineWidth', 1.5, 'Color', COLORS(iLine, :));
    end
    xlabel(ax_multi.(tag), 'Time (ms)', 'FontName', 'Tahoma', ...
        'Color', [0.75 0.75 0.75], 'FontWeight', 'bold');
    xlim(ax_multi.(tag), [0 50]);
    patch(ax_multi.(tag), [0 0 RMS_SAMPLE_EPOCH(1)/4 RMS_SAMPLE_EPOCH(1)/4], [-20 20 20 -20], ...
        'r', 'FaceAlpha', 0.75, 'EdgeColor', 'none');
    serv__data.(tag) = tcpserver(SERVER_ADDRESS, SERVER_PORT_DATA.(tag), ...
        "ConnectionChangedFcn", @server__DATA_connection_changed_cb, ...
        "Timeout", 0.5);
    serv__data.(tag).UserData = struct(...
        'uni', con.(tag), ...
        'lab', lab.(tag), ...
        'lab_expr', sprintf('SAGA-%s::%%s', tag), ...
        'line', h.(tag), ...
        'multi_line', multi_line.(tag), ...
        'bip', im.(tag), ...
        'data', [], ...
        'n', channels.(tag).n, ...
        'channels', channels.(tag), ...
        'last', struct('set', [nan, nan]), ...
        'rms', struct('epoch', RMS_SAMPLE_EPOCH, ...
                      'index', 1, ...
                      'index_max', N_TRIGGERS_RMS, ...
                      'uni',zeros(8, 8, N_TRIGGERS_RMS), ...
                      'bip', zeros(4, 1, N_TRIGGERS_RMS)), ...
        'ts', struct('bip', zeros(4, nsamples_bip, N_TRIGGERS_RMS)), ...
        'sync', struct('ch', TRIGGER_CHANNEL.(tag), ...
                       'bit', TRIGGER_BIT.(tag)), ...
        'tag', tag);
    n_bytes = 8*channels.(tag).n.samples*channels.(tag).n.channels;
    configureCallback(serv__data.(tag), "byte", n_bytes, ...
        @(src, evt)server__DATA_read_data_cb(src, evt));
end
