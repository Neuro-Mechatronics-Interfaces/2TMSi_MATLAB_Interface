clear;
clc;

config = load_spike_server_config();
udpSender = udpport("byte");

writeline(udpSender, 'idle', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

spikeClient = tcpclient(config.TCP.SpikeServer.Address, ...
                   config.TCP.SpikeServer.Port);
timerObj = timer('ExecutionMode', 'fixedRate', ...
                 'Name', 'Spike-Server-Bar-Callback-Timer-0', ...
                 'Period', 0.030);
timerObj.UserData = struct(...
    'A', struct('x', (1:config.Default.N_Spike_Channels)', ...
                'y', zeros(config.Default.N_Spike_Channels,1)), ...
    'B', struct('x', (1:config.Default.N_Spike_Channels)', ...
                'y', zeros(config.Default.N_Spike_Channels,1))); 
fig = figure('Color','w','Name','Spike Counts', ...
    'Position', [381 559 883 347], ...
    'ToolBar','none', ...
    'MenuBar','none');
L = tiledlayout(fig, 1, 2);
ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k','YLim',[0 100]);
hA = bar(ax, timerObj.UserData.A.x, timerObj.UserData.A.y,'FaceColor',config.GUI.Color.A);
title(ax,'SAGA-A Counts','FontName','Tahoma','Color','k');

ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k','YLim',[0 100]);
hB = bar(ax, timerObj.UserData.B.x, timerObj.UserData.B.y, 'FaceColor', config.GUI.Color.B);
title(ax,'SAGA-B Counts','FontName','Tahoma','Color','k');

timerObj.TimerFcn = @(src,~)bar_height_update_callback(src, hA, hB);
spikeClient.UserData = timerObj;

configureCallback(spikeClient, ...
    "terminator", ...
    @test_report_spikes); % Or some other callback here.

pause(2.0);
disp('Sending run command...');
pause(2.0);
writeline(udpSender, 'run', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

pause(0.050);
disp('Timer started...');
start(timerObj);


