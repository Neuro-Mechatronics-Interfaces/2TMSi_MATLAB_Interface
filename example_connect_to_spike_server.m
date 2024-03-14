clear;
clc;

config = load_spike_server_config();

spikeClient = tcpclient(config.TCP.SpikeServer.Address, ...
                   config.TCP.SpikeServer.Port);
spikeClient.UserData = struct(...
    'A', struct('x', 1:numel(config.Default.N_Spike_Channels), ...
                'y', zeros(1,config.Default.N_Spike_Channels)), ...
    'B', struct('x', 1:numel(config.Default.N_Spike_Channels), ...
                'y', zeros(1,config.Default.N_Spike_Channels))); 
udpSender = udpport("byte");

configureCallback(spikeClient, ...
    "terminator", ...
    @test_report_spikes); % Or some other callback here.


fig = figure('Color','w','Name','Spike Counts', ...
    'Position', [381 559 883 347], ...
    'ToolBar','none', ...
    'MenuBar','none');
L = tiledlayout(fig, 1, 2);
ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
hA = bar(ax, spikeClient.UserData.A.x, spikeClient.UserData.A.y);
title(ax,'SAGA-A Counts','FontName','Tahoma','Color','k');

ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
hB = bar(ax, spikeClient.UserData.B.x, spikeClient.UserData.B.y);
title(ax,'SAGA-B Counts','FontName','Tahoma','Color','k');

timerObj = timer('TimerFcn', @(~, ~, hA, hB)bar_height_update_callback(hA, hB), ...
                 'BusyMode', 'queue', ...
                 'Period', 0.1);

pause(2.0);
disp('Sending run command...');
pause(2.0);
writeline(udpSender, 'run', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

pause(0.050);
start(timerObj);


