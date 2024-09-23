function fig = init_controller_fig(options)
%INIT_CONTROLLER_FIG Initializes SAGA State Handler UDP graphical control interface.
%
% Syntax:
%   fig = init_controller_fig();

arguments
    options.SerialDevice {mustBeTextScalar} = "";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger} = 115200;
    options.ForceEnable (1,1) logical = false;
end

host_pc = getenv("COMPUTERNAME");
switch host_pc
    case "MAX_LENOVO" % Max Workstation Laptop (Lenovo ThinkPad D16)
        POSITION_PIX = [100 400  900 400];
    case "NMLVR"
        POSITION_PIX = [500 400 900 400];
    otherwise
        POSITION_PIX = [150 150  900 400];
end

fig = uifigure('Color','w',...
    'MenuBar','none','ToolBar','none',...
    'Name','TMSi Recording Controller',...
    'Position',POSITION_PIX,'Icon',"redlogo.jpg");
L = uigridlayout(fig, [8, 6],'BackgroundColor','k');
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

fig.UserData.BlockEditField = uieditfield(L, 'numeric', "FontName", "Consolas", "AllowEmpty", false, "Value", 0, "RoundFractionalValues", true, "ValueChangedFcn", @handleBlockEditFieldChange,'Enable','off');
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

fig.UserData.EnableTriggerControllerCheckBox = uicheckbox(L, ...
    "Text", "Trigger Controller", ...
    "Value", config.Triggers.Enable, ...
    "FontColor", 'w', ...
    "FontName", 'Consolas', ...
    "ValueChangedFcn", @handleTriggerControllerEnableChange);
fig.UserData.EnableTriggerControllerCheckBox.Layout.Row = 5;
fig.UserData.EnableTriggerControllerCheckBox.Layout.Column = 1;
fig.UserData.EmulateMouseCheckBox = uicheckbox(L, ...
    "Text", "Emulate Mouse", ...
    "Value", config.Triggers.Emulate_Mouse, ...
    "FontColor", 'w', ...
    "FontName", 'Consolas', ...
    "ValueChangedFcn", @handleTriggerControllerEnableChange);
fig.UserData.EmulateMouseCheckBox.Layout.Row = 5;
fig.UserData.EmulateMouseCheckBox.Layout.Column = 2;

lab = uilabel(L,"Text", "Mouse Bits", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 3;
if config.Triggers.Left.Enable
    configTrigBit = config.Triggers.Left.Bit;
else
    configTrigBit = -1;
end
fig.UserData.MouseLeftClickTriggerEditField = uieditfield(L, 'numeric', ...
    "Value", configTrigBit, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleMouseClickTriggerBitChange, 'RoundFractionalValues','on');
fig.UserData.MouseLeftClickTriggerEditField.Layout.Row = 5;
fig.UserData.MouseLeftClickTriggerEditField.Layout.Column = 4;

if config.Triggers.Right.Enable
    configTrigBit = config.Triggers.Right.Bit;
else
    configTrigBit = -1;
end
fig.UserData.MouseRightClickTriggerEditField = uieditfield(L, 'numeric', ...
    "Value", configTrigBit, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleMouseClickTriggerBitChange, 'RoundFractionalValues','on');
fig.UserData.MouseRightClickTriggerEditField.Layout.Row = 5;
fig.UserData.MouseRightClickTriggerEditField.Layout.Column = 5;

fig.UserData.ToggleSquigglesButton = uibutton(L, "Text", "Turn Squiggles OFF", 'ButtonPushedFcn', @toggleSquigglesButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.2 0.3 0.7],'UserData',config.GUI.Squiggles.Enable,'FontColor','w');
fig.UserData.ToggleSquigglesButton.Layout.Row = 5;
fig.UserData.ToggleSquigglesButton.Layout.Column = 6;

fig.UserData.TriggerFromBitsCheckBox = uicheckbox(L, ...
    "Text", "Parse From Bits", ...
    "Value", config.Triggers.Parse_From_Bits, ...
    "FontColor", 'w', ...
    "FontName", 'Consolas', ...
    "ValueChangedFcn", @handleTriggerThresholdModeChange);
fig.UserData.TriggerFromBitsCheckBox.Layout.Row = 6;
fig.UserData.TriggerFromBitsCheckBox.Layout.Column = 2;

lab = uilabel(L,"Text", "Trigger Channels", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 6;
lab.Layout.Column = 3;
fig.UserData.LeftTriggerChannelEditField = uieditfield(L, 'numeric', ...
    "Value", config.Triggers.Left.Channel, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleTriggerChannelChange, 'RoundFractionalValues','on', 'UserData', "L");
fig.UserData.LeftTriggerChannelEditField.Layout.Row = 6;
fig.UserData.LeftTriggerChannelEditField.Layout.Column = 4;

fig.UserData.RightTriggerChannelEditField = uieditfield(L, 'numeric', ...
    "Value", config.Triggers.Right.Channel, "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleTriggerChannelChange, 'RoundFractionalValues','on', 'UserData', "R");
fig.UserData.RightTriggerChannelEditField.Layout.Row = 6;
fig.UserData.RightTriggerChannelEditField.Layout.Column = 5;

lab = uilabel(L,"Text", "Debounce Iterations", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 7;
lab.Layout.Column = 1;
fig.UserData.LoopDebounceEditField = uieditfield(L, 'numeric', ...
    "Value", config.Triggers.Debounce_Loop_Iterations, ...
    "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    "RoundFractionalValues","on", ...
    'ValueChangedFcn', @handleTriggerDebounceChange);
fig.UserData.LoopDebounceEditField.Layout.Row = 7;
fig.UserData.LoopDebounceEditField.Layout.Column = 2;

lab = uilabel(L,"Text", "Trigger Thresholds", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 7;
lab.Layout.Column = 3;
fig.UserData.LeftTriggerThresholdEditField = uieditfield(L, 'text', ...
    "Value", sprintf('%d:%d:%d',config.Triggers.Left.SlidingThreshold*100,config.Triggers.Left.FallingThreshold*100, config.Triggers.Left.RisingThreshold*100), ...
    "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleTriggerThresholdModeChange, 'UserData', "L");
fig.UserData.LeftTriggerThresholdEditField.Layout.Row = 7;
fig.UserData.LeftTriggerThresholdEditField.Layout.Column = 4;

fig.UserData.RightTriggerThresholdEditField = uieditfield(L, 'text', ...
    "Value", sprintf('%d:%d:%d', config.Triggers.Right.SlidingThreshold*100,config.Triggers.Right.FallingThreshold*100, config.Triggers.Right.RisingThreshold*100), ...
    "FontName", 'Consolas', 'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleTriggerThresholdModeChange, 'UserData', "R");
fig.UserData.RightTriggerThresholdEditField.Layout.Row = 7;
fig.UserData.RightTriggerThresholdEditField.Layout.Column = 5;

fig.UserData.FilterCutoffLabel = uilabel(L,"Text", "HPF Cutoff (Hz)", 'FontName', 'Consolas', 'FontColor', 'w', ...
        'VerticalAlignment', 'bottom', 'HorizontalAlignment', 'center', 'FontWeight','bold');
    fig.UserData.FilterCutoffLabel.Layout.Row = 6;
    fig.UserData.FilterCutoffLabel.Layout.Column = 6;
fig.UserData.HPFFilterCutoffValue = config.Default.HPF_Cutoff_Frequency;
fig.UserData.LPFFilterCutoffValue = config.Default.LPF_Cutoff_Frequency;
fig.UserData.FilterCutoffEditField = uieditfield(L, 'numeric', ...
    "Value", config.Default.HPF_Cutoff_Frequency, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.FilterCutoffEditField.Layout.Row = 7;
fig.UserData.FilterCutoffEditField.Layout.Column = 6;

if config.GUI.Squiggles.HPF_Mode
    fig.UserData.ToggleSquigglesModeButton = uibutton(L, "Text", "HPF Mode", 'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.7 0.7 0.3],'FontColor','k', 'FontWeight','bold', 'UserData', false);
else
    fig.UserData.ToggleSquigglesModeButton = uibutton(L, "Text", "Envelope Mode", 'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.7 0.3 0.7],'FontColor','w', 'FontWeight','bold', 'UserData', true);
    fig.UserData.FilterCutoffLabel = "LPF Cutoff (Hz)";
    fig.UserData.FilterCutoffEditField.Value = config.Default.LPF_Cutoff_Frequency;
end
fig.UserData.ToggleSquigglesModeButton.Layout.Row = 8;
fig.UserData.ToggleSquigglesModeButton.Layout.Column = 1;

fig.UserData.UploadModelButton = uibutton(L, "Text", "Upload Model", 'ButtonPushedFcn', @uploadModelButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.65 0.65 0.65],'FontColor',[0.25 0.25 0.25], 'FontWeight','bold', 'UserData', false);
fig.UserData.UploadModelButton.Layout.Row = 8;
fig.UserData.UploadModelButton.Layout.Column = 2;

fig.UserData.ModelTextLabel = uilabel(L, "Text", "No Model Sent", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','left');
fig.UserData.ModelTextLabel.Layout.Row = 8;
fig.UserData.ModelTextLabel.Layout.Column = [3 4];

fig.UserData.TrainModelButton = uibutton(L, "Text", "Train New Model", 'ButtonPushedFcn', @trainModelButtonPushed, 'FontName','Tahoma','BackgroundColor',[0.1 0.0 0.4],'FontColor','w', 'FontWeight','bold', 'UserData', false);
fig.UserData.TrainModelButton.Layout.Row = 8;
fig.UserData.TrainModelButton.Layout.Column = 6;

fig.DeleteFcn = @handleFigureDeletion;

if config.Default.Enable_Teensy
    if strlength(options.SerialDevice) < 1
        sList = serialportlist();
        if numel(sList) > 1
            warning("Multiple serial devices detected: ['%s']\n\t->\tSpecify correct device using SerialDevice option.", strjoin(sList,"'; '"));
            teensy = [];
        elseif numel(sList) < 1
            teensy = [];
            warning("No serial devices detected! Sync signal will not be sent on Recording start/stop.");
        else
            teensy = serialport(sList, options.BaudRate);
        end
    else
        teensy = serialport(options.SerialDevice, options.BaudRate);
    end
else
    teensy = [];
end

fig.UserData.UDP.UserData = struct('expect_quit', false, 'running', false, ...
    'subj', fig.UserData.SubjEditField, 'name', fig.UserData.NameEditField, 'block', fig.UserData.BlockEditField, 'atag', fig.UserData.TagAEditField, 'btag', fig.UserData.TagBEditField,  ...
    'idle', idleButton, 'run', runButton, 'rec', recButton, 'stop', stopButton, 'imp', impButton, 'quit', quitButton, ...
    'address', fig.UserData.Address, 'parameter_port', fig.UserData.ParameterPort, ...
    'n_hosts', config.Default.N_Host_Devices_Per_Controller,'n_acknowledged', 0, 'teensy', teensy);

configureCallback(fig.UserData.UDP, "terminator", @handleUDPmessage);
impButton.UserData = struct('run', runButton, 'idle', idleButton, 'quit', quitButton);
fig.CloseRequestFcn = @handleFigureCloseRequest;
fig.UserData.UDP.writeline("ping", fig.UserData.Address, fig.UserData.StatePort);

    function handleTriggerDebounceChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('v.%d', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Loop Debounce Iterations Updated: %s\n', cmd);
    end

    function handleTriggerControllerEnableChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('y.%d:%d', src.Parent.Parent.UserData.EnableTriggerControllerCheckBox.Value, src.Parent.Parent.UserData.EmulateMouseCheckBox.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Controller Trigger Configuration Update: %s\n', cmd);
    end

    function handleTriggerThresholdModeChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('p.%d:%s:%s', src.Parent.Parent.UserData.TriggerFromBitsCheckBox.Value, src.Parent.Parent.UserData.LeftTriggerThresholdEditField.Value, src.Parent.Parent.UserData.RightTriggerThresholdEditField.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Controller Trigger-Mode/Thresholding Update: %s\n', cmd);
    end

    function handleFilterCutoffChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        if src.Parent.Parent.UserData.ToggleSquigglesModeButton.UserData % In envelope mode
            src.Parent.Parent.UserData.LPFFilterCutoffValue = src.Value;
            cmd = sprintf('j.%d',src.Value*1000);
            filtType = 'RMS-Envelope';
        else % In HPF mode
            src.Parent.Parent.UserData.HPFFilterCutoffValue = src.Value;
            cmd = sprintf('h.%d',src.Value);
            filtType = 'HPF';
        end
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent %s Update: %s\n', filtType, cmd);
    end

    function trainModelButtonPushed(src, ~)
        input_folder = uigetdir(src.Parent.Parent.UserData.DefaultModelFolder,  "Select Experiment Folder");
        if input_folder == 0
            return;
        end
        res = inputdlg('Block:', "Input Model Training Block", [1 50], string(num2str(src.Parent.Parent.UserData.BlockEditField.Value-1)));
        if isempty(res)
            return;
        else
            res = str2double(res{1});
        end
        [p,f] = fileparts(input_folder);
        finfo = strsplit(f,'_');

        input_root = strsplit(p, '/');
        input_root = strjoin(input_root(1:(end-1)),'/');
        [out,saga] = load_ab_saga_poly5_and_initialize_covariance( ...
            finfo{1}, str2double(finfo{2}), str2double(finfo{3}), str2double(finfo{4}), res, ...
            'InputRoot', input_root);
        set(src,'BackgroundColor', [0.65 0.65 0.65], 'FontColor', [0.25 0.25 0.25]);
        set(src.Parent.Parent.UserData.UploadModelButton, 'BackgroundColor', [0.1 0.0 0.4], 'FontColor', [1 1 1]);
        src.Parent.Parent.UserData.DefaultModelFolder = input_folder;
        assignin('base', 'out', out);
        assignin('base', 'saga', saga);
    end

    function uploadModelButtonPushed(src, ~)
        def_folder = src.Parent.Parent.UserData.DefaultModelFolder;
        [file, location] = uigetfile('*.mat', "Select Calibration/Model to Upload",def_folder);
        if file == 0
            return;
        end
        udpSender = src.Parent.Parent.UserData.UDP;
        fname = strrep(fullfile(location,file),'\','/');
        cmd = sprintf('k.%s', fname);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        src.Parent.Parent.UserData.ModelTextLabel.Text = sprintf('Current: %s', file);
        src.BackgroundColor = [0.65 0.65 0.65];
        fprintf(1,'[CONTROLLER]::Sent Classifier Model Upload Request: %s\n', cmd);
    end

    function handleMouseClickTriggerBitChange(src, ~)
        if src.Value > 15
            return;
        end
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('c.%d,%d', src.Parent.Parent.UserData.MouseLeftClickTriggerEditField.Value, src.Parent.Parent.UserData.MouseRightClickTriggerEditField.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent Mouse Trigger-Bit Change Request: %s\n', cmd);
    end

    function handleTriggerChannelChange(src, ~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('l.%s:%d', src.UserData, src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[CONTROLLER]::Sent %s Channel-Change Request: %s\n', src.UserData, cmd);
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

    function toggleSquigglesModeButtonPushed(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        if src.UserData
            src.Text = "HPF Mode"; % Indicate we are now in HPF Mode
            src.Parent.Parent.UserData.FilterCutoffLabel.Text = "HPF Cutoff (Hz)";
            src.Parent.Parent.UserData.FilterCutoffEditField.Value = src.Parent.Parent.UserData.HPFFilterCutoffValue;
            src.BackgroundColor = [0.7 0.7 0.3];
            src.FontColor = 'k';
            src.UserData = false;
            writeline(udpSender,"w.0",src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[CONTROLLER]::Sent request to toggle squiggles GUI to ENVELOPE mode.\n');
        else
            src.Text = "Envelope Mode";
            src.Parent.Parent.UserData.FilterCutoffLabel.Text = "LPF Cutoff (Hz)";
            src.Parent.Parent.UserData.FilterCutoffEditField.Value = src.Parent.Parent.UserData.LPFFilterCutoffValue;
            src.BackgroundColor = [0.7 0.3 0.7];
            src.FontColor = 'w';
            src.UserData = true;
            writeline(udpSender,"w.1",src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
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
                        if ~isempty(src.UserData.teensy) && (src.UserData.n_ackowledged == src.UserData.n_hosts)
                            pause(0.25);
                            src.UserData.teensy.write('r','char'); % RECORDING!
                            src.UserData.n_acknowledged = 0;
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
        if ~isempty(udpSender.UserData.teensy)
            udpSender.UserData.teensy.write('s','char'); % "STOP RECORDING"
        end
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
        if ~isempty(udpSender.UserData.teensy)
            udpSender.UserData.teensy.write('s','char'); % "STOP RECORDING"
        end
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
        if ~isempty(udpSender.UserData.teensy)
            udpSender.UserData.teensy.write('s','char'); % "STOP RECORDING"
        end
        udpSender.UserData.expect_quit = true;
        writeline(udpSender, 'quit', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);

    end

end