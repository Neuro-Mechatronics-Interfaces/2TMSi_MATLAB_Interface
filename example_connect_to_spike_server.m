clearvars -except block teensy;
close all force;
clc;

if exist('block','var')==0
    block = 0;
else
    block = block + 1;
end

SUBJ = "Max";
dt = datetime('today', 'TimeZone', 'America/New_York');
YYYY = year(dt);
MM = month(dt);
DD = day(dt);
SEQUENCE = {'Move right index only.', 'r_d2'; ...
            'Move right ring only.', 'r_d4'; ...
            'Move left index only.', 'l_d2'; ...
            'Move left ring only.', 'l_d4'; ...
            'Move right index and left ring', 'r_d2_l_d4'};
instructed = ["Lift left index." ; ...
"Press left index."; ...
"Lift left middle finger."; ...
"Press left middle finger."; ...
"Lift left ring finger."; ...
"Press left ring finger."; ...
"Lift right index."; ...
"Press right index."; ...
"Lift right middle finger."; ...
"Press right middle finger."; ...
"Lift right ring finger."; ...
"Press right ring finger."; ...
"Rest"; ...
"Flex right wrist."; ...
"Extend right wrist."; ...
"Flex left wrist."; ...
"Extend left wrist."; ...
"Ulnar deviate right wrist."; ...
"Radial deviate right wrist."; ...
"Ulnar deviate left wrist.";
"Radial deviate left wrist."];

config = load_spike_server_config();
udpSender = udpport("byte");

% writeline(udpSender, 'idle', ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.state);

% spikeClient = tcpclient(config.TCP.SpikeServer.Address, ...
%                    config.TCP.SpikeServer.Port);
rmsClient = tcpclient(config.TCP.RMSServer.Address, ...
    config.TCP.RMSServer.Port);
timerObj = timer('ExecutionMode', 'fixedRate', ...
                 'Name', 'Spike-Server-Bar-Callback-Timer-0', ...
                 'BusyMode', 'queue', ...
                 'Period', 0.050);
n_rate_features = 64*numel(config.Default.Rate_Smoothing_Alpha);

timerObj.UserData = struct(...
    'A', struct('x', (1:n_rate_features)', ...
                'y', zeros(1,n_rate_features)), ...
    'B', struct('x', (1:n_rate_features)', ...
                'y', zeros(1,n_rate_features)), ...
    'Zprev', zeros(n_rate_features*2,1), ...
    'NTotal', 2*n_rate_features, ...
    'EigenPairs', [2,4; 3,5; 6,12], ... % Will probably change!
    'CurrentReportedPose', TMSiAccPose.Unknown, ...
    'CurrentAssignedPose', 0, ...
    'AutoEnc', [], ...
    'UpdateGraphics', false, ...
    'NeedsCalibration', true, ...
    'DimReduceData', nan(1000, n_rate_features*2), ...
    'coeff', eye(n_rate_features*2), ...
    'explained', ones(n_rate_features*2,1).*100/(n_rate_features*2), ...
    'CalibrationIndex', 1, ...
    'Calibration', nan(n_rate_features*2, 1000), ...
    'Data', struct( ...
        'X', zeros(0,1), ...
        'Y', zeros(0, n_rate_features*2), ...
        'Pose', zeros(0,1))); 
[timerObj.UserData.Xq, timerObj.UserData.Yq] = meshgrid(1:0.25:8);
% % Main figure: show spike rates
switch getenv("COMPUTERNAME")
    case 'NML-NHP'
        FIG_RATES_POSITION = [4064        -790        1087         556];
    case 'MAX_LENOVO'
        FIG_RATES_POSITION = [86         331        1066         515];
    otherwise
        FIG_RATES_POSITION = [100 100 1000 500];
end
figRates = figure('Color','w','Name','Spike Rates', ...
    'Position', FIG_RATES_POSITION, ...
    'ToolBar','none', ...
    'MenuBar','none');
L = tiledlayout(figRates, 2, 3);
ax = nexttile(L,1,[2 1]);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
% hA = bar(ax, timerObj.UserData.A.x, timerObj.UserData.A.y,'FaceColor',config.GUI.Color.A);
hA = imagesc(ax, zeros(8,8));
title(ax,'SAGA-A RMS','FontName','Tahoma','Color','k');

ax = nexttile(L,2,[1 1]);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k','YLim',[0 1000]);
hZ = bar(ax, 1:numel(instructed), zeros(1,numel(instructed)),'FaceColor','k');
title(ax,'Latent','FontName','Tahoma','Color','k');

ax = nexttile(L,3,[2 1]);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','k');
% hB = bar(ax, timerObj.UserData.B.x, timerObj.UserData.B.y, 'FaceColor', config.GUI.Color.B);
hB = imagesc(ax, zeros(8,8));
title(ax,'SAGA-B RMS','FontName','Tahoma','Color','k');
hTxt = title(L, "Unknown", 'FontName', 'Tahoma', 'Color', 'k');
hTxt2 = subtitle(L, "Unknown", "FontName", "Tahoma", 'Color', [0.65 0.65 0.65]);

ax = nexttile(L,5,[1 1]);
set(ax,'NextPlot','add','FontName','Tahoma','XColor','k','YColor','none','YLim',[-2500 2500]);
hC = bar(ax, 1:12, zeros(1,12),'EdgeColor','none','FaceColor','m');


% % Instructions figure: indicate where we are at in script
% figInstruct = uifigure( ...
%     'Name','Instructions',...
%     'Color','k', ...
%     'Position',[1161         572         560          83]);
% instructionProgress = uiprogressdlg(figInstruct, 'Indeterminate', 'on', 'Message', 'Loading...');

% timerObj.TimerFcn = @(src,~)listener_timer_callback(src, hA, hB, hZ, hTxt, hTxt2, autoEnc, net, Label);
timerObj.TimerFcn = @(src,~)listener_timer_callback(src, hA, hB, hZ, hC, hTxt, hTxt2);
timerObj.UserData.ControlServer = tcpserver("0.0.0.0", config.TCP.ControlServer.Port);
% spikeClient.UserData = struct('Timer', timerObj);
rmsClient.UserData = struct('Timer', timerObj);

% configureCallback(spikeClient, ...
%     "terminator", ...
%     @test_report_spikes); % Or some other callback here.
configureCallback(rmsClient, ...
    "terminator", ...
    @test_report_rms); % Or some other callback here.
writeline(udpSender, "run", ...
    config.UDP.Socket.StreamService.Address, ...
    config.UDP.Socket.StreamService.Port.state);
timerObj.UserData.XBoxKeys = init_xbox_keys();
timerObj.UserData.XBoxServer = tcpserver("0.0.0.0", config.TCP.XBoxServer.Port);
start(timerObj);


% start(timerObj);
% writeline(udpSender, 'run', ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.state);
% writeline(udpSender, sprintf('C:/Data/raw_data/%s/%s_%04d_%02d_%02d/%s_%04d_%02d_%02d_%%s_%d', SUBJ, SUBJ, YYYY, MM, DD, SUBJ, YYYY, MM, DD, block), ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.name);

% pause(0.050);
% 
% instructionProgress.Message = 'Calibrating: MOVE WRIST NOT FINGERS!';
% instructionProgress.Indeterminate = 'off';
% instructionProgress.Value = 0;
% 
% drawnow();
% pause(0.050);
% 
% writeline(udpSender, 'c.dynamic:40000', ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.params);

% for ii = 1:40
%     pause(0.25)
%     instructionProgress.Value = ii/40;
%     drawnow();
% end

% pause(0.050);
% writeline(udpSender, 'rec', ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.state);

% pause(0.050);

% instructionProgress.Message = 'Recording in progress (instructions upcoming)...';
% drawnow();
% pause(0.1);
% 
% runInstructionSequence(udpSender, SEQUENCE, instructionProgress, ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.params);
% 
% instructionProgress.Message = 'Sequence complete!';
% pause(1.0);
% 
% 
% writeline(udpSender, 'run', ...
%     config.UDP.Socket.StreamService.Address, ...
%     config.UDP.Socket.StreamService.Port.state);
% 
% delete(instructionProgress);
% delete(figInstruct);

% stop(timerObj);
% delete(timerObj);
% delete(spikeClient);
% close all force;
% 
% delete(udpSender);


