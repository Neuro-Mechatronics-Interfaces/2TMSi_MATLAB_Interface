classdef gui__tmsi_client < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        TMSiClientUIFigure      matlab.ui.Figure
        GridLayout              matlab.ui.container.GridLayout
        TMSiStateButtonGroup    matlab.ui.container.ButtonGroup
        QuitButton              matlab.ui.control.ToggleButton
        RecordButton            matlab.ui.control.ToggleButton
        RunButton               matlab.ui.control.ToggleButton
        IdleButton              matlab.ui.control.ToggleButton
        StartDatePickerLabel    matlab.ui.control.Label
        StartDatePicker         matlab.ui.control.DatePicker
        UpdateNameButton        matlab.ui.control.Button
        BlockSpinner            matlab.ui.control.Spinner
        BlockSpinnerLabel       matlab.ui.control.Label
        SubjectEditField        matlab.ui.control.EditField
        SubjectEditFieldLabel   matlab.ui.control.Label
        PortSpinner             matlab.ui.control.Spinner
        PortSpinnerLabel        matlab.ui.control.Label
        Lamp                    matlab.ui.control.Lamp
        ConnectButton           matlab.ui.control.StateButton
        ServerIPEditField       matlab.ui.control.EditField
        ServerIPEditFieldLabel  matlab.ui.control.Label
    end

    properties (Hidden, Access = public)
        client    % TCPclient connected to server
        task_port = udpport("byte", "LocalPort", 3033, "EnablePortSharing", true) % UDPPort listening to task messages (Potentially)
    end

    properties (Constant, Access = public)
        STREAM_HOST_IP = "127.0.0.1";
        UDP_STATE_BROADCAST_PORT = 3030;
        UDP_NAME_BROADCAST_PORT = 3031;
    end
    
    methods (Access = public)
        function task__read_data_cb(app, src, ~)
            %TASK__READ_DATA_CB  Callback when line terminator for udp port is detected.

            data = string(readline(src));
            route = strsplit(data, '.');
            switch lower(route(1))
                case "t" % task state data
                    switch lower(route(2))
                        case "r" % recording state
                            app.TMSiStateButtonGroup.SelectedObject = findobj(app.TMSiStateButtonGroup.Buttons, 'Tag', route(3));
                            if app.TMSiStateButtonGroup.Enable == matlab.lang.OnOffSwitchState('on')
                                client__set_saga_state(app.client, route(3));
                            end
                            if strcmpi(route(3), "run")
                                app.BlockSpinner.Value = app.BlockSpinner.Value + 1;
                                updateRecordingName(app);
                            end
                            fprintf(1,'%s -> TMSi State -> %s\n', string(datetime("now")), str2double(route(3)));
                        case "s"
                            fprintf(1,'%s -> Task State -> %d\n', string(datetime("now")), str2double(route(3)));
                        otherwise
                            fprintf(1,'<strong>Received unhandled task-message</strong>: %s\n', data);
                    end
                case "p" % parameter data
                    switch lower(route(2))
                        case "n" % name data
                            src.write([char(sprintf("%s_%%s_%d", route(3), app.BlockSpinner.Value)) 10], "string", ...
                                app.STREAM_HOST_IP,  ...
                                app.UDP_NAME_BROADCAST_PORT);
                            app.BlockSpinner.Value = app.BlockSpinner.Value + 1;
                            updateRecordingName(app);
                        otherwise
                            fprintf(1,'<strong>Received unhandled parameter-message</strong>: %s\n', data);
                    end

                otherwise
                    fprintf(1,'<strong>Received unhandled message</strong>: %s\n', data);
            end
        end

        function connect(app, IP, PORT)
            try %#ok<TRYNC> 
                delete(app.client);
            end
            try
                app.client = tcpclient(IP, PORT);
            catch
                fprintf(1,'Unable to connect to TCP Server ( %s:%d )\n', IP, PORT);
                app.Lamp.Color = [0.8 0.4 0.1];
                app.ConnectButton.Text = "(Re-)Connect";
                app.ConnectButton.Value = 0;
                return;
            end
            app.Lamp.Color = [0.1 0.8 0.1];
            app.ConnectButton.Text = "Disconnect";
            app.TMSiStateButtonGroup.Enable = 'on';
            app.UpdateNameButton.Enable = 'on';
        end
        
        function disconnect(app)
            try %#ok<TRYNC> 
                delete(app.client);
            end
            app.Lamp.Color = [0.1 0.1 0.8];
            app.ConnectButton.Text = "Connect";
            app.TMSiStateButtonGroup.Enable = 'off';
            app.UpdateNameButton.Enable = 'off';
        end
        
        function updateRecordingName(app)
            t = app.StartDatePicker.Value;
            YYYY = year(t);
            MM = month(t);
            DD = day(t);
            client__set_rec_name_metadata(app.client, app.SubjectEditField.Value, YYYY, MM, DD, app.BlockSpinner.Value);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.StartDatePicker.Value = datetime('today', 'Format', 'uuuu-MM-dd');
            app.task_port.configureTerminator("LF");
            app.task_port.configureCallback("terminator", @app.task__read_data_cb);
        end

        % Close request function: TMSiClientUIFigure
        function TMSiClientUIFigureCloseRequest(app, ~)
            try %#ok<TRYNC> 
                delete(app.client);
            end
            delete(app)
        end

        % Value changed function: ConnectButton
        function ConnectButtonValueChanged(app, ~)
            value = app.ConnectButton.Value;
            if value
                app.connect(app.ServerIPEditField.Value, app.PortSpinner.Value);
            else
                app.disconnect();
            end
        end

        % Selection changed function: TMSiStateButtonGroup
        function TMSiStateButtonGroupSelectionChanged(app, ~)
            selectedButton = app.TMSiStateButtonGroup.SelectedObject;
            client__set_saga_state(app.client, selectedButton.Tag);
        end

        % Button pushed function: UpdateNameButton
        function UpdateNameButtonPushed(app, ~)
            updateRecordingName(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create TMSiClientUIFigure and hide until all components are created
            app.TMSiClientUIFigure = uifigure('Visible', 'off');
            app.TMSiClientUIFigure.Color = [1 1 1];
            app.TMSiClientUIFigure.Position = [100 100 800 350];
            app.TMSiClientUIFigure.Name = 'TMSi Client';
            app.TMSiClientUIFigure.Icon = 'cmu_tartans_logo.jpg';
            app.TMSiClientUIFigure.CloseRequestFcn = createCallbackFcn(app, @TMSiClientUIFigureCloseRequest, true);

            % Create GridLayout
            app.GridLayout = uigridlayout(app.TMSiClientUIFigure);
            app.GridLayout.ColumnWidth = {'2x', '5x', '1x', '2x'};
            app.GridLayout.RowHeight = {'1x', '1x', '1x', '1x', '2x'};
            app.GridLayout.BackgroundColor = [1 1 1];

            % Create ServerIPEditFieldLabel
            app.ServerIPEditFieldLabel = uilabel(app.GridLayout);
            app.ServerIPEditFieldLabel.HorizontalAlignment = 'right';
            app.ServerIPEditFieldLabel.FontName = 'Tahoma';
            app.ServerIPEditFieldLabel.FontSize = 14;
            app.ServerIPEditFieldLabel.FontWeight = 'bold';
            app.ServerIPEditFieldLabel.Layout.Row = 1;
            app.ServerIPEditFieldLabel.Layout.Column = 1;
            app.ServerIPEditFieldLabel.Text = 'Server IP';

            % Create ServerIPEditField
            app.ServerIPEditField = uieditfield(app.GridLayout, 'text');
            app.ServerIPEditField.HorizontalAlignment = 'center';
            app.ServerIPEditField.FontName = 'Tahoma';
            app.ServerIPEditField.FontSize = 18;
            app.ServerIPEditField.Layout.Row = 1;
            app.ServerIPEditField.Layout.Column = 2;
            app.ServerIPEditField.Value = '127.0.0.1';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.GridLayout, 'state');
            app.ConnectButton.ValueChangedFcn = createCallbackFcn(app, @ConnectButtonValueChanged, true);
            app.ConnectButton.Text = 'Connect';
            app.ConnectButton.FontName = 'Tahoma';
            app.ConnectButton.FontSize = 20;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Layout.Row = 1;
            app.ConnectButton.Layout.Column = 4;

            % Create Lamp
            app.Lamp = uilamp(app.GridLayout);
            app.Lamp.Layout.Row = 1;
            app.Lamp.Layout.Column = 3;
            app.Lamp.Color = [0.902 0.902 0.902];

            % Create PortSpinnerLabel
            app.PortSpinnerLabel = uilabel(app.GridLayout);
            app.PortSpinnerLabel.HorizontalAlignment = 'right';
            app.PortSpinnerLabel.FontName = 'Tahoma';
            app.PortSpinnerLabel.FontSize = 14;
            app.PortSpinnerLabel.FontWeight = 'bold';
            app.PortSpinnerLabel.Layout.Row = 2;
            app.PortSpinnerLabel.Layout.Column = 1;
            app.PortSpinnerLabel.Text = 'Port';

            % Create PortSpinner
            app.PortSpinner = uispinner(app.GridLayout);
            app.PortSpinner.Limits = [5000 5050];
            app.PortSpinner.RoundFractionalValues = 'on';
            app.PortSpinner.HorizontalAlignment = 'center';
            app.PortSpinner.FontName = 'Tahoma';
            app.PortSpinner.FontSize = 18;
            app.PortSpinner.Layout.Row = 2;
            app.PortSpinner.Layout.Column = 2;
            app.PortSpinner.Value = 5000;

            % Create SubjectEditFieldLabel
            app.SubjectEditFieldLabel = uilabel(app.GridLayout);
            app.SubjectEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectEditFieldLabel.FontName = 'Tahoma';
            app.SubjectEditFieldLabel.FontWeight = 'bold';
            app.SubjectEditFieldLabel.Layout.Row = 3;
            app.SubjectEditFieldLabel.Layout.Column = 1;
            app.SubjectEditFieldLabel.Text = 'Subject';

            % Create SubjectEditField
            app.SubjectEditField = uieditfield(app.GridLayout, 'text');
            app.SubjectEditField.HorizontalAlignment = 'right';
            app.SubjectEditField.FontName = 'Tahoma';
            app.SubjectEditField.Layout.Row = 3;
            app.SubjectEditField.Layout.Column = 2;
            app.SubjectEditField.Value = 'Default';

            % Create BlockSpinnerLabel
            app.BlockSpinnerLabel = uilabel(app.GridLayout);
            app.BlockSpinnerLabel.HorizontalAlignment = 'right';
            app.BlockSpinnerLabel.FontName = 'Tahoma';
            app.BlockSpinnerLabel.FontWeight = 'bold';
            app.BlockSpinnerLabel.Layout.Row = 3;
            app.BlockSpinnerLabel.Layout.Column = 3;
            app.BlockSpinnerLabel.Text = 'Block';

            % Create BlockSpinner
            app.BlockSpinner = uispinner(app.GridLayout);
            app.BlockSpinner.HorizontalAlignment = 'center';
            app.BlockSpinner.FontName = 'Tahoma';
            app.BlockSpinner.FontSize = 18;
            app.BlockSpinner.Layout.Row = 3;
            app.BlockSpinner.Layout.Column = 4;

            % Create UpdateNameButton
            app.UpdateNameButton = uibutton(app.GridLayout, 'push');
            app.UpdateNameButton.ButtonPushedFcn = createCallbackFcn(app, @UpdateNameButtonPushed, true);
            app.UpdateNameButton.Icon = 'baseline_save_black_24dp.png';
            app.UpdateNameButton.FontName = 'Tahoma';
            app.UpdateNameButton.FontSize = 14;
            app.UpdateNameButton.FontWeight = 'bold';
            app.UpdateNameButton.Enable = 'off';
            app.UpdateNameButton.Layout.Row = 2;
            app.UpdateNameButton.Layout.Column = [3 4];
            app.UpdateNameButton.Text = 'Update Name';

            % Create StartDatePicker
            app.StartDatePicker = uidatepicker(app.GridLayout);
            app.StartDatePicker.DisplayFormat = 'uuuu-MM-dd';
            app.StartDatePicker.FontName = 'Tahoma';
            app.StartDatePicker.FontSize = 18;
            app.StartDatePicker.Layout.Row = 4;
            app.StartDatePicker.Layout.Column = [2 4];

            % Create StartDatePickerLabel
            app.StartDatePickerLabel = uilabel(app.GridLayout);
            app.StartDatePickerLabel.HorizontalAlignment = 'right';
            app.StartDatePickerLabel.FontName = 'Tahoma';
            app.StartDatePickerLabel.FontWeight = 'bold';
            app.StartDatePickerLabel.Layout.Row = 4;
            app.StartDatePickerLabel.Layout.Column = 1;
            app.StartDatePickerLabel.Text = 'Start Date';

            % Create TMSiStateButtonGroup
            app.TMSiStateButtonGroup = uibuttongroup(app.GridLayout);
            app.TMSiStateButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @TMSiStateButtonGroupSelectionChanged, true);
            app.TMSiStateButtonGroup.Enable = 'off';
            app.TMSiStateButtonGroup.TitlePosition = 'centertop';
            app.TMSiStateButtonGroup.Title = 'TMSi State';
            app.TMSiStateButtonGroup.Layout.Row = 5;
            app.TMSiStateButtonGroup.Layout.Column = [1 4];
            app.TMSiStateButtonGroup.FontName = 'Tahoma';

            % Create IdleButton
            app.IdleButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.IdleButton.Icon = 'baseline_stop_black_24dp.png';
            app.IdleButton.Text = 'Idle';
            app.IdleButton.Tag = 'idle';
            app.IdleButton.FontName = 'Tahoma';
            app.IdleButton.Position = [33 14 65 23];
            app.IdleButton.Value = true;

            % Create RunButton
            app.RunButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.RunButton.Icon = 'outline_live_tv_black_24dp.png';
            app.RunButton.Text = 'Run';
            app.RunButton.Tag = 'run';
            app.RunButton.FontName = 'Tahoma';
            app.RunButton.Position = [129 14 206 23];

            % Create RecordButton
            app.RecordButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.RecordButton.Icon = 'baseline_radio_button_checked_black_24dp.png';
            app.RecordButton.Text = 'Record';
            app.RecordButton.FontName = 'Tahoma';
            app.RecordButton.Tag = 'rec';
            app.RecordButton.Position = [360 14 85 23];

            % Create QuitButton
            app.QuitButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.QuitButton.Icon = 'baseline_power_off_black_24dp.png';
            app.QuitButton.Text = 'Quit';
            app.QuitButton.FontName = 'Tahoma';
            app.QuitButton.Tag = 'quit';
            app.QuitButton.Position = [455 14 63 23];

            app.TMSiStateButtonGroup.SelectedObject = app.IdleButton;

            % Show the figure after all components are created
            app.TMSiClientUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = gui__tmsi_client

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.TMSiClientUIFigure)

                % Execute the startup function
                runStartupFcn(app, @startupFcn)
            else

                % Focus the running singleton app
                figure(runningApp.TMSiClientUIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.TMSiClientUIFigure)
        end
    end
end