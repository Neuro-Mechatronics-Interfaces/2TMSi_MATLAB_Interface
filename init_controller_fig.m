function fig = init_controller_fig()

fig = uifigure('Color','w','MenuBar','none','ToolBar','none','Name','TMSi Recording Controller','Position',[100 720  720 100],'Icon',"TMSi.png");
L = uigridlayout(fig, [2, 6],'BackgroundColor','k');
L.RowHeight = {'1x', 'fit'};
L.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};

config = load_spike_server_config();

fig.UserData = struct;
fig.UserData.UDP = udpport("byte", 'LocalPort', config.UDP.Socket.RecordingControllerGUI.Port);

fig.UserData.Block = 0;
fig.UserData.Address = config.UDP.Socket.StreamService.Address;
fig.UserData.StatePort = config.UDP.Socket.StreamService.Port.state;
fig.UserData.NamePort = config.UDP.Socket.StreamService.Port.name;

dt = datetime('today','TimeZone','America/New_York');
tank = sprintf('%s_%04d_%02d_%02d', config.Default.Subject, year(dt), month(dt), day(dt));
fig.UserData.NameEditField = uieditfield(L, 'text', "Value", sprintf('%s/%s/%s/%s_%%%%s_%%d.poly5', config.Default.Folder, config.Default.Subject, tank, tank), ...
    "ValueChangedFcn", @nameFieldValueChanged, "FontName", 'Consolas');
fig.UserData.NameEditField.Layout.Row = 1;
fig.UserData.NameEditField.Layout.Column = [1 5];

fig.UserData.BlockEditField = uieditfield(L, 'numeric', "FontName", "Consolas", "AllowEmpty", false, "Value", 0, "RoundFractionalValues", true, "ValueChangedFcn", @handleBlockEditFieldChange);
fig.UserData.BlockEditField.Layout.Row = 1;
fig.UserData.BlockEditField.Layout.Column = 6;

runButton = uibutton(L, "Text", "RUN", 'ButtonPushedFcn', @runButtonPushed,'FontName','Tahoma');
runButton.Layout.Row = 2;
runButton.Layout.Column = 1;

recButton = uibutton(L, "Text", "REC", 'ButtonPushedFcn', @recButtonPushed,'FontName','Tahoma', 'Enable', 'off');
recButton.Layout.Row = 2;
recButton.Layout.Column = 2;

stopButton = uibutton(L, "Text", "STOP", 'ButtonPushedFcn', @stopButtonPushed,'FontName','Tahoma','Enable','off');
stopButton.Layout.Row = 2;
stopButton.Layout.Column = 3;

idleButton = uibutton(L, "Text", "IDLE", 'ButtonPushedFcn', @idleButtonPushed,'FontName','Tahoma');
idleButton.Layout.Row = 2;
idleButton.Layout.Column = 4;

impButton = uibutton(L, "Text", "IMP", 'ButtonPushedFcn', @impButtonPushed,'FontName','Tahoma');
impButton.Layout.Row = 2;
impButton.Layout.Column = 5;
impButton.UserData = struct('rec', recButton, 'stop', stopButton);
idleButton.UserData = struct('rec', recButton, 'stop', stopButton, 'run', runButton, 'imp', impButton);
runButton.UserData = struct('rec', recButton, 'stop', stopButton, 'idle', idleButton, 'imp', impButton);
stopButton.UserData = struct('rec', recButton, 'run', runButton, 'idle', idleButton);
recButton.UserData = struct('stop', stopButton, 'run', runButton, 'idle', idleButton);

quitButton = uibutton(L, "Text", "QUIT", 'ButtonPushedFcn', @quitButtonPushed,'FontName','Tahoma','BackgroundColor','r','FontColor','w');
quitButton.Layout.Row = 2;
quitButton.Layout.Column = 6;
quitButton.UserData = struct('idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton);
fig.DeleteFcn = @handleFigureDeletion;
fig.UserData.UDP.UserData = struct('expect_quit', false, 'running', false, 'name', fig.UserData.NameEditField, 'block', fig.UserData.BlockEditField, 'idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton, 'quit', quitButton);
configureCallback(fig.UserData.UDP, "terminator", @handleUDPmessage);
impButton.UserData = struct('run', runButton, 'idle', idleButton, 'quit', quitButton);
fig.CloseRequestFcn = @handleFigureCloseRequest;
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
writeline(udpSender, s, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.NamePort)
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

function handleUDPmessage(src, ~)
data = jsondecode(readline(src));
switch data.type
    case 'status'
        switch data.value
            case 'start'
                src.UserData.idle.Enable = 'on';
                src.UserData.run.Enable = 'on';
                src.UserData.rec.Enable = 'on';
                src.UserData.quit.Enable = 'on';
                src.UserData.stop.Enable = 'on';
                src.UserData.imp.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.block.Enable = 'on';
                src.UserData.expect_quit = false;
                src.UserData.running = true;
            case 'resume'
                src.UserData.run.Enable = 'on';
                src.UserData.imp.Enable = 'on';
                src.UserData.quit.Enable = 'on';
                src.UserData.name.Enable = 'on';
                src.UserData.block.Enable = 'on';
            case 'stop'
                src.UserData.idle.Enable = 'off';
                src.UserData.run.Enable = 'off';
                src.UserData.rec.Enable = 'off';
                src.UserData.quit.Enable = 'off';
                src.UserData.stop.Enable = 'off';
                src.UserData.imp.Enable = 'off';
                src.UserData.name.Enable = 'off';
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

function nameFieldValueChanged(src, ~)
updateNameCallback(src);

end

function recButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'rec', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.UserData.stop.Enable = 'on';
src.UserData.idle.Enable = 'off';
src.UserData.run.Enable = 'off';
src.Enable = 'off';
src.Parent.Parent.UserData.BlockEditField.Enable = 'off';
src.Parent.Parent.UserData.NameEditField.Enable = 'off';
end

function stopButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'run', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.UserData.rec.Enable = 'on';
src.Enable = 'off';
src.UserData.run.Enable = 'off';
src.UserData.idle.Enable = 'on';
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
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
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
end

function impButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'imp', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
if udpSender.UserData.running
    src.Enable = 'off';
    src.UserData.run.Enable = 'off';
    src.UserData.idle.Enable = 'off';
    src.UserData.quit.Enable = 'off';
    src.Parent.Parent.UserData.BlockEditField.Enable = 'off';
    src.Parent.Parent.UserData.NameEditField.Enable = 'off';
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
src.Parent.Parent.UserData.BlockEditField.Enable = 'on';
src.Parent.Parent.UserData.NameEditField.Enable = 'on';
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