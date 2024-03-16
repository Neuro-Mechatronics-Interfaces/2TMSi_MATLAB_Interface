clearvars -except block;
clc;

if exist('block','var')==0
    block = 0;
else
    block = block + 1;
end

SUBJ = "Max";
YYYY = year(today);
MM = month(today);
DD = day(today);
SEQUENCE = {'Move right index only.', 'r_d2'; ...
            'Move right ring only.', 'r_d4'; ...
            'Move left index only.', 'l_d2'; ...
            'Move left ring only.', 'l_d4'; ...
            'Move right index and left ring', 'r_d2_l_d4'};

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

% % Main figure: show spike rates
figRates = figure('Color','w','Name','Spike Rates', ...
    'Position', [4064        -790        1087         556], ...
    'ToolBar','none', ...
    'MenuBar','none');
L = tiledlayout(figRates, 1, 2);
ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k','YLim',[0 250]);
hA = bar(ax, timerObj.UserData.A.x, timerObj.UserData.A.y,'FaceColor',config.GUI.Color.A);
title(ax,'SAGA-A Rates','FontName','Tahoma','Color','k');

ax = nexttile(L);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k','YLim',[0 250]);
hB = bar(ax, timerObj.UserData.B.x, timerObj.UserData.B.y, 'FaceColor', config.GUI.Color.B);
title(ax,'SAGA-B Rates','FontName','Tahoma','Color','k');

% % Instructions figure: indicate where we are at in script
figInstruct = uifigure( ...
    'Name','Instructions',...
    'Color','k', ...
    'Position',[1161         572         560          83]);
instructionProgress = uiprogressdlg(figInstruct, 'Indeterminate', 'on', 'Message', 'Loading...');

timerObj.TimerFcn = @(src,~)bar_height_update_callback(src, hA, hB);
spikeClient.UserData = timerObj;

configureCallback(spikeClient, ...
    "terminator", ...
    @test_report_spikes); % Or some other callback here.
start(timerObj);
writeline(udpSender, 'run', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);
writeline(udpSender, sprintf('C:/Data/raw_data/%s/%s_%04d_%02d_%02d/%s_%04d_%02d_%02d_%%s_%d', SUBJ, SUBJ, YYYY, MM, DD, SUBJ, YYYY, MM, DD, block), ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.name);

pause(0.050);
writeline(udpSender, 'run', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

pause(0.050);

instructionProgress.Message = 'Calibrating: MOVE WRIST NOT FINGERS!';
instructionProgress.Indeterminate = 'off';
instructionProgress.Value = 0;

drawnow();
pause(0.050);

writeline(udpSender, 'c.static3:40000', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.params);

for ii = 1:40
    pause(0.25)
    instructionProgress.Value = ii/40;
    drawnow();
end

pause(0.050);
writeline(udpSender, 'rec', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

pause(0.050);

instructionProgress.Message = 'Recording in progress (instructions upcoming)...';
drawnow();
pause(0.1);

runInstructionSequence(udpSender, SEQUENCE, instructionProgress, ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.params);

instructionProgress.Message = 'Sequence complete!';
pause(1.0);


writeline(udpSender, 'run', ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);

delete(instructionProgress);
delete(figInstruct);

% stop(timerObj);
% delete(udpSender);
% delete(timerObj);
% delete(spikeClient);
% close all force;


