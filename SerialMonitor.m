classdef SerialMonitor < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TMSiRippleSerialMonitorUIFigure  matlab.ui.Figure
        Toolbar                     matlab.ui.container.Toolbar
        UploadParametersPushTool    matlab.ui.container.toolbar.PushTool
        NotificationsPanel          matlab.ui.container.Panel
        NotificationsTextArea       matlab.ui.control.TextArea
        ParametersPanel             matlab.ui.container.Panel
        ParametersUITable           matlab.ui.control.Table
        RecordingInformationPanel   matlab.ui.container.Panel
        ParameterKeyEditField       matlab.ui.control.NumericEditField
        ParameterKeyEditFieldLabel  matlab.ui.control.Label
        StimsEditField              matlab.ui.control.NumericEditField
        StimsEditFieldLabel         matlab.ui.control.Label
        StimIndicatorLamp           matlab.ui.control.Lamp
        StartButton                 matlab.ui.control.StateButton
        AnnotationPanel             matlab.ui.container.Panel
        SaveButton                  matlab.ui.control.Button
        NotesTextArea               matlab.ui.control.TextArea
        COMDeviceStatusPanel        matlab.ui.container.Panel
        PCTypeDropDown              matlab.ui.control.DropDown
        PCTypeDropDownLabel         matlab.ui.control.Label
        COMPortDropDown             matlab.ui.control.DropDown
        COMPortDropDownLabel        matlab.ui.control.Label
        ConnectionIndicatorLamp     matlab.ui.control.Lamp
        ConnectionLampLabel         matlab.ui.control.Label
        ConnectButton               matlab.ui.control.Button
    end

    
    properties (Access = public)
        Interface = [] % Microcontroller class object
        Listeners = [] % Event listeners array
    end
    
    properties (Access = protected)
        Flags = struct('TypeSelected', false, 'PortSelected', false, 'SentParameters', false);  % Boolean flags struct
        Parameters = struct('PatternName', "Stim", 'Current', 0, 'NumberTrials', 20, 'PulseWidth', 0, 'PulseRepetitionTime', inf, 'TrainFrequency', 0, 'TrainPulseNumber', 0, 'PulseBiphasic', 0);
        AllParameters = []
    end
    
    properties (Constant, Access=protected)
        DEFAULT_PARAMETERS_FILE = 'R:\NMLShare\raw_data\primate\Frank\Frank_2021_11_18\Frank_2021_11_18_parameters.xlsx'  % Default file to load parameters
    end
    
    events
        ConnectionEvent   % Event indicating that connection to or disconnection from the TMSiSAGA devices has been completed
        AcknowledgeEvent  % Event indicating that some software-side process has been completed (from TMSi side)
    end
    
    methods (Access = public)
        
        % Callback for when "Connect" button is "Disconnect" button.
        function DisconnectButtonPushed(app)
            delete(app.Interface);
            app.Interface = [];
            delete(app.Listeners);
            app.Listeners = [];
            app.ConnectionIndicatorLamp.Color = [0.90,0.90,0.90];
            app.ConnectButton.Text = 'Connect';
            app.ConnectButton.Icon = 'baseline_power_black_24dp.png';
            app.ConnectButton.ButtonPushedFcn = @(~,event)app.ConnectButtonPushed(event);
            app.StartButton.Enable = 'off';
            app.SaveButton.Enable = 'off';
            app.NotesTextArea.Enable = 'off';
            app.ParameterKeyEditField.Enable = 'off';
            app.ParametersUITable.Enable = 'off';
            app.PCTypeDropDown.Enable = 'on';
            app.COMPortDropDown.Enable = 'on';
            eventdata = ConnectionEventData("Disconnect", app.COMPortDropDown.Value);
            notify(app, "ConnectionEvent", eventdata);
        end
        
        % Callback to handle Metadata events from Microcontroller.
        function HandleMetaEvent(app, ~, event)
            app.StimsEditField.Value = event.n_stims;
            app.ParameterKeyEditField.Value = event.key;
        end
        
        % Callback to handle Metadata events from Microcontroller.
        function HandleParameterEvent(app, ~, event)
            if ~app.Flags.SentParameters
                app.UpdateNotifications(event.ts, "New parameters (from interface).");
                for iParam = 1:numel(app.ParametersUITable.ColumnName)
                    param = app.ParametersUITable.ColumnName{iParam};
                    try
                        app.ParametersUITable.Data.(param) = event.p.(param);
                    catch me
                        db.print_error_message(me);
                    end
                end
                app.StimsEditField.Value = event.p.Progress;
                app.ParameterKeyEditField.Value = event.p.Key;
            else
                app.UpdateNotifications(event.ts, "Parameters sent.");
                app.Flags.SentParameters = false; 
            end
        end
        
        % Callback to handle Recording events from Microcontroller.
        function HandleRecordingEvent(app, ~, event)
            switch event.type
                case "Start"
                    app.UpdateNotifications(event.ts, sprintf("Start recording %d.", event.key));
                    app.StartButton.Value = true;
                    app.NotesTextArea.Enable = 'off';
                    app.SaveButton.Enable = 'off';
                    app.StimIndicatorLamp.Color = [0.0 0.0 1.0];
                    app.UpdateDisplayedParameters();
                case "Stop"
                    app.UpdateNotifications(event.ts, sprintf("Stop recording %d.", event.key - 1));
                    app.StartButton.Value = false;
                    app.NotesTextArea.Enable = 'on';
                    app.SaveButton.Enable = 'on';
                    app.StimIndicatorLamp.Color = [0.9 0.9 0.9];
                case "Pause"
                    app.UpdateNotifications(event.ts, "Pause recording.");
                    app.StartButton.Value = false;
                    app.NotesTextArea.Enable = 'on';
                    app.SaveButton.Enable = 'on';
                    app.StimIndicatorLamp.Color = [0.5 0.8 0.0];
                case "Resume"
                    app.UpdateNotifications(event.ts, "Resume recording.");
                    app.StartButton.Value = true;
                    app.NotesTextArea.Enable = 'off';
                    app.SaveButton.Enable = 'off';
                    app.StimIndicatorLamp.Color = [0.0 0.0 1.0];
                case "ReadyForParams"
                    app.UpdateNotifications(event.ts, "Ready for new parameters.");
                    app.StartButton.Enable = 'off';
                    app.StimIndicatorLamp.Color = [0.2 0.2 0.8];
                case "ReadyForStim"
                    app.UpdateNotifications(event.ts, "Ready to begin stimulation.");
                    app.StartButton.Enable = 'on';
                    app.StimIndicatorLamp.Color = [0.2 0.8 0.8];
                otherwise
                    error("I have not added handling for %s RecordingEvent yet.", event.type);
            end
        end
        
        % Callback to handle Stim events from Microcontroller.
        function HandleStimEvent(app, ~, event)
            if app.StartButton.Value
                app.StimIndicatorLamp.Color = [1.0 0.0 0.0];
                app.StimsEditField.Value = event.n_stims;
                app.ParameterKeyEditField.Value = event.key;
                drawnow;
                pause(0.050);
                app.StimIndicatorLamp.Color = [0.0 0.0 1.0];
            end
        end
        
        % Updates the parameters currently displayed in the table.
        function UpdateDisplayedParameters(app)
            if ~isempty(app.AllParameters)
                app.ParametersUITable.Data = app.AllParameters(app.AllParameters.Key == app.ParameterKeyEditField.Value, 1:8);
%                 app.Interface.parameters = struct(...
%                     'Key', app.ParameterKeyEditField.Value, ...
%                     'Progress', app.StimsEditField.Value, ...
%                     'PatternName', app.ParametersUITable.Data.PatternName{1}, ...
%                     'Current', app.ParametersUITable.Data.Current(1), ...
%                     'NumberTrials', app.ParametersUITable.Data.NumberTrials(1), ...
%                     'PulseWidth', app.ParametersUITable.Data.PulseWidth(1), ...
%                     'PulseRepetitionTime', app.ParametersUITable.Data.PulseRepetitionTime(1), ...
%                     'TrainFrequency', app.ParametersUITable.Data.TrainFrequency(1), ...
%                     'TrainPulseNumber', app.ParametersUITable.Data.TrainPulseNumber(1), ...
%                     'PulseBiphasic', app.ParametersUITable.Data.PulseBiphasic(1) ...
%                 );
            end
        end
        
        % Upload parameters from spreadsheet file
        function UploadParameters(app, fname)
            app.AllParameters = readtable(fname);
            app.AllParameters.Key = (0:(size(app.AllParameters, 1)-1))';
            app.UpdateDisplayedParameters();
            if ~isempty(app.Interface)
                app.Interface.updateLocalParams(...
                        app.ParameterKeyEditField.Value, ...
                        app.StimsEditField.Value, ...
                        app.ParametersUITable.Data.PatternName{1}, ...
                        app.ParametersUITable.Data.Current(1), ...
                        app.ParametersUITable.Data.NumberTrials(1), ...
                        app.ParametersUITable.Data.PulseWidth(1), ...
                        app.ParametersUITable.Data.PulseRepetitionTime(1), ...
                        app.ParametersUITable.Data.TrainFrequency(1), ...
                        app.ParametersUITable.Data.TrainPulseNumber(1), ...
                        app.ParametersUITable.Data.PulseBiphasic(1));
                % Have to refresh listeners so they "know" the new Interface
                % object.
                delete(app.Listeners);
                app.Listeners = [ ...
                        addlistener(app.Interface, "RecordingEvent", @app.HandleRecordingEvent); ...
                        addlistener(app.Interface, "MetaEvent", @app.HandleMetaEvent); ...
                        addlistener(app.Interface, "StimEvent", @app.HandleStimEvent); ...
                        addlistener(app.Interface, "ParameterEvent", @app.HandleParameterEvent) ...
                    ]; 
            end
            ts = Microcontroller.convert_to_Mats_ts_format(default.now());
            app.UpdateNotifications(ts, "New parameters uploaded.");
        end
    end
    
    methods (Access = private)
        
        function UpdateNotifications(app, ts, new_notification_text)
            % take current text from box
            temp_text = app.NotificationsTextArea.Value;
            temp_text = temp_text(~cellfun(@(C)isempty(strip(C)), temp_text));

            % add new input text to box and place it on top
            new_temp_text = [...
                {sprintf('[%s] %s', ts, new_notification_text)}; ...
                temp_text];


            % send text back to box
            app.NotificationsTextArea.Value = new_temp_text;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            ports = serialportlist();
            app.COMPortDropDown.ItemsData = ports;
            app.COMPortDropDown.Items = ports;
            for ii = 1:numel(ports)
                s = serialport(ports(ii), 115200, "Timeout", 15);
                s.writeline('init');
                try
                    word = strip(s.readline()); 
                catch
                    fprintf(1, 'No handshake on port: <strong>%s</strong>\n', ports(ii));
                    continue;
                end
                app.COMPortDropDown.Items{ii} = sprintf('%s (%s)', ports(ii), word);
            end
            app.UploadParameters(app.DEFAULT_PARAMETERS_FILE);
            if exist('logs', 'dir') == 0
                mkdir('logs');
            end
        end

        % Button pushed function: ConnectButton
        function ConnectButtonPushed(app, event)
            port = app.COMPortDropDown.Value;
            type = app.PCTypeDropDown.Value;
            lab = sprintf('%s interface', type);
            app.ConnectionIndicatorLamp.Color = [1.00,1.00,0.00];
            try
                app.Interface = Microcontroller(type, port, lab);
                app.Interface.updateLocalParams(...
                        app.ParameterKeyEditField.Value, ...
                        app.StimsEditField.Value, ...
                        app.ParametersUITable.Data.PatternName{1}, ...
                        app.ParametersUITable.Data.Current(1), ...
                        app.ParametersUITable.Data.NumberTrials(1), ...
                        app.ParametersUITable.Data.PulseWidth(1), ...
                        app.ParametersUITable.Data.PulseRepetitionTime(1), ...
                        app.ParametersUITable.Data.TrainFrequency(1), ...
                        app.ParametersUITable.Data.TrainPulseNumber(1), ...
                        app.ParametersUITable.Data.PulseBiphasic(1));
            catch me
                db.print_error_message(me);
                app.ConnectionIndicatorLamp.Color = [1.00,0.00,0.00];
                return;
            end
            app.ConnectionIndicatorLamp.Color = [0.00,1.00,0.00];
            app.ConnectButton.Text = 'Disconnect';
            app.ConnectButton.Icon = 'baseline_power_off_black_24dp.png';
            app.ConnectButton.ButtonPushedFcn = @(~, ~)app.DisconnectButtonPushed();
            app.Listeners = [ ...
                    addlistener(app.Interface, "RecordingEvent", @app.HandleRecordingEvent); ...
                    addlistener(app.Interface, "MetaEvent", @app.HandleMetaEvent); ...
                    addlistener(app.Interface, "StimEvent", @app.HandleStimEvent); ...
                    addlistener(app.Interface, "ParameterEvent", @app.HandleParameterEvent) ...
                ]; 
            app.ParametersUITable.Enable = 'on';
            app.StartButton.Enable = 'on';
            app.SaveButton.Enable = 'on';
            app.NotesTextArea.Enable = 'on';
            app.ParameterKeyEditField.Enable = 'on';
            app.PCTypeDropDown.Enable = 'off';
            app.COMPortDropDown.Enable = 'off';
            eventdata = ConnectionEventData("Connect", port);
            notify(app, "ConnectionEvent", eventdata);
        end

        % Close request function: TMSiRippleSerialMonitorUIFigure
        function TMSiRippleSerialMonitorUIFigureCloseRequest(app, event)
            try
                notify(app, "ConnectionEvent", ConnectionEventData("Disconnect", app.COMPortDropDown.Value));
            catch
                disp('Interface disconnected.');
            end
            try
                delete(app.Interface);
            catch
                disp('Interface deleted.');
            end
            try
                delete(app.Listeners);
            catch
                disp('Listeners deleted.');
            end
            delete(app);
        end

        % Drop down opening function: COMPortDropDown
        function COMPortDropDownOpening(app, event)
            app.Flags.PortSelected = true;
            if app.Flags.TypeSelected
                app.ConnectButton.Enable = 'on';
            end
        end

        % Drop down opening function: PCTypeDropDown
        function PCTypeDropDownOpening(app, event)
            app.Flags.TypeSelected = true;
            if app.Flags.PortSelected
                app.ConnectButton.Enable = 'on';
            end
        end

        % Value changed function: StartButton
        function StartButtonValueChanged(app, event)
            value = app.StartButton.Value;
            if value
                app.StimIndicatorLamp.Color = [0.0 0.0 1.0];
                app.NotesTextArea.Enable = 'off';
                app.SaveButton.Enable = 'off';
            else
                app.StimIndicatorLamp.Color = [0.9 0.9 0.9];
                app.NotesTextArea.Enable = 'on';
                app.SaveButton.Enable = 'on';
            end
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            for ii = 1:numel(app.NotesTextArea.Value)
                word = char(strrep(app.NotesTextArea.Value{ii}, ':', '|'));
                app.Interface.note(word);
                app.UpdateNotifications(Microcontroller.convert_to_Mats_ts_format(default.now()), word);
            end
            app.NotesTextArea.Value = {''};
        end

        % Value changed function: ParameterKeyEditField
        function ParameterKeyEditFieldValueChanged(app, event)
            if ~isempty(app.Interface)
                value = app.ParameterKeyEditField.Value;
                app.Flags.SentParameters = true;
                app.Interface.setParameterKey(value);
            end
        end

        % Clicked callback: UploadParametersPushTool
        function UploadParametersPushToolClicked(app, event)
            [file, path] = uigetfile(...
                '*_parameters.xlsx', ...
                'Select parameters file', ...
                app.DEFAULT_PARAMETERS_FILE);
            if file == 0
                return;
            end
            fname = fullfile(path, file);
            app.UploadParameters(fname);
        end

        % Value changed function: PCTypeDropDown
        function PCTypeDropDownValueChanged(app, event)
            value = app.PCTypeDropDown.Value;
            if strcmpi(value, "Ripple")
                app.ParametersUITable.ColumnEditable = true;
            else
                app.ParametersUITable.ColumnEditable = false;
            end
        end

        % Cell edit callback: ParametersUITable
        function ParametersUITableCellEdit(app, event)
            if ~isempty(app.Interface)
                app.Flags.SentParameters = true;
                app.Interface.sendParams(...
                    app.ParameterKeyEditField.Value, ...
                    app.StimsEditField.Value, ...
                    app.ParametersUITable.Data.PatternName{1}, ...
                    app.ParametersUITable.Data.Current(1), ...
                    app.ParametersUITable.Data.NumberTrials(1), ...
                    app.ParametersUITable.Data.PulseWidth(1), ...
                    app.ParametersUITable.Data.PulseRepetitionTime(1), ...
                    app.ParametersUITable.Data.TrainFrequency(1), ...
                    app.ParametersUITable.Data.TrainPulseNumber(1), ...
                    app.ParametersUITable.Data.PulseBiphasic(1));
            end
        end

        % Value changed function: StimsEditField
        function StimsEditFieldValueChanged(app, event)
            if ~isempty(app.Interface)
                value = app.StimsEditField.Value;
                app.Flags.SentParameters = true;
                app.Interface.setStimCount(value);
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TMSiRippleSerialMonitorUIFigure and hide until all components are created
            app.TMSiRippleSerialMonitorUIFigure = uifigure('Visible', 'off');
            app.TMSiRippleSerialMonitorUIFigure.Position = [100 100 1130 431];
            app.TMSiRippleSerialMonitorUIFigure.Name = 'TMSi-Ripple Serial Monitor';
            app.TMSiRippleSerialMonitorUIFigure.Icon = 'cmu_tartans_logo.jpg';
            app.TMSiRippleSerialMonitorUIFigure.CloseRequestFcn = createCallbackFcn(app, @TMSiRippleSerialMonitorUIFigureCloseRequest, true);

            % Create Toolbar
            app.Toolbar = uitoolbar(app.TMSiRippleSerialMonitorUIFigure);

            % Create UploadParametersPushTool
            app.UploadParametersPushTool = uipushtool(app.Toolbar);
            app.UploadParametersPushTool.Tag = 'Upload.Parameters';
            app.UploadParametersPushTool.Tooltip = {'Set parameters spreadsheet.'};
            app.UploadParametersPushTool.ClickedCallback = createCallbackFcn(app, @UploadParametersPushToolClicked, true);
            app.UploadParametersPushTool.Icon = 'baseline_file_upload_black_24dp.png';

            % Create COMDeviceStatusPanel
            app.COMDeviceStatusPanel = uipanel(app.TMSiRippleSerialMonitorUIFigure);
            app.COMDeviceStatusPanel.Title = 'COM Device Status';
            app.COMDeviceStatusPanel.FontName = 'Tahoma';
            app.COMDeviceStatusPanel.FontWeight = 'bold';
            app.COMDeviceStatusPanel.FontSize = 14;
            app.COMDeviceStatusPanel.Position = [11 238 260 183];

            % Create ConnectButton
            app.ConnectButton = uibutton(app.COMDeviceStatusPanel, 'push');
            app.ConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ConnectButtonPushed, true);
            app.ConnectButton.Icon = 'baseline_power_black_24dp.png';
            app.ConnectButton.Enable = 'off';
            app.ConnectButton.Position = [16 29 130 22];
            app.ConnectButton.Text = 'Connect';

            % Create ConnectionLampLabel
            app.ConnectionLampLabel = uilabel(app.COMDeviceStatusPanel);
            app.ConnectionLampLabel.HorizontalAlignment = 'right';
            app.ConnectionLampLabel.Position = [166 29 66 22];
            app.ConnectionLampLabel.Text = 'Connection';

            % Create ConnectionIndicatorLamp
            app.ConnectionIndicatorLamp = uilamp(app.COMDeviceStatusPanel);
            app.ConnectionIndicatorLamp.Position = [157 35 10 10];
            app.ConnectionIndicatorLamp.Color = [0.902 0.902 0.902];

            % Create COMPortDropDownLabel
            app.COMPortDropDownLabel = uilabel(app.COMDeviceStatusPanel);
            app.COMPortDropDownLabel.HorizontalAlignment = 'right';
            app.COMPortDropDownLabel.Position = [8 129 59 22];
            app.COMPortDropDownLabel.Text = 'COM Port';

            % Create COMPortDropDown
            app.COMPortDropDown = uidropdown(app.COMDeviceStatusPanel);
            app.COMPortDropDown.Items = {'COM1'};
            app.COMPortDropDown.DropDownOpeningFcn = createCallbackFcn(app, @COMPortDropDownOpening, true);
            app.COMPortDropDown.Placeholder = 'Port';
            app.COMPortDropDown.Position = [82 129 169 22];
            app.COMPortDropDown.Value = 'COM1';

            % Create PCTypeDropDownLabel
            app.PCTypeDropDownLabel = uilabel(app.COMDeviceStatusPanel);
            app.PCTypeDropDownLabel.HorizontalAlignment = 'right';
            app.PCTypeDropDownLabel.Position = [16 98 51 22];
            app.PCTypeDropDownLabel.Text = 'PC Type';

            % Create PCTypeDropDown
            app.PCTypeDropDown = uidropdown(app.COMDeviceStatusPanel);
            app.PCTypeDropDown.Items = {'TMSi', 'Ripple'};
            app.PCTypeDropDown.DropDownOpeningFcn = createCallbackFcn(app, @PCTypeDropDownOpening, true);
            app.PCTypeDropDown.ValueChangedFcn = createCallbackFcn(app, @PCTypeDropDownValueChanged, true);
            app.PCTypeDropDown.Placeholder = 'Type';
            app.PCTypeDropDown.Position = [82 98 169 22];
            app.PCTypeDropDown.Value = 'TMSi';

            % Create AnnotationPanel
            app.AnnotationPanel = uipanel(app.TMSiRippleSerialMonitorUIFigure);
            app.AnnotationPanel.Title = 'Annotation';
            app.AnnotationPanel.FontName = 'Tahoma';
            app.AnnotationPanel.FontWeight = 'bold';
            app.AnnotationPanel.FontSize = 14;
            app.AnnotationPanel.Position = [11 26 260 201];

            % Create NotesTextArea
            app.NotesTextArea = uitextarea(app.AnnotationPanel);
            app.NotesTextArea.WordWrap = 'off';
            app.NotesTextArea.FontName = 'Tahoma';
            app.NotesTextArea.Enable = 'off';
            app.NotesTextArea.Tooltip = {'Enter manual notes here.'};
            app.NotesTextArea.Position = [16 40 224 131];

            % Create SaveButton
            app.SaveButton = uibutton(app.AnnotationPanel, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.Enable = 'off';
            app.SaveButton.Position = [16 7 224 22];
            app.SaveButton.Text = 'Save';

            % Create RecordingInformationPanel
            app.RecordingInformationPanel = uipanel(app.TMSiRippleSerialMonitorUIFigure);
            app.RecordingInformationPanel.Title = 'Recording Information';
            app.RecordingInformationPanel.FontName = 'Tahoma';
            app.RecordingInformationPanel.FontWeight = 'bold';
            app.RecordingInformationPanel.FontSize = 14;
            app.RecordingInformationPanel.Position = [282 360 836 61];

            % Create StartButton
            app.StartButton = uibutton(app.RecordingInformationPanel, 'state');
            app.StartButton.ValueChangedFcn = createCallbackFcn(app, @StartButtonValueChanged, true);
            app.StartButton.Enable = 'off';
            app.StartButton.Text = 'Start';
            app.StartButton.Position = [9 7 130 22];

            % Create StimIndicatorLamp
            app.StimIndicatorLamp = uilamp(app.RecordingInformationPanel);
            app.StimIndicatorLamp.Position = [321 7 22 22];
            app.StimIndicatorLamp.Color = [0.902 0.902 0.902];

            % Create StimsEditFieldLabel
            app.StimsEditFieldLabel = uilabel(app.RecordingInformationPanel);
            app.StimsEditFieldLabel.HorizontalAlignment = 'right';
            app.StimsEditFieldLabel.FontName = 'Tahoma';
            app.StimsEditFieldLabel.Position = [354 7 47 22];
            app.StimsEditFieldLabel.Text = '# Stims';

            % Create StimsEditField
            app.StimsEditField = uieditfield(app.RecordingInformationPanel, 'numeric');
            app.StimsEditField.RoundFractionalValues = 'on';
            app.StimsEditField.ValueChangedFcn = createCallbackFcn(app, @StimsEditFieldValueChanged, true);
            app.StimsEditField.FontName = 'Tahoma';
            app.StimsEditField.Position = [417 7 64 22];

            % Create ParameterKeyEditFieldLabel
            app.ParameterKeyEditFieldLabel = uilabel(app.RecordingInformationPanel);
            app.ParameterKeyEditFieldLabel.HorizontalAlignment = 'right';
            app.ParameterKeyEditFieldLabel.FontName = 'Tahoma';
            app.ParameterKeyEditFieldLabel.FontWeight = 'bold';
            app.ParameterKeyEditFieldLabel.Position = [611 7 99 22];
            app.ParameterKeyEditFieldLabel.Text = 'Parameter Key:';

            % Create ParameterKeyEditField
            app.ParameterKeyEditField = uieditfield(app.RecordingInformationPanel, 'numeric');
            app.ParameterKeyEditField.ValueChangedFcn = createCallbackFcn(app, @ParameterKeyEditFieldValueChanged, true);
            app.ParameterKeyEditField.FontName = 'Tahoma';
            app.ParameterKeyEditField.Position = [725 7 100 22];

            % Create ParametersPanel
            app.ParametersPanel = uipanel(app.TMSiRippleSerialMonitorUIFigure);
            app.ParametersPanel.Title = 'Stimulus Parameters';
            app.ParametersPanel.FontName = 'Tahoma';
            app.ParametersPanel.FontWeight = 'bold';
            app.ParametersPanel.FontSize = 14;
            app.ParametersPanel.Position = [282 238 836 111];

            % Create ParametersUITable
            app.ParametersUITable = uitable(app.ParametersPanel);
            app.ParametersUITable.ColumnName = {'PatternName'; 'Current'; 'NumberTrials'; 'PulseWidth'; 'PulseRepetitionTime'; 'TrainFrequency'; 'TrainPulseNumber'; 'PulseBiphasic'};
            app.ParametersUITable.RowName = {};
            app.ParametersUITable.CellEditCallback = createCallbackFcn(app, @ParametersUITableCellEdit, true);
            app.ParametersUITable.Tooltip = {'Stimulation pulse train parameters.'};
            app.ParametersUITable.Enable = 'off';
            app.ParametersUITable.FontName = 'Tahoma';
            app.ParametersUITable.FontSize = 11;
            app.ParametersUITable.Position = [9 6 816 75];

            % Create NotificationsPanel
            app.NotificationsPanel = uipanel(app.TMSiRippleSerialMonitorUIFigure);
            app.NotificationsPanel.Title = 'Notifications';
            app.NotificationsPanel.FontName = 'Tahoma';
            app.NotificationsPanel.FontWeight = 'bold';
            app.NotificationsPanel.FontSize = 14;
            app.NotificationsPanel.Position = [282 26 836 201];

            % Create NotificationsTextArea
            app.NotificationsTextArea = uitextarea(app.NotificationsPanel);
            app.NotificationsTextArea.Editable = 'off';
            app.NotificationsTextArea.FontName = 'Tahoma';
            app.NotificationsTextArea.FontSize = 10;
            app.NotificationsTextArea.Tooltip = {'Notifications from the serial interface.'};
            app.NotificationsTextArea.Position = [9 7 816 164];

            % Show the figure after all components are created
            app.TMSiRippleSerialMonitorUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SerialMonitor

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.TMSiRippleSerialMonitorUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TMSiRippleSerialMonitorUIFigure)
        end
    end
end