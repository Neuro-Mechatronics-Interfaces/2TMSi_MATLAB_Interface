classdef SAGA_Controller < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        TabGroup                        matlab.ui.container.TabGroup
        DeviceControlTab                matlab.ui.container.Tab
        DeviceControlGridLayout         matlab.ui.container.GridLayout
        RawDataFolderEditField          matlab.ui.control.EditField
        RawDataFolderEditFieldLabel     matlab.ui.control.Label
        TMSiStateButtonGroup            matlab.ui.container.ButtonGroup
        ImpedanceButton                 matlab.ui.control.ToggleButton
        QuitButton                      matlab.ui.control.ToggleButton
        RecordButton                    matlab.ui.control.ToggleButton
        RunButton                       matlab.ui.control.ToggleButton
        IdleButton                      matlab.ui.control.ToggleButton
        StartDatePickerLabel            matlab.ui.control.Label
        StartDatePicker                 matlab.ui.control.DatePicker
        UpdateNameButton                matlab.ui.control.Button
        BlockSpinner                    matlab.ui.control.Spinner
        BlockSpinnerLabel               matlab.ui.control.Label
        SubjectEditField                matlab.ui.control.EditField
        SubjectEditFieldLabel           matlab.ui.control.Label
        TMSiControlPortSpinner          matlab.ui.control.Spinner
        TMSiControlPortSpinnerLabel     matlab.ui.control.Label
        Lamp                            matlab.ui.control.Lamp
        ConnectButton                   matlab.ui.control.StateButton
        ServerIPEditField               matlab.ui.control.EditField
        ServerIPEditFieldLabel          matlab.ui.control.Label
        TriggeringTab                   matlab.ui.container.Tab
        TriggeringGridLayout            matlab.ui.container.GridLayout
        SAGABTriggerBitEditField        matlab.ui.control.NumericEditField
        SAGABTriggerBitEditFieldLabel   matlab.ui.control.Label
        SAGAATriggerBitEditField        matlab.ui.control.NumericEditField
        SAGAATriggerBitEditFieldLabel   matlab.ui.control.Label
        ResetTriggersButton             matlab.ui.control.Button
        NTriggersStoredEditField        matlab.ui.control.NumericEditField
        NTriggersStoredEditFieldLabel   matlab.ui.control.Label
        PostTriggerSamplesEditField     matlab.ui.control.NumericEditField
        PostTriggerSamplesEditFieldLabel  matlab.ui.control.Label
        PreTriggerSamplesEditField      matlab.ui.control.NumericEditField
        PreTriggerSamplesEditFieldLabel  matlab.ui.control.Label
        SAGABSTAChannelEditField        matlab.ui.control.NumericEditField
        SAGABSTAChannelEditFieldLabel   matlab.ui.control.Label
        SAGAASTAChannelEditField        matlab.ui.control.NumericEditField
        SAGAASTAChannelEditFieldLabel   matlab.ui.control.Label
        UNISnippetsTab                  matlab.ui.container.Tab
        UNISnippetsGridLayout           matlab.ui.container.GridLayout
        SAGABChannelsEditField          matlab.ui.control.EditField
        SAGABChannelsEditFieldLabel     matlab.ui.control.Label
        SAGAAChannelsEditField          matlab.ui.control.EditField
        SAGAAChannelsEditFieldLabel     matlab.ui.control.Label
        RMSRangeUpperBoundEditField     matlab.ui.control.NumericEditField
        RMSRangeUpperBoundEditFieldLabel  matlab.ui.control.Label
        RMSRangeLowerBoundEditField     matlab.ui.control.NumericEditField
        RMSRangeLowerBoundEditFieldLabel  matlab.ui.control.Label
        DataServerTab                   matlab.ui.container.Tab
        DataServerGridLayout            matlab.ui.container.GridLayout
        DataServerConnectionPushButton  matlab.ui.control.Button
        DataServerPortEditField         matlab.ui.control.NumericEditField
        DataServerPortEditFieldLabel    matlab.ui.control.Label
        DataServerIPEditField           matlab.ui.control.EditField
        DataServerIPEditFieldLabel      matlab.ui.control.Label
        DataServerStatusLamp            matlab.ui.control.Lamp
        DataServerStatusLampLabel       matlab.ui.control.Label
    end

    
    
    properties (Hidden, GetAccess = public, SetAccess = protected)
        Parent
    end

    properties (SetAccess = protected, GetAccess = public)
        connected (1,1) logical = false % Is the client currently connected to the TCP server?
    end

    properties (Access = protected)
        data_server_connection_ 
        controller_                     % udpport client connected to server
        controller_listener_            % eventlistener for the controller_ udp port
        task_                           % UDPPort listening to task messages (Potentially)
        task_host_     (1,1) string = "0.0.0.0"; % LocalHost address for UDP port configured to listen to messages from wrist task.
        task_port_     (1,1) double              % UDP port configured to listen to messages from wrist task.

        controller_host_        (1,1) string = "0.0.0.0"; % IP Address of the TMSi UDP interface
        controller_port_        (1,1) double              % Port for the TMSi UDP interface
        streams_service_host_   (1,1) string              % IP Address hosting the streams
        streams_service_port_   (1,1) double
        config_                 (1,1) struct
        logger_                 (1,1) mlog.Logger = mlog.Logger('SAGA_Controller', fullfile(pwd, 'logs'));
        verbosity_              (1,1) struct = struct('interface', 0, 'task', 0);
    end
    
    methods (Access = public)
        function clean_up_handles(app, ~, ~)
            try %#ok<*TRYNC> 
                delete(app.controller_);
            end
            try
                delete(app.controller_listener_);
            end
            try
                delete(app.task_);
            end
            try
                delete(app.data_server_connection_);
            end
        end
        
        function task__read_data_cb(app, src, evt)
            %TASK__READ_DATA_CB  Callback when line terminator for udp port is detected.
            % TODO: REWORK THIS PART IF RUNNING ON BEHAVIORAL TASK!! %
            data = string(readline(src));
            route = strsplit(data, '.');
            if app.verbosity_.task > 0
                fprintf(1,'[TMSi CLIENT]::[%s] Received Message (client): %s\n', string(evt.AbsoluteTime), data);
            end
            switch lower(route(1))
                case "t" % task state data
                    switch lower(route(2))
                        case "r" % recording state
                            app.TMSiStateButtonGroup.SelectedObject = findobj(app.TMSiStateButtonGroup.Buttons, 'Tag', char(route(3)));
                            if app.TMSiStateButtonGroup.Enable
                                app.TMSiStateButtonGroupSelectionChanged();
                            end
                            if (strcmpi(route(3), "run")) || (strcmpi(route(3), "idle"))
                                app.BlockSpinner.Value = app.BlockSpinner.Value + 1;
                                app.UpdateNameButtonPushed();
                            end
                            if app.verbosity_.task > 0
                                fprintf(1,'[TMSi Client]::[%s]\t%s -> TMSi State -> %s\n', string(evt.AbsoluteTime), string(datetime("now")), route(3));
                            end
                        case "s"
                            if app.verbosity_.task > 0
                                fprintf(1,'[TMSi Client]::[%s]\t%s -> Task State -> %d\n', string(evt.AbsoluteTime), string(datetime("now")), str2double(route(3)));
                            end
                        otherwise
                            if app.verbosity_.task > 0
                                fprintf(1,'[TMSi Client]::[%s]\tReceived unhandled task-message: %s\n', string(evt.AbsoluteTime), data);
                            end
                    end
                case "p" % parameter data
                    switch lower(route(2))
                        case "n" % name data
%                             data = msg.json_task_udp_name_message(route(3), app.BlockSpinner.Value);
%                             message = jsonencode(data);
%                             src.writeline(message, app.streams_host_ip_, app.stream_service_port_);
                            app.BlockSpinner.Value = app.BlockSpinner.Value + 1;
                            app.UpdateNameButtonPushed();
                        otherwise
                            if app.verbosity_.task > 0
                                fprintf(1,'[TMSi Client]::[%s]\tReceived unhandled parameter-message: %s\n', string(evt.AbsoluteTime), data);
                            end
                    end

                otherwise
                    if app.verbosity_.task > 0
                        fprintf(1,'[TMSi Client]::[%s]\tReceived unhandled message: %s\n', string(evt.AbsoluteTime), data);
                    end
            end
        end

        function connect(app, IP, PORT)
            try  
                delete(app.controller_);
            end
            try
                app.controller_ = udpport(...
                    'LocalHost', app.controller_host_, ...
                    'LocalPort', app.controller_port_);
                app.controller_.EnableBroadcast = true;
                app.streams_service_host_ = IP;
                app.streams_service_port_ = PORT;
                if app.verbosity_.interface > 0
                    fprintf(1,'[TMSi Client]\tOpened UDP (multicast) TMSi service-controller-interface ( %s:%d ---> %s:%d )\n', ...
                        app.controller_host_, app.controller_port_, app.streams_service_host_, app.streams_service_port_);
                end
            catch
                if app.verbosity_.interface > 0
                    fprintf(1,'[TMSi Client]\tUnable to create UDP (multicast) TMSi service-controller-interface ( %s:%d ---> %s:%d )\n', ...
                        app.controller_host_, app.controller_port_, IP, PORT);
                end
                app.Lamp.Color = [0.8 0.4 0.1];
                app.ConnectButton.Text = "(Re-)Connect";
                app.ConnectButton.Value = 0;
                return;
            end
            app.controller_.UserData = SubjectMetadata();
            app.controller_listener_ = addlistener(app.controller_.UserData, "MetaEvent", @app.update_meta_fields);
            app.controller_.configureCallback("terminator", @app.handle_serialized_udp_messages_to_controller);
            app.Lamp.Color = [0.1 0.8 0.1];
            app.ConnectButton.Text = "Disconnect";
            app.TMSiStateButtonGroup.Enable = 'on';
            app.UpdateNameButton.Enable = 'on';
            app.connected = true;

            % Now that we have "connected" request the current name from
            % any current "TMSi_Node" if it exists. Otherwise, when it is
            % created, it will send out the name parameters to us, which we
            % can respond to and update the interface.
            data = msg.json_tmsi_udp_controller_message("get", "name");
            message = jsonencode(data);
            app.controller_.writeline(message, app.streams_service_host_, app.streams_service_port_);
            if ~isempty(app.Parent)
                if isvalid(app.Parent)
                    app.Parent.TMSiLamp.Color = [0.0 0.6 0.0];
                end
            end
        end
        
        function disconnect(app)
            try 
                delete(app.controller_);
            end
            try
                delete(app.controller_listener_);
            end
            app.Lamp.Color = [0.1 0.1 0.8];
            app.ConnectButton.Text = "Connect";
            app.TMSiStateButtonGroup.Enable = 'off';
            app.UpdateNameButton.Enable = 'off';
            app.connected = false;
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tClosed UDP TMSi service-controller-interface ( %s:%d -x-> %s:%d )\n', ...
                    app.controller_host_, app.controller_port_, ...
                    app.streams_service_host_, app.streams_service_port_);
            end
            if ~isempty(app.Parent)
                if isvalid(app.Parent)
                    app.Parent.TMSiLamp.Color = [0.1 0.1 0.8];
                end
            end
        end

        function update_meta_fields(app, src, ~)
            %UPDATE_META_FIELDS  Any time a "MetaEvent" happens, this listener callback is fired.
            app.SubjectEditField.Value = src.SUBJ;
            app.StartDatePicker.Value = src.Date;
            app.BlockSpinner.Value = src.BLOCK;
        end
        
        function update_metadata(app, SUBJ, YYYY, MM, DD, BLOCK)
            %UPDATE_METADATA Update the metadata fields and execute updating callback as well.
            app.SubjectEditField.Value = SUBJ;
            app.StartDatePicker.Value = datetime(YYYY, MM, DD);
            app.BlockSpinner.Value = BLOCK;
            if app.UpdateNameButton.Enable
                callback.handleTMSiRecNameMetadata(app.controller_, SUBJ, YYYY, MM, DD, BLOCK);
            end
        end

        function handle_serialized_tcp_messages_from_data_server(app, src, evt)
            %HANDLE_SERIALIZED_TCP_MESSAGES_FROM_DATA_SERVER  Callback for the TCP server connection to Data Server client.
            message = src.readline();
            data = jsondecode(message);
            app.logger_.info(sprintf("TCP :: INTERFACE :: %s :: %s", string(evt.AbsoluteTime), message));
            switch lower(char(data.type))
                case 'stim.pattern'
                    state = string(app.TMSiStateButtonGroup.SelectedObject.Tag);
                    block = app.BlockSpinner.Value;
                    response = msg.json_tmsi_state_message(state, block);
                    response_message = jsonencode(response);
                    src.writeline(response_message);
                    % TODO: Handle any additional parsing?
            end
        end

        function handle_data_server_connection_change(app, src, evt)
            %HANDLE_DATA_SERVER_CONNECTION_CHANGE  Callback for when data server connections change.
            if src.Connected
                app.logger_.info(sprintf("TCP :: INTERFACE :: %s :: Connected", string(evt.AbsoluteTime)));
                app.DataServerStatusLamp.Color = [0.1 0.9 0.1];
            else
                app.logger_.info(sprintf("TCP :: INTERFACE :: %s :: Disconnected", string(evt.AbsoluteTime)));
                app.DataServerStatusLamp.Color = [0.1 0.1 0.9];
            end
        end

        function handle_serialized_udp_messages_to_controller(app, src, evt)
            %HANDLE_SERIALIZED_UDP_MESSAGES_TO_CONTROLLER  Callback for the UDP "client" object.
            
            message = src.readline();
            data = jsondecode(message);
            app.logger_.info(sprintf("UDP :: INTERFACE :: %s :: %s", string(evt.AbsoluteTime), message));
            switch lower(char(data.type))
                case 'name.task'
                    src.UserData.BLOCK = data.block;
                    src.UserData.tank_2_meta_and_event(data.tank);
                case 'name.tmsi'
                    app.SubjectEditField.Value = data.subject;
                    app.StartDatePicker.Value = datetime(data.year, data.month, data.day, 'Format', 'uuuu-MM-dd');
                    app.BlockSpinner.Value = data.block;
                    if app.verbosity_.interface > 0
                        fprintf(1,'[TMSi Client]::[%s]\tReceived `name.tmsi` message and updated UI fields.\n', string(evt.AbsoluteTime));
                    end
                otherwise
                    error("[TMSi Client]::[%s]\tUnexpected message `type`: %s (message: [%s])\n", string(evt.AbsoluteTime), lower(char(data.type)), message);
            end
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, config)
            if nargin < 2
                config_file = parameters('config');
                config = parse_main_config(config_file);
            end
            app.config_ = config;
            app.verbosity_.interface = config.Verbosity.tmsi.interface;
            app.verbosity_.task = config.Verbosity.task;
            app.StartDatePicker.Value = datetime('today', 'Format', 'uuuu-MM-dd');
            app.RawDataFolderEditField.Value = strrep(config.Default.Folder, '\', '/');
            
            app.SAGAASTAChannelEditField.UserData = struct(...
                'host', config.Host.visualizer.A, ...
                'port', config.UDP.tmsi.visualizer.A);
            app.SAGABSTAChannelEditField.UserData = struct(...
                'host', config.Host.visualizer.B, ...
                'port', config.UDP.tmsi.visualizer.B);
            app.SAGAATriggerBitEditField.UserData = struct(...
                'host', config.Host.visualizer.A, ...
                'port', config.UDP.tmsi.visualizer.A);
            app.SAGABTriggerBitEditField.UserData = struct(...
                'host', config.Host.visualizer.B, ...
                'port', config.UDP.tmsi.visualizer.B);

            app.task_port_ = config.UDP.task.interface;
            app.controller_port_ = config.UDP.tmsi.controller.interface;

            app.task_ = udpport(...
                "LocalHost", app.task_host_, ...
                "LocalPort", app.task_port_);
            app.task_.configureTerminator("LF");
            app.task_.configureCallback("terminator", @app.task__read_data_cb);

            app.streams_service_host_ = config.Host.multicast;
            app.ServerIPEditField.Value = config.Host.multicast;
            app.streams_service_port_ = config.UDP.tmsi.controller.service;
        end

        % Close request function: UIFigure
        function UIFigureCloseRequest(app, event)
            try 
                app.clean_up_handles();
            end
            delete(app)
        end

        % Value changed function: ConnectButton
        function ConnectButtonValueChanged(app, event)
            value = app.ConnectButton.Value;
            if value
                app.connect(app.ServerIPEditField.Value, app.TMSiControlPortSpinner.Value);
            else
                app.disconnect();
            end
        end

        % Button pushed function: UpdateNameButton
        function UpdateNameButtonPushed(app, event)
            t = app.StartDatePicker.Value;
            SUBJ = app.SubjectEditField.Value;
            BLOCK = app.BlockSpinner.Value;
            YYYY = year(t);
            MM = month(t);
            DD = day(t);
            data = msg.json_tmsi_udp_controller_message("folder", app.RawDataFolderEditField.Value);
            message = jsonencode(data);
            app.controller_.writeline(message, app.streams_service_host_, app.streams_service_port_);
            val = msg.json_tmsi_udp_name_message(SUBJ, YYYY, MM, DD, "%s", BLOCK);
            data = msg.json_tmsi_udp_controller_message("name", val);
            message = jsonencode(data);
            app.controller_.writeline(message, app.streams_service_host_, app.streams_service_port_);
            
        end

        % Selection changed function: TMSiStateButtonGroup
        function TMSiStateButtonGroupSelectionChanged(app, event)
            selectedButton = app.TMSiStateButtonGroup.SelectedObject;
            switch selectedButton.Tag
                case "rec"
                    app.Lamp.Color = [0.2 1.0 0.2];
                    state = enum.TMSiState.REC;
                case "idle"
                    app.Lamp.Color = [0.0 0.6 0.0];
                    state = enum.TMSiState.IDLE;
                case "run"
                    app.Lamp.Color = [0.3 0.8 0.3];
                    state = enum.TMSiState.RUN;
                case "imp"
                    app.Lamp.Color = [0.2 0.8 0.8];
                    state = enum.TMSiState.IMP;
                case "quit"
                    app.Lamp.Color = [0.8 0.5 0.1];
                    state = enum.TMSiState.QUIT;
            end
            data = msg.json_tmsi_udp_controller_message('state', state);
            message = jsonencode(data);
            app.controller_.writeline(message, ...
                app.streams_service_host_, app.streams_service_port_);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command [%s] ( %s:%d ---> %s:%d )\n', ...
                        message, app.controller_host_, app.controller_port_, ...
                        app.streams_service_host_, app.streams_service_port_);
            end
            if ~isempty(app.Parent)
                if isvalid(app.Parent)
                    app.Parent.TMSiLamp.Color = app.Lamp.Color;
                end
            end
        end

        % Value changed function: SAGAASTAChannelEditField, 
        % ...and 1 other component
        function HandleSendingNewTriggerChannelMessage(app, event)
            channel = event.Source.Value;
            n_max = app.NTriggersStoredEditField.Value;
            n_pre = app.PreTriggerSamplesEditField.Value;
            n_post = app.PostTriggerSamplesEditField.Value;
            if strcmpi(event.Source.Tag, 'A')
                trigger_bit = app.SAGAATriggerBitEditField.Value;
            else
                trigger_bit = app.SAGABTriggerBitEditField.Value;
            end
            data = msg.json_sta_udp_config_message(false, n_max,n_pre,n_post,channel,trigger_bit);
            message = jsonencode(data);
            app.controller_.writeline(message, ...
                event.Source.UserData.host, ...
                event.Source.UserData.port);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command to STA visualizer at %s:%d\n', ...
                    event.Source.UserData.host, event.Source.UserData.port);
            end
        end

        % Callback function: NTriggersStoredEditField, 
        % ...and 3 other components
        function HandleSendingConfigMessageToAll(app, event)
            n_max = app.NTriggersStoredEditField.Value;
            n_pre = app.PreTriggerSamplesEditField.Value;
            n_post = app.PostTriggerSamplesEditField.Value;
            
            channel = app.SAGAASTAChannelEditField.Value;
            trigger_bit = app.SAGAATriggerBitEditField.Value;
            data = msg.json_sta_udp_config_message(true, n_max,n_pre,n_post,channel,trigger_bit);
            message = jsonencode(data);
            app.controller_.writeline(message, ...
                app.SAGAASTAChannelEditField.UserData.host, ...
                app.SAGAASTAChannelEditField.UserData.port);

            channel = app.SAGABSTAChannelEditField.Value;
            trigger_bit = app.SAGABTriggerBitEditField.Value;
            data = msg.json_sta_udp_config_message(true, n_max,n_pre,n_post,channel,trigger_bit);
            message = jsonencode(data);
            app.controller_.writeline(message, ...
                app.SAGABSTAChannelEditField.UserData.host, ...
                app.SAGABSTAChannelEditField.UserData.port);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command to both STA visualizers.\n');
            end
        end

        % Value changed function: SAGAATriggerBitEditField
        function HandleSendingNewBitMessage(app, event)
            trigger_bit = event.Source.Value;
            n_max = app.NTriggersStoredEditField.Value;
            n_pre = app.PreTriggerSamplesEditField.Value;
            n_post = app.PostTriggerSamplesEditField.Value;
            if strcmpi(event.Source.Tag, 'A')
                channel = app.SAGAASTAChannelEditField.Value;
            else
                channel = app.SAGABSTAChannelEditField.Value;
            end
            data = msg.json_sta_udp_config_message(false, n_max,n_pre,n_post,channel,trigger_bit);
            message = jsonencode(data);
            app.controller_.writeline(message, ...
                event.Source.UserData.host, ...
                event.Source.UserData.port);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command to STA visualizer at %s:%d\n', ...
                    event.Source.UserData.host, event.Source.UserData.port);
            end
        end

        % Value changed function: RMSRangeLowerBoundEditField, 
        % ...and 3 other components
        function RMSRangeBoundEditFieldValueChanged(app, event)
            rms_range = [ app.RMSRangeLowerBoundEditField.Value, app.RMSRangeUpperBoundEditField.Value];
            data_A = msg.json_snippets_udp_config_message(app.SAGAAChannelsEditField.Value, rms_range, app.SAGAATriggerBitEditField.Value);
            data_B = msg.json_snippets_udp_config_message(app.SAGABChannelsEditField.Value, rms_range, app.SAGABTriggerBitEditField.Value);
            
            message = jsonencode(data_A);
            app.controller_.writeline(message, ...
                app.SAGAASTAChannelEditField.UserData.host, ...
                app.SAGAASTAChannelEditField.UserData.port);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command to snippets visualizer at %s:%d\n', ...
                    app.SAGAASTAChannelEditField.UserData.host, app.SAGAASTAChannelEditField.UserData.port);
            end

            message = jsonencode(data_B);
            app.controller_.writeline(message, ...
                app.SAGABSTAChannelEditField.UserData.host, ...
                app.SAGABSTAChannelEditField.UserData.port);
            if app.verbosity_.interface > 0
                fprintf(1,'[TMSi Client]\tWrote UDP command to snippets visualizer at %s:%d\n', ...
                    app.SAGABSTAChannelEditField.UserData.host, app.SAGABSTAChannelEditField.UserData.port);
            end
        end

        % Button pushed function: DataServerConnectionPushButton
        function DataServerConnectionPushButtonPushed(app, event)
            if strcmpi(event.Source.Text, "Open Connection")
                try
                    app.data_server_connection_ = tcpserver(...
                        app.DataServerIPEditField.Value, ...
                        app.DataServerPortEditField.Value, ...
                        'Timeout', 30, ...
                        'ConnectionChangedFcn', @app.handle_data_server_connection_change);
                    app.data_server_connection_.configureCallback(...
                        "terminator", @app.handle_serialized_tcp_messages_from_data_server);
                    set(event.Source, ...
                        'Text', "Close Connection", ...
                        'Icon', 'baseline_link_off_black_24dp.png');
                    app.DataServerStatusLamp.Color = [0.1 0.1 0.9];
                catch me
                    disp(me);
                    return;
                end
            else
                try
                    delete(app.data_server_connection_);
                    set(event.Source, ...
                        'Text', "Open Connection", ...
                        'Icon', 'baseline_link_black_24dp.png');
                    app.DataServerStatusLamp.Color = [0.9 0.9 0.9];
                catch me
                    disp(me);
                    return;
                end
                
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Color = [1 1 1];
            app.UIFigure.Position = [240 320 809 437];
            app.UIFigure.Name = 'TMSi 2SAGA Client';
            app.UIFigure.Icon = 'cmu_tartans_logo.jpg';
            app.UIFigure.CloseRequestFcn = createCallbackFcn(app, @UIFigureCloseRequest, true);

            % Create TabGroup
            app.TabGroup = uitabgroup(app.UIFigure);
            app.TabGroup.Position = [1 1 809 437];

            % Create DeviceControlTab
            app.DeviceControlTab = uitab(app.TabGroup);
            app.DeviceControlTab.Title = 'Device Control';

            % Create DeviceControlGridLayout
            app.DeviceControlGridLayout = uigridlayout(app.DeviceControlTab);
            app.DeviceControlGridLayout.ColumnWidth = {'2x', '5x', '1x', '2x'};
            app.DeviceControlGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '2x'};
            app.DeviceControlGridLayout.BackgroundColor = [1 1 1];

            % Create ServerIPEditFieldLabel
            app.ServerIPEditFieldLabel = uilabel(app.DeviceControlGridLayout);
            app.ServerIPEditFieldLabel.HorizontalAlignment = 'right';
            app.ServerIPEditFieldLabel.FontName = 'Tahoma';
            app.ServerIPEditFieldLabel.FontSize = 17;
            app.ServerIPEditFieldLabel.FontWeight = 'bold';
            app.ServerIPEditFieldLabel.Layout.Row = 2;
            app.ServerIPEditFieldLabel.Layout.Column = 1;
            app.ServerIPEditFieldLabel.Text = 'Server IP';

            % Create ServerIPEditField
            app.ServerIPEditField = uieditfield(app.DeviceControlGridLayout, 'text');
            app.ServerIPEditField.HorizontalAlignment = 'center';
            app.ServerIPEditField.FontName = 'Tahoma';
            app.ServerIPEditField.FontSize = 20;
            app.ServerIPEditField.Layout.Row = 2;
            app.ServerIPEditField.Layout.Column = 2;
            app.ServerIPEditField.Value = '226.0.0.1';

            % Create ConnectButton
            app.ConnectButton = uibutton(app.DeviceControlGridLayout, 'state');
            app.ConnectButton.ValueChangedFcn = createCallbackFcn(app, @ConnectButtonValueChanged, true);
            app.ConnectButton.Text = 'Connect';
            app.ConnectButton.FontName = 'Tahoma';
            app.ConnectButton.FontSize = 20;
            app.ConnectButton.FontWeight = 'bold';
            app.ConnectButton.Layout.Row = 3;
            app.ConnectButton.Layout.Column = 4;

            % Create Lamp
            app.Lamp = uilamp(app.DeviceControlGridLayout);
            app.Lamp.Layout.Row = 3;
            app.Lamp.Layout.Column = 3;
            app.Lamp.Color = [0.902 0.902 0.902];

            % Create TMSiControlPortSpinnerLabel
            app.TMSiControlPortSpinnerLabel = uilabel(app.DeviceControlGridLayout);
            app.TMSiControlPortSpinnerLabel.HorizontalAlignment = 'right';
            app.TMSiControlPortSpinnerLabel.FontName = 'Tahoma';
            app.TMSiControlPortSpinnerLabel.FontSize = 17;
            app.TMSiControlPortSpinnerLabel.FontWeight = 'bold';
            app.TMSiControlPortSpinnerLabel.Layout.Row = 3;
            app.TMSiControlPortSpinnerLabel.Layout.Column = 1;
            app.TMSiControlPortSpinnerLabel.Text = 'TMSi Control Port';

            % Create TMSiControlPortSpinner
            app.TMSiControlPortSpinner = uispinner(app.DeviceControlGridLayout);
            app.TMSiControlPortSpinner.Limits = [0 Inf];
            app.TMSiControlPortSpinner.RoundFractionalValues = 'on';
            app.TMSiControlPortSpinner.ValueDisplayFormat = '%11d';
            app.TMSiControlPortSpinner.HorizontalAlignment = 'center';
            app.TMSiControlPortSpinner.FontName = 'Tahoma';
            app.TMSiControlPortSpinner.FontSize = 20;
            app.TMSiControlPortSpinner.Layout.Row = 3;
            app.TMSiControlPortSpinner.Layout.Column = 2;
            app.TMSiControlPortSpinner.Value = 3030;

            % Create SubjectEditFieldLabel
            app.SubjectEditFieldLabel = uilabel(app.DeviceControlGridLayout);
            app.SubjectEditFieldLabel.HorizontalAlignment = 'right';
            app.SubjectEditFieldLabel.FontName = 'Tahoma';
            app.SubjectEditFieldLabel.FontSize = 18;
            app.SubjectEditFieldLabel.FontWeight = 'bold';
            app.SubjectEditFieldLabel.Layout.Row = 4;
            app.SubjectEditFieldLabel.Layout.Column = 1;
            app.SubjectEditFieldLabel.Text = 'Subject';

            % Create SubjectEditField
            app.SubjectEditField = uieditfield(app.DeviceControlGridLayout, 'text');
            app.SubjectEditField.HorizontalAlignment = 'right';
            app.SubjectEditField.FontName = 'Tahoma';
            app.SubjectEditField.FontSize = 20;
            app.SubjectEditField.Layout.Row = 4;
            app.SubjectEditField.Layout.Column = 2;
            app.SubjectEditField.Value = 'Default';

            % Create BlockSpinnerLabel
            app.BlockSpinnerLabel = uilabel(app.DeviceControlGridLayout);
            app.BlockSpinnerLabel.HorizontalAlignment = 'right';
            app.BlockSpinnerLabel.FontName = 'Tahoma';
            app.BlockSpinnerLabel.FontSize = 18;
            app.BlockSpinnerLabel.FontWeight = 'bold';
            app.BlockSpinnerLabel.Layout.Row = 4;
            app.BlockSpinnerLabel.Layout.Column = 3;
            app.BlockSpinnerLabel.Text = 'Block';

            % Create BlockSpinner
            app.BlockSpinner = uispinner(app.DeviceControlGridLayout);
            app.BlockSpinner.HorizontalAlignment = 'center';
            app.BlockSpinner.FontName = 'Tahoma';
            app.BlockSpinner.FontSize = 18;
            app.BlockSpinner.Layout.Row = 4;
            app.BlockSpinner.Layout.Column = 4;

            % Create UpdateNameButton
            app.UpdateNameButton = uibutton(app.DeviceControlGridLayout, 'push');
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
            app.StartDatePicker = uidatepicker(app.DeviceControlGridLayout);
            app.StartDatePicker.DisplayFormat = 'uuuu-MM-dd';
            app.StartDatePicker.FontName = 'Tahoma';
            app.StartDatePicker.FontSize = 18;
            app.StartDatePicker.Layout.Row = 5;
            app.StartDatePicker.Layout.Column = [2 4];

            % Create StartDatePickerLabel
            app.StartDatePickerLabel = uilabel(app.DeviceControlGridLayout);
            app.StartDatePickerLabel.HorizontalAlignment = 'right';
            app.StartDatePickerLabel.FontName = 'Tahoma';
            app.StartDatePickerLabel.FontSize = 18;
            app.StartDatePickerLabel.FontWeight = 'bold';
            app.StartDatePickerLabel.Layout.Row = 5;
            app.StartDatePickerLabel.Layout.Column = 1;
            app.StartDatePickerLabel.Text = 'Start Date';

            % Create TMSiStateButtonGroup
            app.TMSiStateButtonGroup = uibuttongroup(app.DeviceControlGridLayout);
            app.TMSiStateButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @TMSiStateButtonGroupSelectionChanged, true);
            app.TMSiStateButtonGroup.Enable = 'off';
            app.TMSiStateButtonGroup.TitlePosition = 'centertop';
            app.TMSiStateButtonGroup.Title = 'TMSi State';
            app.TMSiStateButtonGroup.BackgroundColor = [0.8 0.8 0.8];
            app.TMSiStateButtonGroup.Layout.Row = 6;
            app.TMSiStateButtonGroup.Layout.Column = [1 4];
            app.TMSiStateButtonGroup.FontName = 'Tahoma';

            % Create IdleButton
            app.IdleButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.IdleButton.Tag = 'idle';
            app.IdleButton.Icon = 'baseline_stop_black_24dp.png';
            app.IdleButton.Text = 'Idle';
            app.IdleButton.FontName = 'Tahoma';
            app.IdleButton.Position = [27 3 126 50];
            app.IdleButton.Value = true;

            % Create RunButton
            app.RunButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.RunButton.Tag = 'run';
            app.RunButton.Icon = 'outline_live_tv_black_24dp.png';
            app.RunButton.Text = 'Run';
            app.RunButton.FontName = 'Tahoma';
            app.RunButton.Position = [174 3 143 50];

            % Create RecordButton
            app.RecordButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.RecordButton.Tag = 'rec';
            app.RecordButton.Icon = 'baseline_radio_button_checked_black_24dp.png';
            app.RecordButton.Text = 'Record';
            app.RecordButton.FontName = 'Tahoma';
            app.RecordButton.Position = [490 3 159 50];

            % Create QuitButton
            app.QuitButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.QuitButton.Tag = 'quit';
            app.QuitButton.Icon = 'baseline_power_off_black_24dp.png';
            app.QuitButton.Text = 'Quit';
            app.QuitButton.FontName = 'Tahoma';
            app.QuitButton.Position = [666 3 98 50];

            % Create ImpedanceButton
            app.ImpedanceButton = uitogglebutton(app.TMSiStateButtonGroup);
            app.ImpedanceButton.Tag = 'imp';
            app.ImpedanceButton.Icon = 'Impedance-Symbol.png';
            app.ImpedanceButton.Text = 'Impedance';
            app.ImpedanceButton.FontName = 'Tahoma';
            app.ImpedanceButton.Position = [336 3 139 50];

            % Create RawDataFolderEditFieldLabel
            app.RawDataFolderEditFieldLabel = uilabel(app.DeviceControlGridLayout);
            app.RawDataFolderEditFieldLabel.HorizontalAlignment = 'right';
            app.RawDataFolderEditFieldLabel.FontName = 'Tahoma';
            app.RawDataFolderEditFieldLabel.FontSize = 17;
            app.RawDataFolderEditFieldLabel.FontWeight = 'bold';
            app.RawDataFolderEditFieldLabel.Layout.Row = 1;
            app.RawDataFolderEditFieldLabel.Layout.Column = 1;
            app.RawDataFolderEditFieldLabel.Text = 'Raw Data Folder';

            % Create RawDataFolderEditField
            app.RawDataFolderEditField = uieditfield(app.DeviceControlGridLayout, 'text');
            app.RawDataFolderEditField.HorizontalAlignment = 'right';
            app.RawDataFolderEditField.FontName = 'Tahoma';
            app.RawDataFolderEditField.FontSize = 20;
            app.RawDataFolderEditField.Placeholder = 'e.g. R:/NMLShare/raw_data/primate';
            app.RawDataFolderEditField.Layout.Row = 1;
            app.RawDataFolderEditField.Layout.Column = [2 4];

            % Create TriggeringTab
            app.TriggeringTab = uitab(app.TabGroup);
            app.TriggeringTab.Title = 'Triggering';

            % Create TriggeringGridLayout
            app.TriggeringGridLayout = uigridlayout(app.TriggeringTab);
            app.TriggeringGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.TriggeringGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.TriggeringGridLayout.Visible = 'off';
            app.TriggeringGridLayout.BackgroundColor = [1 1 1];

            % Create SAGAASTAChannelEditFieldLabel
            app.SAGAASTAChannelEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.SAGAASTAChannelEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGAASTAChannelEditFieldLabel.FontName = 'Tahoma';
            app.SAGAASTAChannelEditFieldLabel.FontSize = 16;
            app.SAGAASTAChannelEditFieldLabel.FontWeight = 'bold';
            app.SAGAASTAChannelEditFieldLabel.Layout.Row = 1;
            app.SAGAASTAChannelEditFieldLabel.Layout.Column = 1;
            app.SAGAASTAChannelEditFieldLabel.Text = 'SAGA-A STA Channel';

            % Create SAGAASTAChannelEditField
            app.SAGAASTAChannelEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.SAGAASTAChannelEditField.Limits = [1 68];
            app.SAGAASTAChannelEditField.RoundFractionalValues = 'on';
            app.SAGAASTAChannelEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingNewTriggerChannelMessage, true);
            app.SAGAASTAChannelEditField.Tag = 'A';
            app.SAGAASTAChannelEditField.HorizontalAlignment = 'center';
            app.SAGAASTAChannelEditField.FontName = 'Tahoma';
            app.SAGAASTAChannelEditField.FontSize = 16;
            app.SAGAASTAChannelEditField.Layout.Row = 1;
            app.SAGAASTAChannelEditField.Layout.Column = 2;
            app.SAGAASTAChannelEditField.Value = 1;

            % Create SAGABSTAChannelEditFieldLabel
            app.SAGABSTAChannelEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.SAGABSTAChannelEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGABSTAChannelEditFieldLabel.FontName = 'Tahoma';
            app.SAGABSTAChannelEditFieldLabel.FontSize = 16;
            app.SAGABSTAChannelEditFieldLabel.FontWeight = 'bold';
            app.SAGABSTAChannelEditFieldLabel.Layout.Row = 2;
            app.SAGABSTAChannelEditFieldLabel.Layout.Column = 1;
            app.SAGABSTAChannelEditFieldLabel.Text = 'SAGA-B STA Channel';

            % Create SAGABSTAChannelEditField
            app.SAGABSTAChannelEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.SAGABSTAChannelEditField.Limits = [1 68];
            app.SAGABSTAChannelEditField.RoundFractionalValues = 'on';
            app.SAGABSTAChannelEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingNewTriggerChannelMessage, true);
            app.SAGABSTAChannelEditField.Tag = 'B';
            app.SAGABSTAChannelEditField.HorizontalAlignment = 'center';
            app.SAGABSTAChannelEditField.FontName = 'Tahoma';
            app.SAGABSTAChannelEditField.FontSize = 16;
            app.SAGABSTAChannelEditField.Layout.Row = 2;
            app.SAGABSTAChannelEditField.Layout.Column = 2;
            app.SAGABSTAChannelEditField.Value = 1;

            % Create PreTriggerSamplesEditFieldLabel
            app.PreTriggerSamplesEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.PreTriggerSamplesEditFieldLabel.HorizontalAlignment = 'right';
            app.PreTriggerSamplesEditFieldLabel.FontName = 'Tahoma';
            app.PreTriggerSamplesEditFieldLabel.FontSize = 16;
            app.PreTriggerSamplesEditFieldLabel.FontWeight = 'bold';
            app.PreTriggerSamplesEditFieldLabel.Layout.Row = 4;
            app.PreTriggerSamplesEditFieldLabel.Layout.Column = 1;
            app.PreTriggerSamplesEditFieldLabel.Text = 'Pre-Trigger Samples';

            % Create PreTriggerSamplesEditField
            app.PreTriggerSamplesEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.PreTriggerSamplesEditField.Limits = [1 1000];
            app.PreTriggerSamplesEditField.RoundFractionalValues = 'on';
            app.PreTriggerSamplesEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingConfigMessageToAll, true);
            app.PreTriggerSamplesEditField.HorizontalAlignment = 'center';
            app.PreTriggerSamplesEditField.FontName = 'Tahoma';
            app.PreTriggerSamplesEditField.FontSize = 16;
            app.PreTriggerSamplesEditField.Layout.Row = 4;
            app.PreTriggerSamplesEditField.Layout.Column = 2;
            app.PreTriggerSamplesEditField.Value = 40;

            % Create PostTriggerSamplesEditFieldLabel
            app.PostTriggerSamplesEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.PostTriggerSamplesEditFieldLabel.HorizontalAlignment = 'right';
            app.PostTriggerSamplesEditFieldLabel.FontName = 'Tahoma';
            app.PostTriggerSamplesEditFieldLabel.FontSize = 16;
            app.PostTriggerSamplesEditFieldLabel.FontWeight = 'bold';
            app.PostTriggerSamplesEditFieldLabel.Layout.Row = 5;
            app.PostTriggerSamplesEditFieldLabel.Layout.Column = 1;
            app.PostTriggerSamplesEditFieldLabel.Text = 'Post-Trigger Samples';

            % Create PostTriggerSamplesEditField
            app.PostTriggerSamplesEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.PostTriggerSamplesEditField.Limits = [1 4000];
            app.PostTriggerSamplesEditField.RoundFractionalValues = 'on';
            app.PostTriggerSamplesEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingConfigMessageToAll, true);
            app.PostTriggerSamplesEditField.HorizontalAlignment = 'center';
            app.PostTriggerSamplesEditField.FontName = 'Tahoma';
            app.PostTriggerSamplesEditField.FontSize = 16;
            app.PostTriggerSamplesEditField.Layout.Row = 5;
            app.PostTriggerSamplesEditField.Layout.Column = 2;
            app.PostTriggerSamplesEditField.Value = 120;

            % Create NTriggersStoredEditFieldLabel
            app.NTriggersStoredEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.NTriggersStoredEditFieldLabel.HorizontalAlignment = 'right';
            app.NTriggersStoredEditFieldLabel.FontName = 'Tahoma';
            app.NTriggersStoredEditFieldLabel.FontSize = 16;
            app.NTriggersStoredEditFieldLabel.FontWeight = 'bold';
            app.NTriggersStoredEditFieldLabel.Layout.Row = 6;
            app.NTriggersStoredEditFieldLabel.Layout.Column = 1;
            app.NTriggersStoredEditFieldLabel.Text = 'N Triggers Stored';

            % Create NTriggersStoredEditField
            app.NTriggersStoredEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.NTriggersStoredEditField.Limits = [1 4000];
            app.NTriggersStoredEditField.RoundFractionalValues = 'on';
            app.NTriggersStoredEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingConfigMessageToAll, true);
            app.NTriggersStoredEditField.HorizontalAlignment = 'center';
            app.NTriggersStoredEditField.FontName = 'Tahoma';
            app.NTriggersStoredEditField.FontSize = 16;
            app.NTriggersStoredEditField.Layout.Row = 6;
            app.NTriggersStoredEditField.Layout.Column = 2;
            app.NTriggersStoredEditField.Value = 30;

            % Create ResetTriggersButton
            app.ResetTriggersButton = uibutton(app.TriggeringGridLayout, 'push');
            app.ResetTriggersButton.ButtonPushedFcn = createCallbackFcn(app, @HandleSendingConfigMessageToAll, true);
            app.ResetTriggersButton.FontName = 'Tahoma';
            app.ResetTriggersButton.FontSize = 16;
            app.ResetTriggersButton.FontWeight = 'bold';
            app.ResetTriggersButton.FontColor = [1 0 0];
            app.ResetTriggersButton.Layout.Row = 7;
            app.ResetTriggersButton.Layout.Column = 4;
            app.ResetTriggersButton.Text = 'Reset Triggers';

            % Create SAGAATriggerBitEditFieldLabel
            app.SAGAATriggerBitEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.SAGAATriggerBitEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGAATriggerBitEditFieldLabel.FontName = 'Tahoma';
            app.SAGAATriggerBitEditFieldLabel.FontSize = 16;
            app.SAGAATriggerBitEditFieldLabel.FontWeight = 'bold';
            app.SAGAATriggerBitEditFieldLabel.Layout.Row = 1;
            app.SAGAATriggerBitEditFieldLabel.Layout.Column = 3;
            app.SAGAATriggerBitEditFieldLabel.Text = 'SAGA-A Trigger Bit';

            % Create SAGAATriggerBitEditField
            app.SAGAATriggerBitEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.SAGAATriggerBitEditField.Limits = [0 15];
            app.SAGAATriggerBitEditField.RoundFractionalValues = 'on';
            app.SAGAATriggerBitEditField.ValueChangedFcn = createCallbackFcn(app, @HandleSendingNewBitMessage, true);
            app.SAGAATriggerBitEditField.Tag = 'A';
            app.SAGAATriggerBitEditField.HorizontalAlignment = 'center';
            app.SAGAATriggerBitEditField.FontName = 'Tahoma';
            app.SAGAATriggerBitEditField.FontSize = 16;
            app.SAGAATriggerBitEditField.Layout.Row = 1;
            app.SAGAATriggerBitEditField.Layout.Column = 4;
            app.SAGAATriggerBitEditField.Value = 9;

            % Create SAGABTriggerBitEditFieldLabel
            app.SAGABTriggerBitEditFieldLabel = uilabel(app.TriggeringGridLayout);
            app.SAGABTriggerBitEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGABTriggerBitEditFieldLabel.FontName = 'Tahoma';
            app.SAGABTriggerBitEditFieldLabel.FontSize = 16;
            app.SAGABTriggerBitEditFieldLabel.FontWeight = 'bold';
            app.SAGABTriggerBitEditFieldLabel.Layout.Row = 2;
            app.SAGABTriggerBitEditFieldLabel.Layout.Column = 3;
            app.SAGABTriggerBitEditFieldLabel.Text = 'SAGA-B Trigger Bit';

            % Create SAGABTriggerBitEditField
            app.SAGABTriggerBitEditField = uieditfield(app.TriggeringGridLayout, 'numeric');
            app.SAGABTriggerBitEditField.Limits = [0 15];
            app.SAGABTriggerBitEditField.RoundFractionalValues = 'on';
            app.SAGABTriggerBitEditField.Tag = 'B';
            app.SAGABTriggerBitEditField.HorizontalAlignment = 'center';
            app.SAGABTriggerBitEditField.FontName = 'Tahoma';
            app.SAGABTriggerBitEditField.FontSize = 16;
            app.SAGABTriggerBitEditField.Layout.Row = 2;
            app.SAGABTriggerBitEditField.Layout.Column = 4;
            app.SAGABTriggerBitEditField.Value = 9;

            % Create UNISnippetsTab
            app.UNISnippetsTab = uitab(app.TabGroup);
            app.UNISnippetsTab.Title = 'UNI Snippets';

            % Create UNISnippetsGridLayout
            app.UNISnippetsGridLayout = uigridlayout(app.UNISnippetsTab);
            app.UNISnippetsGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.UNISnippetsGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.UNISnippetsGridLayout.Visible = 'off';
            app.UNISnippetsGridLayout.BackgroundColor = [1 1 1];

            % Create RMSRangeLowerBoundEditFieldLabel
            app.RMSRangeLowerBoundEditFieldLabel = uilabel(app.UNISnippetsGridLayout);
            app.RMSRangeLowerBoundEditFieldLabel.HorizontalAlignment = 'right';
            app.RMSRangeLowerBoundEditFieldLabel.FontName = 'Tahoma';
            app.RMSRangeLowerBoundEditFieldLabel.FontSize = 16;
            app.RMSRangeLowerBoundEditFieldLabel.FontWeight = 'bold';
            app.RMSRangeLowerBoundEditFieldLabel.Layout.Row = 1;
            app.RMSRangeLowerBoundEditFieldLabel.Layout.Column = [1 2];
            app.RMSRangeLowerBoundEditFieldLabel.Text = 'RMS Range Lower Bound';

            % Create RMSRangeLowerBoundEditField
            app.RMSRangeLowerBoundEditField = uieditfield(app.UNISnippetsGridLayout, 'numeric');
            app.RMSRangeLowerBoundEditField.Limits = [0 Inf];
            app.RMSRangeLowerBoundEditField.ValueChangedFcn = createCallbackFcn(app, @RMSRangeBoundEditFieldValueChanged, true);
            app.RMSRangeLowerBoundEditField.HorizontalAlignment = 'center';
            app.RMSRangeLowerBoundEditField.FontName = 'Tahoma';
            app.RMSRangeLowerBoundEditField.FontSize = 16;
            app.RMSRangeLowerBoundEditField.Layout.Row = 1;
            app.RMSRangeLowerBoundEditField.Layout.Column = 3;

            % Create RMSRangeUpperBoundEditFieldLabel
            app.RMSRangeUpperBoundEditFieldLabel = uilabel(app.UNISnippetsGridLayout);
            app.RMSRangeUpperBoundEditFieldLabel.HorizontalAlignment = 'right';
            app.RMSRangeUpperBoundEditFieldLabel.FontName = 'Tahoma';
            app.RMSRangeUpperBoundEditFieldLabel.FontSize = 16;
            app.RMSRangeUpperBoundEditFieldLabel.FontWeight = 'bold';
            app.RMSRangeUpperBoundEditFieldLabel.Layout.Row = 2;
            app.RMSRangeUpperBoundEditFieldLabel.Layout.Column = [1 2];
            app.RMSRangeUpperBoundEditFieldLabel.Text = 'RMS Range Upper Bound';

            % Create RMSRangeUpperBoundEditField
            app.RMSRangeUpperBoundEditField = uieditfield(app.UNISnippetsGridLayout, 'numeric');
            app.RMSRangeUpperBoundEditField.Limits = [0 Inf];
            app.RMSRangeUpperBoundEditField.ValueChangedFcn = createCallbackFcn(app, @RMSRangeBoundEditFieldValueChanged, true);
            app.RMSRangeUpperBoundEditField.HorizontalAlignment = 'center';
            app.RMSRangeUpperBoundEditField.FontName = 'Tahoma';
            app.RMSRangeUpperBoundEditField.FontSize = 16;
            app.RMSRangeUpperBoundEditField.Layout.Row = 2;
            app.RMSRangeUpperBoundEditField.Layout.Column = 3;
            app.RMSRangeUpperBoundEditField.Value = 30;

            % Create SAGAAChannelsEditFieldLabel
            app.SAGAAChannelsEditFieldLabel = uilabel(app.UNISnippetsGridLayout);
            app.SAGAAChannelsEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGAAChannelsEditFieldLabel.FontName = 'Tahoma';
            app.SAGAAChannelsEditFieldLabel.Layout.Row = 4;
            app.SAGAAChannelsEditFieldLabel.Layout.Column = 1;
            app.SAGAAChannelsEditFieldLabel.Text = 'SAGA-A Channels';

            % Create SAGAAChannelsEditField
            app.SAGAAChannelsEditField = uieditfield(app.UNISnippetsGridLayout, 'text');
            app.SAGAAChannelsEditField.ValueChangedFcn = createCallbackFcn(app, @RMSRangeBoundEditFieldValueChanged, true);
            app.SAGAAChannelsEditField.FontName = 'Tahoma';
            app.SAGAAChannelsEditField.Layout.Row = 4;
            app.SAGAAChannelsEditField.Layout.Column = [2 4];
            app.SAGAAChannelsEditField.Value = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64';

            % Create SAGABChannelsEditFieldLabel
            app.SAGABChannelsEditFieldLabel = uilabel(app.UNISnippetsGridLayout);
            app.SAGABChannelsEditFieldLabel.HorizontalAlignment = 'right';
            app.SAGABChannelsEditFieldLabel.FontName = 'Tahoma';
            app.SAGABChannelsEditFieldLabel.Layout.Row = 5;
            app.SAGABChannelsEditFieldLabel.Layout.Column = 1;
            app.SAGABChannelsEditFieldLabel.Text = 'SAGA-B Channels';

            % Create SAGABChannelsEditField
            app.SAGABChannelsEditField = uieditfield(app.UNISnippetsGridLayout, 'text');
            app.SAGABChannelsEditField.ValueChangedFcn = createCallbackFcn(app, @RMSRangeBoundEditFieldValueChanged, true);
            app.SAGABChannelsEditField.FontName = 'Tahoma';
            app.SAGABChannelsEditField.Layout.Row = 5;
            app.SAGABChannelsEditField.Layout.Column = [2 4];
            app.SAGABChannelsEditField.Value = '1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64';

            % Create DataServerTab
            app.DataServerTab = uitab(app.TabGroup);
            app.DataServerTab.Title = 'Data Server';

            % Create DataServerGridLayout
            app.DataServerGridLayout = uigridlayout(app.DataServerTab);
            app.DataServerGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x'};
            app.DataServerGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x'};
            app.DataServerGridLayout.BackgroundColor = [1 1 1];

            % Create DataServerStatusLampLabel
            app.DataServerStatusLampLabel = uilabel(app.DataServerGridLayout);
            app.DataServerStatusLampLabel.HorizontalAlignment = 'right';
            app.DataServerStatusLampLabel.FontName = 'Tahoma';
            app.DataServerStatusLampLabel.FontSize = 16;
            app.DataServerStatusLampLabel.FontWeight = 'bold';
            app.DataServerStatusLampLabel.Layout.Row = 1;
            app.DataServerStatusLampLabel.Layout.Column = 1;
            app.DataServerStatusLampLabel.Text = 'Data Server Status';

            % Create DataServerStatusLamp
            app.DataServerStatusLamp = uilamp(app.DataServerGridLayout);
            app.DataServerStatusLamp.Layout.Row = 1;
            app.DataServerStatusLamp.Layout.Column = 2;
            app.DataServerStatusLamp.Color = [0.902 0.902 0.902];

            % Create DataServerIPEditFieldLabel
            app.DataServerIPEditFieldLabel = uilabel(app.DataServerGridLayout);
            app.DataServerIPEditFieldLabel.HorizontalAlignment = 'right';
            app.DataServerIPEditFieldLabel.FontName = 'Tahoma';
            app.DataServerIPEditFieldLabel.FontSize = 16;
            app.DataServerIPEditFieldLabel.FontWeight = 'bold';
            app.DataServerIPEditFieldLabel.Tooltip = {'IP Address of data server connection tcpserver object.'};
            app.DataServerIPEditFieldLabel.Layout.Row = 2;
            app.DataServerIPEditFieldLabel.Layout.Column = 1;
            app.DataServerIPEditFieldLabel.Text = 'Data Server IP';

            % Create DataServerIPEditField
            app.DataServerIPEditField = uieditfield(app.DataServerGridLayout, 'text');
            app.DataServerIPEditField.HorizontalAlignment = 'center';
            app.DataServerIPEditField.FontName = 'Tahoma';
            app.DataServerIPEditField.FontSize = 20;
            app.DataServerIPEditField.Placeholder = 'A.B.C.D';
            app.DataServerIPEditField.Layout.Row = 2;
            app.DataServerIPEditField.Layout.Column = [2 3];
            app.DataServerIPEditField.Value = '127.0.0.1';

            % Create DataServerPortEditFieldLabel
            app.DataServerPortEditFieldLabel = uilabel(app.DataServerGridLayout);
            app.DataServerPortEditFieldLabel.HorizontalAlignment = 'right';
            app.DataServerPortEditFieldLabel.FontName = 'Tahoma';
            app.DataServerPortEditFieldLabel.FontSize = 16;
            app.DataServerPortEditFieldLabel.FontWeight = 'bold';
            app.DataServerPortEditFieldLabel.Layout.Row = 3;
            app.DataServerPortEditFieldLabel.Layout.Column = 1;
            app.DataServerPortEditFieldLabel.Text = 'Data Server Port';

            % Create DataServerPortEditField
            app.DataServerPortEditField = uieditfield(app.DataServerGridLayout, 'numeric');
            app.DataServerPortEditField.Limits = [1 100000];
            app.DataServerPortEditField.RoundFractionalValues = 'on';
            app.DataServerPortEditField.HorizontalAlignment = 'center';
            app.DataServerPortEditField.FontName = 'Tahoma';
            app.DataServerPortEditField.FontSize = 20;
            app.DataServerPortEditField.Layout.Row = 3;
            app.DataServerPortEditField.Layout.Column = [2 3];
            app.DataServerPortEditField.Value = 5070;

            % Create DataServerConnectionPushButton
            app.DataServerConnectionPushButton = uibutton(app.DataServerGridLayout, 'push');
            app.DataServerConnectionPushButton.ButtonPushedFcn = createCallbackFcn(app, @DataServerConnectionPushButtonPushed, true);
            app.DataServerConnectionPushButton.Icon = fullfile(pathToMLAPP, 'baseline_link_black_24dp.png');
            app.DataServerConnectionPushButton.FontName = 'Tahoma';
            app.DataServerConnectionPushButton.FontSize = 20;
            app.DataServerConnectionPushButton.FontWeight = 'bold';
            app.DataServerConnectionPushButton.Layout.Row = 4;
            app.DataServerConnectionPushButton.Layout.Column = [2 3];
            app.DataServerConnectionPushButton.Text = 'Open Connection';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SAGA_Controller(varargin)

            runningApp = getRunningApp(app);

            % Check for running singleton app
            if isempty(runningApp)

                % Create UIFigure and components
                createComponents(app)

                % Register the app with App Designer
                registerApp(app, app.UIFigure)

                % Execute the startup function
                runStartupFcn(app, @(app)startupFcn(app, varargin{:}))
            else

                % Focus the running singleton app
                figure(runningApp.UIFigure)

                app = runningApp;
            end

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end