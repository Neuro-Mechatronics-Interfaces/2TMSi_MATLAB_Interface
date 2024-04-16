function fig = init_controller_fig()
%INIT_CONTROLLER_FIG Initializes SAGA State Handler UDP graphical control interface.  
%
% Syntax: 
%   fig = init_controller_fig();

host_pc = getenv("COMPUTERNAME");
switch host_pc
    case "MAX_LENOVO" % Max Workstation Laptop (Lenovo ThinkPad D16)
        POSITION_PIX = [100 600  900 250];
    case "NMLVR"
        POSITION_PIX = [1500 1200 900 250];
    otherwise
        POSITION_PIX = [150 250  900 250];
end

fig = uifigure('Color','w',...
    'MenuBar','none','ToolBar','none',...
    'Name','TMSi Recording Controller',...
    'Position',POSITION_PIX,'Icon',"redlogo.jpg");
L = uigridlayout(fig, [5, 6],'BackgroundColor','k');
L.RowHeight = {'1x', '1x', '1x', '1x', '1x'};
L.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};

config = load_spike_server_config();

fig.UserData = struct;
fig.UserData.UDP = udpport("byte", 'LocalPort', config.UDP.Socket.RecordingControllerGUI.Port);

fig.UserData.Block = 0;
fig.UserData.Address = config.UDP.Socket.StreamService.Address;
fig.UserData.StatePort = config.UDP.Socket.StreamService.Port.state;
fig.UserData.NamePort = config.UDP.Socket.StreamService.Port.name;
fig.UserData.ParameterPort = config.UDP.Socket.StreamService.Port.params;

dt = datetime('today','TimeZone','America/New_York');
tank = sprintf('%s_%04d_%02d_%02d', config.Default.Subject, year(dt), month(dt), day(dt));
fig.UserData.SubjEditField = uieditfield(L, 'text', "Value", config.Default.Subject, ...
    "ValueChangedFcn", @subjFieldValueChanged, "FontName", 'Consolas','Enable','off');
fig.UserData.SubjEditField.Layout.Row = 1;
fig.UserData.SubjEditField.Layout.Column = 1;

fig.UserData.TagAEditField = uieditfield(L, 'text', "Value", config.SAGA.A.Array.Location, ...
    "ValueChangedFcn", @tagFieldValueChanged, "FontName", 'Consolas','Enable','off','UserData',"A", ...
    'HorizontalAlignment', 'center', 'Placeholder', "A");
fig.UserData.TagAEditField.Layout.Row = 1;
fig.UserData.TagAEditField.Layout.Column = [2 3];

fig.UserData.TagBEditField = uieditfield(L, 'text', "Value", config.SAGA.B.Array.Location, ...
    "ValueChangedFcn", @tagFieldValueChanged, "FontName", 'Consolas','Enable','off','UserData',"B", ...
    'HorizontalAlignment', 'center', 'Placeholder', "B");
fig.UserData.TagBEditField.Layout.Row = 1;
fig.UserData.TagBEditField.Layout.Column = [4 5];

fig.UserData.BlockEditField = uieditfield(L, 'numeric', "FontName", "Consolas", "AllowEmpty", false, "Value", 0, "RoundFractionalValues", true, "ValueChangedFcn", @handleBlockEditFieldChange,'Enable','off');
fig.UserData.BlockEditField.Layout.Row = 1;
fig.UserData.BlockEditField.Layout.Column = 6;

fig.UserData.NameEditField = uieditfield(L, 'text', ...
    "Value", sprintf('%s/%s/%s/%s_%%%%s_%%d.poly5', config.Default.Folder, config.Default.Subject, tank, tank), ...
    "ValueChangedFcn", @nameFieldValueChanged, "FontName", 'Consolas','Enable','off');
fig.UserData.NameEditField.Layout.Row = 2;
fig.UserData.NameEditField.Layout.Column = [1 6];

lab = uilabel(L,"Text", "Offset (μV)", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 1;
fig.UserData.OffsetEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.Offset, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @offsetFieldValueChanged,'RoundFractionalValues','on');
fig.UserData.OffsetEditField.Layout.Row = 4;
fig.UserData.OffsetEditField.Layout.Column = 2;

lab = uilabel(L,"Text", "Timescale (samples)", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 3;
fig.UserData.SamplesEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.N_Samples, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @samplesFieldValueChanged, 'RoundFractionalValues','on');
fig.UserData.SamplesEditField.Layout.Row = 4;
fig.UserData.SamplesEditField.Layout.Column = 4;

lab = uilabel(L,"Text", "Channel", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 5;
fig.UserData.SamplesEditField = uieditfield(L, 'text', ...
    "Value", sprintf('%d:%s:%d', config.GUI.Single.Enable, config.GUI.Single.SAGA, config.GUI.Single.Channel), ...
    "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @channelFieldValueChanged);
fig.UserData.SamplesEditField.Layout.Row = 4;
fig.UserData.SamplesEditField.Layout.Column = 6;

runButton = uibutton(L, "Text", "RUN", 'ButtonPushedFcn', @runButtonPushed,'FontName','Tahoma','Enable','off');
runButton.Layout.Row = 3;
runButton.Layout.Column = 1;

recButton = uibutton(L, "Text", "REC", 'ButtonPushedFcn', @recButtonPushed,'FontName','Tahoma', 'Enable', 'off');
recButton.Layout.Row = 3;
recButton.Layout.Column = 2;

stopButton = uibutton(L, "Text", "STOP", 'ButtonPushedFcn', @stopButtonPushed,'FontName','Tahoma','Enable','off');
stopButton.Layout.Row = 3;
stopButton.Layout.Column = 3;

idleButton = uibutton(L, "Text", "IDLE", 'ButtonPushedFcn', @idleButtonPushed,'FontName','Tahoma','Enable','off');
idleButton.Layout.Row = 3;
idleButton.Layout.Column = 4;

impButton = uibutton(L, "Text", "IMP", 'ButtonPushedFcn', @impButtonPushed,'FontName','Tahoma','Enable','off');
impButton.Layout.Row = 3;
impButton.Layout.Column = 5;
impButton.UserData = struct('rec', recButton, 'stop', stopButton);
idleButton.UserData = struct('rec', recButton, 'stop', stopButton, 'run', runButton, 'imp', impButton);
runButton.UserData = struct('rec', recButton, 'stop', stopButton, 'idle', idleButton, 'imp', impButton);
stopButton.UserData = struct('rec', recButton, 'run', runButton, 'idle', idleButton);
recButton.UserData = struct('stop', stopButton, 'run', runButton, 'idle', idleButton);

quitButton = uibutton(L, "Text", "QUIT", 'ButtonPushedFcn', @quitButtonPushed,'FontName','Tahoma','BackgroundColor','r','FontColor','w');
quitButton.Layout.Row = 3;
quitButton.Layout.Column = 6;
quitButton.UserData = struct('idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton);

fig.UserData.PButton = struct;
fig.UserData.PButton.Calibrate = uibutton(L, "Text", "Re-Calibrate", 'ButtonPushedFcn', @calibrateButtonPushed, 'FontName','Tahoma');
fig.UserData.PButton.Layout.Row = 5;
fig.UserData.PButton.Layout.Column = 1;
lab = uilabel(L,"Text", "Calibration (samples)", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 2;
fig.UserData.CalSamplesEditField = uieditfield(L, 'numeric', ...
    "Value", config.Default.N_Samples_Calibration, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'RoundFractionalValues','on');
fig.UserData.CalSamplesEditField.Layout.Row = 5;
fig.UserData.CalSamplesEditField.Layout.Column = 3;

lab = uilabel(L,"Text", "Triggers YLim", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 4;
fig.UserData.TriggersBoundEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.TriggerBound, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleTriggersBoundFieldChanged, 'RoundFractionalValues','on');
fig.UserData.TriggersBoundEditField.Layout.Row = 5;
fig.UserData.TriggersBoundEditField.Layout.Column = 5;

fig.UserData.ToggleSquigglesButton = uibutton(L, "Text", "Turn Squiggles OFF", 'ButtonPushedFcn', @toggleSquigglesButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.2 0.3 0.7],'UserData',config.GUI.Squiggles.Enable,'FontColor','w');
fig.UserData.ToggleSquigglesButton.Layout.Row = 5;
fig.UserData.ToggleSquigglesButton.Layout.Column = 6;

fig.DeleteFcn = @handleFigureDeletion;
fig.UserData.UDP.UserData = struct('expect_quit', false, 'running', false, ...
    'subj', fig.UserData.SubjEditField, 'name', fig.UserData.NameEditField, 'block', fig.UserData.BlockEditField, 'atag', fig.UserData.TagAEditField, 'btag', fig.UserData.TagBEditField,  ...
    'idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton, 'quit', quitButton, ...
    'address', fig.UserData.Address, 'parameter_port', fig.UserData.ParameterPort);
configureCallback(fig.UserData.UDP, "terminator", @handleUDPmessage);
impButton.UserData = struct('run', runButton, 'idle', idleButton, 'quit', quitButton);
fig.CloseRequestFcn = @handleFigureCloseRequest;
fig.UserData.UDP.writeline("ping", fig.UserData.Address, fig.UserData.StatePort);

end

function handleTriggersBoundFieldChanged(src, ~)
if src.Value <= 0
    return;
end
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf('y.%d', src.Value);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent Triggers Bound Request: %s\n', cmd);
end

function toggleSquigglesButtonPushed(src,~)
udpSender = src.Parent.Parent.UserData.UDP;
if src.UserData
    src.Text = "Turn Squiggles ON";
    writeline(udpSender,"q.0",src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
    fprintf(1,'[CONTROLLER]::Sent request to toggle squiggles OFF: q.0\n');
else
    src.Text = "Turn Squiggles OFF";
    cmd = "q.1:A:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68:B:1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68";
    writeline(udpSender,cmd,src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
    fprintf(1,'[CONTROLLER]::Sent request to toggle squiggles ON: %s\n', cmd);
end
src.UserData = ~src.UserData;
end

function calibrateButtonPushed(src,~)
val = src.Parent.Parent.UserData.CalSamplesEditField.Value;
if val < 100
    src.Parent.Parent.UserData.CalSamplesEditField.BackgroundColor = 'r';
    return;
else
    src.Parent.Parent.UserData.CalSamplesEditField.BackgroundColor = 'w';
end
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf('c.main:%d', val);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent recalibration request: %s\n', cmd);
end

function handleFigureCloseRequest(src, ~)
if src.UserData.UDP.UserData.running
    res = questdlg('Close controller? (State machine is still running)', 'Exit Recording Controller', 'Yes', 'No', 'No');
    if strcmpi(res, 'Yes')
        delete(src);
    end
else
    delete(src);
end
end

function handleBlockEditFieldChange(src, ~)
updateNameCallback(src);
end

function updateNameCallback(src)
udpSender = src.Parent.Parent.UserData.UDP;
fixedValue = string(src.Parent.Parent.UserData.NameEditField.Value);
if ~contains(fixedValue, ".poly5")
    fixedValue = strcat(fixedValue, ".poly5");
end
if ~contains(fixedValue, "%%s")
    fixedValue = strrep(fixedValue, ".poly5", "_%%s.poly5");
end
if ~contains(fixedValue, "%d")
    fixedValue = strrep(fixedValue, ".poly5", "_%d.poly5");
end
s = sprintf(fixedValue, src.Parent.Parent.UserData.BlockEditField.Value);
writeline(udpSender, s, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.NamePort);
fprintf(1,'[CONTROLLER]::Sent name: %s\n', s);
end

function handleFigureDeletion(src,~)
try
    delete(src.UserData.UDP);
catch me
    disp(me.message);
    disp(me.stack(end));
end

end

function offsetFieldValueChanged(src,~)
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf("o.%d", src.Value);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent offset: %s\n', cmd);
end

function samplesFieldValueChanged(src,~)
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf("g.%d", src.Value);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent samples: %s\n', cmd);
end

function channelFieldValueChanged(src,~)
if ~contains(src.Value, ":")
    return;
end
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf("e.%s", src.Value);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent channel: %s\n', cmd);
end

function handleUDPmessage(src, ~)
data = jsondecode(readline(src));
switch data.type
    case 'res'
        switch data.value
            case 'idle'
                src.UserData.idle.Enable = 'off';
                src.UserData.run.Enable = 'on';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'on';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'on';
                src.UserData.subj.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.block.Enable = 'on';
                src.UserData.atag.Enable = 'on';
                src.UserData.btag.Enable = 'on';
                src.UserData.expect_quit = false;
                if ~src.UserData.running
                    updateNameCallback(src.UserData.name);
                    udpSenderRelayNameTags(src);
                end
                src.UserData.running = true;
            case 'imp'
                src.UserData.idle.Enable = 'off';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'off';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'off';
                src.UserData.subj.Enable = 'off';
                src.UserData.name.Enable = 'off';
                src.UserData.block.Enable = 'off';
                src.UserData.atag.Enable = 'off';
                src.UserData.btag.Enable = 'off';
                src.UserData.expect_quit = false;
                if ~src.UserData.running
                    updateNameCallback(src.UserData.name);
                    udpSenderRelayNameTags(src);
                end
                src.UserData.running = true;
            case 'run'
                src.UserData.idle.Enable = 'on';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'on';
                src.UserData.quit.Enable = 'on';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'off';
                src.UserData.subj.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.block.Enable = 'on';
                src.UserData.atag.Enable = 'on';
                src.UserData.btag.Enable = 'on';
                src.UserData.expect_quit = false;
                if ~src.UserData.running
                    updateNameCallback(src.UserData.name);
                    udpSenderRelayNameTags(src);
                end
                src.UserData.running = true;
            case 'rec'
                src.UserData.idle.Enable = 'on';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'on';
                src.UserData.stop.Enable = 'on';
                src.UserData.imp.Enable = 'off';
                src.UserData.subj.Enable = 'off';
                src.UserData.name.Enable = 'off';
                src.UserData.block.Enable = 'off';
                src.UserData.atag.Enable = 'off';
                src.UserData.btag.Enable = 'off';
                src.UserData.expect_quit = false;
                if ~src.UserData.running
                    updateNameCallback(src.UserData.name);
                    udpSenderRelayNameTags(src);
                end
                src.UserData.running = true;
            case 'quit'
                src.UserData.idle.Enable = 'off';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'off';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'off';
                src.UserData.subj.Enable = 'off';
                src.UserData.name.Enable = 'off';
                src.UserData.block.Enable = 'off';
                src.UserData.atag.Enable = 'off';
                src.UserData.btag.Enable = 'off';
                src.UserData.running = false;
                if src.UserData.expect_quit
                    msgbox("State machine stopped running.");
                    src.UserData.expect_quit = false;
                else
                    errordlg("State machine stopped running unexpectedly!");
                end
            otherwise
                disp("Received message:");
                disp(data);
                error("Unhandled state message value: %s\n", data.value);
        end
    case 'status'
        switch data.value
            case 'start'
                src.UserData.idle.Enable = 'on';
                src.UserData.run.Enable = 'on';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'on';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'on';
                src.UserData.subj.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.block.Enable = 'on';
                src.UserData.atag.Enable = 'on';
                src.UserData.btag.Enable = 'on';
                src.UserData.expect_quit = false;
                if ~src.UserData.running
                    updateNameCallback(src.UserData.name);
                    udpSenderRelayNameTags(src);
                end
                src.UserData.running = true;
            case 'resume'
                src.UserData.run.Enable = 'on';
                src.UserData.imp.Enable = 'on';
                src.UserData.quit.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.subj.Enable = 'on';
                src.UserData.block.Enable = 'on';
                src.UserData.atag.Enable = 'on';
                src.UserData.btag.Enable = 'on';
            case 'stop'
                src.UserData.idle.Enable = 'off';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'off';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'off';
                src.UserData.subj.Enable = 'off';
                src.UserData.name.Enable = 'off';
                src.UserData.atag.Enable = 'off';
                src.UserData.btag.Enable = 'off';
                src.UserData.block.Enable = 'off';
                src.UserData.running = false;
                if src.UserData.expect_quit
                    msgbox("State machine stopped running.");
                    src.UserData.expect_quit = false;
                else
                    errordlg("State machine stopped running unexpectedly!");
                end
            otherwise
                disp("Received message:");
                disp(data);
                error("Unhandled status message value: %s\n", data.value);
        end
    otherwise
        disp("Received message:");
        disp(data);
        error("Unhandled message type: %s\n", data.type);
end
end

function udpSenderRelayNameTags(src)
cmd = sprintf('b.A:%s', src.UserData.atag.Value);
writeline(src, cmd, src.UserData.address, src.UserData.parameter_port);
cmd = sprintf('b.B:%s', src.UserData.btag.Value);
writeline(src, cmd, src.UserData.address, src.UserData.parameter_port);
end

function nameFieldValueChanged(src, ~)
updateNameCallback(src);

end

function tagFieldValueChanged(src, ~)
if strlength(src.Value) < 1
    return;
end
udpSender = src.Parent.Parent.UserData.UDP;
cmd = sprintf('b.%s:%s', src.UserData, src.Value);
writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
fprintf(1,'[CONTROLLER]::Sent Parameter Command: %s\n', cmd);
end

function subjFieldValueChanged(src, evt)
s = strrep(src.Parent.Parent.UserData.NameEditField.Value, evt.PreviousValue, evt.Value);
src.Parent.Parent.UserData.NameEditField.Value = s;
updateNameCallback(src);
end

function recButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'rec', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.UserData.stop.Enable = 'on';
src.UserData.idle.Enable = 'off';
src.UserData.run.Enable = 'off';
src.Enable = 'off';
src.Parent.Parent.UserData.SubjEditField.Enable = 'off';
src.Parent.Parent.UserData.BlockEditField.Enable = 'off';
src.Parent.Parent.UserData.NameEditField.Enable = 'off';
src.Parent.Parent.UserData.TagAEditField.Enable = 'off';
src.Parent.Parent.UserData.TagBEditField.Enable = 'off';
end

function stopButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'run', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.UserData.rec.Enable = 'on';
src.Enable = 'off';
src.UserData.run.Enable = 'off';
src.UserData.idle.Enable = 'on';
src.Parent.Parent.UserData.SubjEditField.Enable = 'on';
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
src.Parent.Parent.UserData.TagAEditField.Enable = 'on';
src.Parent.Parent.UserData.TagBEditField.Enable = 'on';
src.Parent.Parent.UserData.BlockEditField.Value = src.Parent.Parent.UserData.BlockEditField.Value + 1;
updateNameCallback(src);
end

function runButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'run', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.UserData.stop.Enable = 'off';
src.UserData.rec.Enable = 'on';
src.UserData.idle.Enable = 'on';
src.UserData.imp.Enable = 'off';
src.Enable = 'off';
src.Parent.Parent.UserData.SubjEditField.Enable = 'on';
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
src.Parent.Parent.UserData.TagAEditField.Enable = 'on';
src.Parent.Parent.UserData.TagBEditField.Enable = 'on';
end

function impButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'imp', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
if udpSender.UserData.running
    src.Enable = 'off';
    src.UserData.run.Enable = 'off';
    src.UserData.idle.Enable = 'off';
    src.UserData.quit.Enable = 'off';
    src.Parent.Parent.UserData.SubjEditField.Enable = 'off';
    src.Parent.Parent.UserData.BlockEditField.Enable = 'off';
    src.Parent.Parent.UserData.NameEditField.Enable = 'off';
    src.Parent.Parent.UserData.TagAEditField.Enable = 'off';
    src.Parent.Parent.UserData.TagBEditField.Enable = 'off';
end
end

function idleButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'idle', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.Enable = 'off';
src.UserData.run.Enable = 'on';
src.UserData.rec.Enable = 'off';
src.UserData.stop.Enable = 'off';
src.UserData.imp.Enable = 'on';
src.Parent.Parent.UserData.SubjEditField.Enable = 'on';
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
src.Parent.Parent.UserData.TagAEditField.Enable = 'on';
src.Parent.Parent.UserData.TagBEditField.Enable = 'on';
end

function quitButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
if udpSender.UserData.running
    res = questdlg('Quit Acquisition State Machine?', 'Quit Acquisition State Machine?', 'Yes', 'No', 'No');
    if strcmpi(res, 'No')
        disp("[CONTROLLER]::State machine still running (no QUIT command sent).");
        return;
    end
end
udpSender.UserData.expect_quit = true;
writeline(udpSender, 'quit', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);

end