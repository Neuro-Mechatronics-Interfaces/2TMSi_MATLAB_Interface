function fig = init_emg_eeg_controller_fig(options)
%INIT_EMG_EEG_CONTROLLER_FIG Initializes SAGA State Handler UDP graphical control interface.
%
% Syntax:
%   fig = init_emg_eeg_controller_fig();

arguments
    options.ForceEnable (1,1) logical = false;
end

host_pc = getenv("COMPUTERNAME");
switch host_pc
    case "MAX_LENOVO" % Max Workstation Laptop (Lenovo ThinkPad D16)
        POSITION_PIX = [100 400  900 450];
    case "NMLVR"
        POSITION_PIX = [500 400 900 450];
    otherwise
        POSITION_PIX = [150 150  900 450];
end

fig = uifigure('Color','w',...
    'MenuBar','none','ToolBar','none',...
    'Name','TMSi Recording Controller',...
    'Position',POSITION_PIX,'Icon',"redlogo.jpg");
L = uigridlayout(fig, [9, 6],'BackgroundColor','k');
L.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};
L.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};

config = load_spike_server_config();

fig.UserData = struct;
fig.UserData.UDP = udpport("byte",...
    "LocalHost", "0.0.0.0", ...
    'LocalPort', config.UDP.Socket.RecordingControllerGUI.Port, ...
    'EnablePortSharing', true);

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

fig.UserData.BlockEditField = uieditfield(L, 'numeric', "FontName", "Consolas", "Value", 0, "RoundFractionalValues", true, "ValueChangedFcn", @handleBlockEditFieldChange,'Enable','off');
fig.UserData.BlockEditField.Layout.Row = 1;
fig.UserData.BlockEditField.Layout.Column = 6;

def_name_init = sprintf('%s/%s/%s/%s_%%%%s_%%d.poly5', config.Default.Folder, config.Default.Subject, tank, tank);
def_folder_init = sprintf('%s/%s/%s', config.Default.Folder, config.Default.Subject, tank);
fig.UserData.NameEditField = uieditfield(L, 'text', ...
    "Value", def_name_init, ...
    "ValueChangedFcn", @nameFieldValueChanged, "FontName", 'Consolas','Enable','off');
fig.UserData.NameEditField.Layout.Row = 2;
fig.UserData.NameEditField.Layout.Column = [1 6];
fig.UserData.DefaultModelFolder = def_folder_init;

lab = uilabel(L,"Text", "Offset (μV)", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 1;
fig.UserData.OffsetEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.Offset, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @offsetFieldValueChanged,'RoundFractionalValues','on');
fig.UserData.OffsetEditField.Layout.Row = 4;
fig.UserData.OffsetEditField.Layout.Column = 2;

lab = uilabel(L, ...
    "Text", "Timescale (samples)", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 3;
fig.UserData.SamplesEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.N_Samples, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @samplesFieldValueChanged, 'RoundFractionalValues','on','ValueDisplayFormat','%d');
fig.UserData.SamplesEditField.Layout.Row = 4;
fig.UserData.SamplesEditField.Layout.Column = 4;

lab = uilabel(L,"Text", "REF MODE", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 5;
if config.Default.Enable_Filters
    refVal = config.Default.Virtual_Reference_Mode;
else
    refVal = -1;
end
fig.UserData.RefModeDropDown = uidropdown(L, ...
    "Items", ["No Filtering", ...
              "HPF-Only", ...
              "HPF + CAR", ...
              "HPF + CAR: Textiles", ...
              "HPF + CAR + DEL2", ...
              "HPF + CAR + DEL2: Textiles"], ...
    "ItemsData", -1:4, ...
    "Value", refVal, ...
    "FontName", 'Consolas', ...
    'ValueChangedFcn', @refModeChanged);
fig.UserData.RefModeDropDown.Layout.Row = 4;
fig.UserData.RefModeDropDown.Layout.Column = 6;

runButton = uibutton(L, "Text", "RUN", 'ButtonPushedFcn', @runButtonPushed,...
    'FontName','Tahoma','Enable',matlab.lang.OnOffSwitchState(options.ForceEnable));
runButton.Layout.Row = 3;
runButton.Layout.Column = 1;

recButton = uibutton(L, "Text", "REC", 'ButtonPushedFcn', @recButtonPushed,...
    'FontName','Tahoma', 'Enable',matlab.lang.OnOffSwitchState(options.ForceEnable));
recButton.Layout.Row = 3;
recButton.Layout.Column = 2;

stopButton = uibutton(L, "Text", "STOP", 'ButtonPushedFcn', @stopButtonPushed,...
    'FontName','Tahoma','Enable',matlab.lang.OnOffSwitchState(options.ForceEnable));
stopButton.Layout.Row = 3;
stopButton.Layout.Column = 3;

idleButton = uibutton(L, "Text", "IDLE", 'ButtonPushedFcn', @idleButtonPushed,...
    'FontName','Tahoma','Enable',matlab.lang.OnOffSwitchState(options.ForceEnable));
idleButton.Layout.Row = 3;
idleButton.Layout.Column = 4;

impButton = uibutton(L, "Text", "IMP", 'ButtonPushedFcn', @impButtonPushed,...
    'FontName','Tahoma','Enable',matlab.lang.OnOffSwitchState(options.ForceEnable));
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

% SAGA-A Filters %
lab = uilabel(L,"Text", "A Cutoffs (Hz):", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 3;
fig.UserData.HPFFilterCutoffEditFieldA = uieditfield(L, 'numeric', ...
    "Value", 13, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.HPFFilterCutoffEditFieldA.Layout.Row = 5;
fig.UserData.HPFFilterCutoffEditFieldA.Layout.Column = 4;
fig.UserData.LPFFilterCutoffEditFieldA = uieditfield(L, 'numeric', ...
    "Value", 30, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.LPFFilterCutoffEditFieldA.Layout.Row = 5;
fig.UserData.LPFFilterCutoffEditFieldA.Layout.Column = 5;

fig.UserData.ToggleSquigglesModeButtonA = uibutton(L, "Text", "BPF Mode", ...
    'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma', ...
    'BackgroundColor',[0.7 0.3 0.7],'FontColor','w', 'FontWeight','bold', ...
    'UserData', struct("Mode","BPF","SAGA","A"));
fig.UserData.ToggleSquigglesModeButtonA.Layout.Row = 5;
fig.UserData.ToggleSquigglesModeButtonA.Layout.Column = 6;

% SAGA-B Filters % 
lab = uilabel(L,"Text", "B Cutoffs (Hz):", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 6;
lab.Layout.Column = 3;
fig.UserData.HPFFilterCutoffEditFieldB = uieditfield(L, 'numeric', ...
    "Value", 100, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.HPFFilterCutoffEditFieldB.Layout.Row = 6;
fig.UserData.HPFFilterCutoffEditFieldB.Layout.Column = 4;
fig.UserData.LPFFilterCutoffEditFieldB = uieditfield(L, 'numeric', ...
    "Value", 500, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.LPFFilterCutoffEditFieldB.Layout.Row = 6;
fig.UserData.LPFFilterCutoffEditFieldB.Layout.Column = 5;

fig.UserData.ToggleSquigglesModeButtonB = uibutton(L, "Text", "HPF Mode", ...
    'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma', ...
    'BackgroundColor',[0.7 0.7 0.3],'FontColor','k', 'FontWeight','bold', ...
    'UserData', struct("Mode","HPF","SAGA","B"));
fig.UserData.ToggleSquigglesModeButtonB.Layout.Row = 6;
fig.UserData.ToggleSquigglesModeButtonB.Layout.Column = 6;

fig.DeleteFcn = @handleFigureDeletion;

fig.UserData.UDP.UserData = struct('expect_quit', false, 'running', false, ...
    'subj', fig.UserData.SubjEditField, 'name', fig.UserData.NameEditField, 'block', fig.UserData.BlockEditField, 'atag', fig.UserData.TagAEditField, 'btag', fig.UserData.TagBEditField,  ...
    'idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton, 'quit', quitButton, ...
    'address', fig.UserData.Address, 'parameter_port', fig.UserData.ParameterPort, ...
    'n_hosts', config.Default.N_Host_Devices_Per_Controller,'n_acknowledged', 0);

configureCallback(fig.UserData.UDP, "terminator", @handleUDPmessage);
impButton.UserData = struct('run', runButton, 'idle', idleButton, 'quit', quitButton);
fig.CloseRequestFcn = @handleFigureCloseRequest;
fig.UserData.UDP.writeline("ping", fig.UserData.Address, fig.UserData.StatePort);

    function handleFilterCutoffChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf("n.%d:%d:%d:%d", ...
            src.Parent.Parent.UserData.HPFFilterCutoffEditFieldA.Value, ...
            src.Parent.Parent.UserData.LPFFilterCutoffEditFieldA.Value, ...
            src.Parent.Parent.UserData.HPFFilterCutoffEditFieldB.Value, ...
            src.Parent.Parent.UserData.LPFFilterCutoffEditFieldB.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Filter Update: %s\n', cmd);
    end

    function toggleSquigglesModeButtonPushed(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        if src.UserData.Mode == "BPF"
            src.Text = "HPF Mode"; % Indicate we are now in HPF Mode
            src.BackgroundColor = [0.7 0.7 0.3];
            src.FontColor = 'k';
            src.UserData.Mode = "HPF";
            cmd = sprintf("w.%s.0",src.UserData.SAGA);
            writeline(udpSender,cmd,src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[CONTROLLER]::Sent request to toggle squiggles GUI to BPF mode.\n');
        else
            src.Text = "BPF Mode";
            src.BackgroundColor = [0.7 0.3 0.7];
            src.FontColor = 'w';
            src.UserData.Mode = "BPF";
            cmd = sprintf("w.%s.1",src.UserData.SAGA);
            writeline(udpSender,cmd,src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[CONTROLLER]::Sent request to toggle squiggles GUI to HPF mode.\n');
        end
    end

    function handleFigureCloseRequest(src, ~)
        if src.UserData.UDP.UserData.running
            res = questdlg('Close controller? (State machine is still running)', 'Exit Recording Controller', 'Yes', 'No', 'No');
            if strcmpi(res, 'Yes')
                src.CloseRequestFcn = @closereq;
                delete(src);
            end
        else
            src.CloseRequestFcn = @closereq;
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

    function refModeChanged(src,evt)
        % REMINDER: `evt` has following fields:
        %   -> 'Value' (updated value)  
        %   -> 'PreviousValue' (value before this edit)
        %   -> 'Source' (same as `src`)
        %   -> 'EventName' :: 'ValueChanged'
        if (evt.Value < -1) || (evt.Value > 4)
            warning("Value must be integer between -1 and 4.");
            src.Value = evt.PreviousValue;
            return;
        end
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf("a.%d", src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Virtual_Reference_Mode Change Request %s\n', cmd);
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
                        src.UserData.n_acknowledged = src.UserData.n_acknowledged + 1;
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
                            if src.UserData.n_acknowledged < src.UserData.n_hosts
                                src.UserData.n_acknowledged = src.UserData.n_acknowledged + 1;
                            else
                                msgbox("State machine stopped running.");
                                src.UserData.expect_quit = false;
                                src.UserData.n_acknowledged = 0;
                            end
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
            case 'name'
                switch data.value
                    case 'new'
                        src.UserData.block.Value = src.UserData.block.Value + 1;
                        updateNameCallback(src.UserData.block);
                    otherwise
                        fprintf(1,'Unhandled `name` message value: %s\n', data.value);
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

end