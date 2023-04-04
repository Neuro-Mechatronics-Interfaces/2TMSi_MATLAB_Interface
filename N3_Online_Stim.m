classdef N3_Online_Stim < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                        matlab.ui.Figure
        MainGridLayout                  matlab.ui.container.GridLayout
        ResponsesOnlineStatusLamp       matlab.ui.control.Lamp
        ResponsesOnlineStatusLampLabel  matlab.ui.control.Label
        IntensityLabel                  matlab.ui.control.Label
        YLabel                          matlab.ui.control.Label
        XLabel                          matlab.ui.control.Label
        TabGroup                        matlab.ui.container.TabGroup
        StimTab                         matlab.ui.container.Tab
        StimGridLayout                  matlab.ui.container.GridLayout
        PatternsLoadedLabel             matlab.ui.control.Label
        CreateOptionButton              matlab.ui.control.Button
        SendButton                      matlab.ui.control.Button
        StimulationControllerIPEditField  matlab.ui.control.EditField
        StimulationControllerIPEditFieldLabel  matlab.ui.control.Label
        StimulationControllerPortEditField  matlab.ui.control.NumericEditField
        StimulationControllerPortEditFieldLabel  matlab.ui.control.Label
        StimulationControllerStatusLamp  matlab.ui.control.Lamp
        QueuedPatternsUITableLabel      matlab.ui.control.Label
        QueuedPatternsUITable           matlab.ui.control.Table
        RepetitionsEditFieldLabel       matlab.ui.control.Label
        IntensityEditFieldLabel         matlab.ui.control.Label
        RepetitionsEditField            matlab.ui.control.NumericEditField
        AddSelectedButton               matlab.ui.control.Button
        IntensityEditField              matlab.ui.control.NumericEditField
        SelectedPatternsUITableLabel    matlab.ui.control.Label
        SelectedPatternsUITable         matlab.ui.control.Table
        ChooseOptionsButton             matlab.ui.control.Button
        StimulationOptionsListBox       matlab.ui.control.ListBox
        StimulationControllerModeDropDown  matlab.ui.control.DropDown
        StimulationControllerModeDropDownLabel  matlab.ui.control.Label
        StimulationControllerConnectButton  matlab.ui.control.Button
        ResponseTab                     matlab.ui.container.Tab
        ResponseGridLayout              matlab.ui.container.GridLayout
        StimCountLabel                  matlab.ui.control.Label
        RefreshButton                   matlab.ui.control.Button
        CLimEditField                   matlab.ui.control.NumericEditField
        CLimEditFieldLabel              matlab.ui.control.Label
        ResponseSweepFilterEditFieldLabel  matlab.ui.control.Label
        ResponseSweepFilterEditField    matlab.ui.control.EditField
        ResponseAmplitudeFilterEditFieldLabel  matlab.ui.control.Label
        ResponseSAGAFilterDropDownLabel  matlab.ui.control.Label
        ResponseChannelFilterEditFieldLabel  matlab.ui.control.Label
        ResponseAmplitudeFilterEditField  matlab.ui.control.NumericEditField
        ResponseChannelFilterEditField  matlab.ui.control.NumericEditField
        ResponseSAGAFilterDropDown      matlab.ui.control.DropDown
        ResponseUIAxes                  matlab.ui.control.UIAxes
        ConfigureTab                    matlab.ui.container.Tab
        ConfigureGridLayout             matlab.ui.container.GridLayout
        ExportCurrentPatternsButton     matlab.ui.control.Button
        ExportFolderEditField           matlab.ui.control.EditField
        ExportFolderEditFieldLabel      matlab.ui.control.Label
        ImportGridSubsetButton          matlab.ui.control.Button
        DeltaYEditField                 matlab.ui.control.NumericEditField
        XmLabel_2                       matlab.ui.control.Label
        DeltaXEditField                 matlab.ui.control.NumericEditField
        XmLabel                         matlab.ui.control.Label
        YMaxEditField                   matlab.ui.control.NumericEditField
        YMaxmEditFieldLabel             matlab.ui.control.Label
        YMinEditField                   matlab.ui.control.NumericEditField
        YMinmEditFieldLabel             matlab.ui.control.Label
        XMaxEditField                   matlab.ui.control.NumericEditField
        XMaxmEditFieldLabel             matlab.ui.control.Label
        XMinEditField                   matlab.ui.control.NumericEditField
        XMinmEditFieldLabel             matlab.ui.control.Label
    end

    
    properties (Access = public)
        connected (1,1) struct = struct('stimulator', false, 'responses', false); % Flags indicating connection status to stimulator and responses client
        has_patterns (1,1) logical = false;
        rserver % Responses tcpserver object
        sclient % Stimulation controller tcpclient object
        pdata   % Struct array containing the pattern data parsed from pattern filenames (for all pattern options in selected folder)
    end

    properties (Access = private)
        patterns_dir_ (1,1) string
        logger_ (1,1) mlog.Logger = mlog.Logger('OnlineStims');
        pdata_   % Singleton struct generated/updated any time `send_message_to_stimulator` method is called
        rdata_   % Struct with fields 'A' and 'B'. Each contains data table containing 1 row per response data. Columns are: 'SAGA' | 'Group' | 'Channel' | 'Intensity' | 'Sweep' | 'Response' | 
        img_     % Response data image object
        sent_ (1,:) struct = struct('sweep', {}, 'intensity', {}, 'index', {}); % Struct with indexing to current stimulus pattern(s) in queue. Most-recent stimuli are the largest-indexed elements.
        received_ (1,:) struct = struct('sweep', {}, 'intensity', {}, 'index', {});
        xg_  % X-grid for pattern responses
        yg_  % Y-grid for pattern responses
        xlim_ (1,2) double = [-6500, 6500];
        ylim_ (1,2) double = [-2500, 2500];
        clim_ (1,2) double = [0, 10]; % Colormap limits for response axes visualization
        colormap_ (:, 3) double % Color mapping for response amplitudes
        cb_  % Colorbar for image
        kernel_width_ (1,1) double = 4; % Number of bins in exponential smoothing kernel.
    end

    properties (Constant, Hidden)
        LAMP_CONNECTED_COLOR = [0.39,0.83,0.07]; % Color of lamps when connected
        LAMP_DISCONNECTED_COLOR = [0.65,0.65,0.65]; % Color of lamps when disconnected
        LAMP_ERROR_COLOR = [0.8 0.2 0.2]; % Color of lamps when there is a problem
    end
    
    methods (Access = public)  
        % Returns the response data based on filters in Responses tab
        function data = get_filtered_response_subset(app)
            %GET_FILTERED_RESPONSE_SUBSET  Return the response data based on filter selections.
            %
            % Syntax:
            %   data = app.get_filtered_response_subset();
            tag = app.ResponseSAGAFilterDropDown.Value;
            ch = app.ResponseChannelFilterEditField.Value;
            intensity = app.ResponseAmplitudeFilterEditField.Value;
            sweep = app.ResponseSweepFilterEditField.Value;
            data = app.rdata_.(tag)( ...
                              (app.rdata_.(tag).Channel == ch) & ...
                              (app.rdata_.(tag).Intensity == intensity) & ...
                              strcmpi(app.rdata_.(tag).Sweep, sweep), :);
        end

        % Handle stimulation pattern messages from the stimulation tcpserver
        function handle_sclient_msg_from_stimulator(app, src, ~)
            %HANDLE_SCLIENT_MSG_FROM_STIMULATOR  Handles stimulation pattern JSON-serialized messages from stimulation controller tcpserver.
            message = src.readline(); % struct with fields: 'pattern', 'amplitude'
            data = jsondecode(message);
            if ismember(app.StimulationControllerModeDropDown.Value, {'Passive'})
                tmp_index = find(strcmpi([app.pdata.name], data.pattern), 1, 'first');
                if isempty(tmp_index)
                    fprintf(1, "[N3 STIM INTERFACE]\tRunning in Passive mode, but no pdata for received pattern (%s).\n", data.pattern);
                else
                    tmp_sweep = strsplit(data.pattern, '_');
                    tmp_sweep = strjoin(tmp_sweep(1:2), '_');
                    if ~strcmpi(app.ResponseSweepFilterEditField.Value, tmp_sweep)
                        app.ResponseSweepFilterEditField.Value = tmp_sweep;
                    end
                    rcv = struct('sweep', tmp_sweep, 'intensity', data.amplitude, 'index', tmp_index);
                    app.received_(end+1) = rcv;
                    app.QueuedPatternsUITable.Data = [app.QueuedPatternsUITable.Data; ...
                        {char(data.pattern), data.amplitude}];
                end
            else
                msgbox([string(sprintf("pattern: %s", data.pattern)); ...
                        string(sprintf("amplitude: %5.2f%%", data.amplitude))], ...
                        "Stimulation Message Received", "modal");
            end
            app.logger_.info(sprintf("STIM_SERVER :: %s", message));
        end

        % Connection changed callback for "response" tcpserver object.
        function handle_rserver_connection_change(app, src, ~)
            %HANDLE_RSERVER_CONNECTION_CHANGE  Just change the connection lamp color and update the corresponding field in `connected` flags.
            app.connected.responses = src.Connected;
            if src.Connected
                app.ResponsesOnlineStatusLamp.Color = app.LAMP_CONNECTED_COLOR;
            else
                app.ResponsesOnlineStatusLamp.Color = app.LAMP_DISCONNECTED_COLOR;
            end
        end

        % Handle response data messages to the tcpserver object.
        function handle_rserver_response_message(app, src, ~)
            %HANDLE_RSERVER_RESPONSE_MESSAGE Handle response data messages
            %
            % Messages are expected to arrive in JSON-serialized format,
            % with the structure:
            %   data = struct('type', type, ... 0 -> metadata | 1 -> response data
            %   
            %   The rest of the structure, for metadata data type (0) :
            %                'cmd', command); command: "next" (drop most-recent queued data)
            %
            %   The rest of the structure, for response data type (1) :             
            %                'saga', app.Tag, ... "A" or "B"
            %                'n', n_new, ... Number of new pulses
            %                'channel', ch, ... vector up to 1:68 (UNI & BIP channels together)
            %                'response', mean_rms); same number elements as ch, matched 1:1- mean RMS by channel
            data = jsondecode(src.readline());
            n_pulse = data.n;
            data = rmfield(data, 'n');
            n_ch = numel(data.channel);
            data.channel = reshape(data.channel, n_ch, 1);
            response = reshape(data.response(:), n_ch, n_pulse);
            for ii = 1:n_pulse
                if ismember(app.StimulationControllerModeDropDown.Value, {'Manual', 'Adaptive'})
                    if isempty(app.sent_)
                        return;
                    end
                    q = app.sent_(1);
                else
                    if isempty(app.received_)
                        return;
                    end
                    q = app.received_(1);
                end
                p = app.pdata(q.index);
                data.intensity = q.intensity;
                data.sweep = q.sweep;
                data.index = q.index;
                data.x = p.x;
                data.y = p.y;
                data.response = response(:, ii);
                app.logger_.info(sprintf('RESPONSE :: %s', jsonencode(data)));
                app.update_response_data(data.tag, data.channel, ones(n_ch,1).*q.intensity, repmat(string(q.sweep),n_ch,1), ones(n_ch,1).*p.x, ones(n_ch,1).*p.y, data.response);
                if strcmpi(data.tag, "B") % Don't do this for both SAGAs- then we'll burn through the queue twice as fast.
                    if ismember(app.StimulationControllerModeDropDown.Value, {'Manual', 'Adaptive'})
                        app.sent_(1) = [];
                    else
                        app.received_(1) = [];
                    end
                end
            end
            app.update_response_plot();
            if ~isempty(app.QueuedPatternsUITable.Data) && strcmpi(data.tag, "B") % Same, don't want to burn through this twice as fast.
                app.QueuedPatternsUITable.Data(1,:) = [];
            end
        end

        % Parse all the .txt filenames in selpath folder.
        function parse_stim_txt_files(app, selpath, deltaX, deltaY)
            %PARSE_STIM_TXT_FILES  Parse stimulation .txt pattern files to generate pdata property array and fill in uicontrols.
            %
            % Syntax:
            %   app.parse_stim_txt_files(selpath);
            %
            % Inputs:
            %   selpath - Char array or string to some folder containing
            %               the .txt files.

            F = dir(fullfile(selpath, '*.txt'));
            if isempty(F)
                warning("Folder contained no valid stim-patterns.");
                return;
            end
            p = [];
            for iF = 1:numel(F)
                p = [p; parse_pattern_volume_string(F(iF).name)]; %#ok<AGROW> 
            end
            if nargin > 3
                app.pdata = filter_patterns_by_spatial_extent(p, app.xlim_, app.ylim_, deltaX, deltaY);
            else
                app.pdata = filter_patterns_by_spatial_extent(p, app.xlim_, app.ylim_);
            end
            [xg, yg] = parse_pattern_grid(app.pdata);
            app.xg_ = 1e3 * xg;
            app.yg_ = 1e3 * yg;
            opts = vertcat(app.pdata.name);
            n_opt = numel(opts);
            if n_opt > 0
                set(app.StimulationOptionsListBox, 'Items', opts, 'ItemsData', 1:n_opt, 'Value', 1, 'Enable', "on");
                app.has_patterns = true;
                if app.connected.stimulator && ismember(app.StimulationControllerModeDropDown.Value, {'Manual'}) && (size(app.SelectedPatternsUITable.Data,1) > 0)
                    app.SendButton.Enable = "on";
                end
                app.AddSelectedButton.Enable = "on";
                app.StimulationOptionsListBox.Enable = "on";
                if n_opt > 1
                    app.PatternsLoadedLabel.Text = string(sprintf("%d patterns loaded", n_opt));
                else
                    app.PatternsLoadedLabel.Text = "1 pattern loaded";
                end
            else
                app.has_patterns = false;
                app.SendButton.Enable = "off";
                app.AddSelectedButton.Enable = "off";
                app.StimulationOptionsListBox.Enable = "off";
                app.PatternsLoadedLabel.Text = "No patterns loaded";
            end

        end

        % Send stimulation json-serialized TCP command to stimulation
        % controller, log it, and update associated uicontrols.
        function send_message_to_stimulator(app, pattern_name, pattern_amplitude)
            %SEND_MESSAGE_TO_STIMULATOR  Format message for stimulator tcpserver and update relevant labels/indexing.
            if isempty(app.pdata)
                warning("No pattern-data loaded yet. Please populate pattern list before running stimulation.");
                return;
            end
            tmp = find(strcmpi([app.pdata.name], pattern_name), 1, 'first');
            if isempty(tmp)
                error("Could not find pattern ('%s') from %d items in pattern dataset.", ...
                    pattern_name, numel(app.pdata));
            end

            p = app.pdata(tmp);
            data = msg.json_stim_pattern(pattern_name, pattern_amplitude);
            message = jsonencode(data);
            app.sclient.writeline(message);

            % Log the stimulation pattern that was just sent.
            p.pattern_sweep = sprintf('%s_%d', p.optimizer, p.focusing_level);
            p.intensity = pattern_amplitude;
            app.logger_.info(sprintf('STIM :: %s', jsonencode(p)));

            % Auto-update the filter so we will be watching as it applies
            % to the most-recent stimulation command.
            app.sent_(end+1) = struct('sweep', p.pattern_sweep, 'intensity', pattern_amplitude, 'index', tmp);
            app.ResponseAmplitudeFilterEditField.Value = app.sent_(1).intensity;
            app.ResponseSweepFilterEditField.Value = app.sent_(1).sweep;
            app.QueuedPatternsUITable.Data = [app.QueuedPatternsUITable.Data; ...
                {char(pattern_name), pattern_amplitude}];
            p = app.pdata(app.sent_(1).index);
            app.XLabel.Text = string(sprintf('X: %5d μm', round(p.x * 1e3)));
            app.YLabel.Text = string(sprintf('Y: %5d μm', round(p.y * 1e3)));
            drawnow();
        end

        % Updates saved response data table with new data and log it. 
        function update_response_data(app, SAGA, Channel, Intensity, Sweep, X, Y, Response)
            %UPDATE_RESPONSE_DATA  Update saved response data table, and log it (but does not update graphics).
            %
            % This should be used by any configured callback of
            % `app.rserver` in order to populate the response table.
            %
            % It's used as a separate function from the message callback
            % handler, because that way it's possible to update the app
            % from an external script/function if it's not done by TCP/IP.
            %
            % NOTE: all inputs are expected to be scalar.
            T = table(Channel, Intensity, Sweep, X, Y, Response);
            app.rdata_.(SAGA) = [ app.rdata_.(SAGA); T ];
        end
    end

    methods (Access = protected)
        % Initialize the main data table (response data)
        function init_rdata_(app)
            %INIT_RDATA_  Initialize the main response data table
            app.rdata_ = struct('A', table(...
                                        'Size', [0, 6], ...
                                        'VariableTypes', {'double', 'double', 'string', 'double', 'double', 'double'}, ...
                                        'VariableNames', {'Channel', 'Intensity', 'Sweep', 'X', 'Y', 'Response'}), ...
                                'B', table(...
                                        'Size', [0, 6], ...
                                        'VariableTypes', {'double', 'double', 'string', 'double', 'double', 'double'}, ...
                                        'VariableNames', {'Channel', 'Intensity', 'Sweep', 'X', 'Y', 'Response'}));
        end

        % Initialize the axes that contains most of response visuals
        function init_response_axes_(app)
            %INIT_RESPONSE_AXES_ Initialize axes and child graphics that show responses.
            delete(app.ResponseUIAxes.Children);
            set(app.ResponseUIAxes, 'NextPlot', 'add', 'CLim', app.clim_, 'YDir', 'reverse', ...
                'XLim', app.xlim_, 'YLim', app.ylim_, 'Colormap', app.colormap_); 
            if ~isempty(app.xg_) && ~isempty(app.yg_)
                ny = numel(app.yg_)-1;
                nx = numel(app.xg_)-1;
                app.img_ = image(app.ResponseUIAxes, app.xlim_, app.ylim_, zeros(ny, nx), 'CDataMapping', 'scaled', 'Interpolation', 'bilinear');
            else
                app.img_ = image(app.ResponseUIAxes, app.xlim_, app.ylim_, nan, 'CDataMapping', 'scaled', 'Interpolation', 'bilinear');
            end
            app.cb_ = colorbar(app.ResponseUIAxes, 'FontName', 'Tahoma');
        end

        % Save the data table
        function save_rdata_(app)
            %SAVE_RDATA_  Save the data table
            outdir = fullfile(pwd, 'rdata');
            if exist(outdir, 'dir')==0
                mkdir(outdir);
            end
            dt = datetime("now","Format","uuuu-MM-dd_HH-mm-ss");
            fname = fullfile(outdir, sprintf('%s_%s_AMP-%d_responses.mat', string(dt), app.ResponseSweepFilterEditField.Value, round(app.ResponseAmplitudeFilterEditField.Value)));
            tmp = app.rdata_;
            tmp.A.SAGA = repmat("A", size(tmp.A,1), 1);
            tmp.B.SAGA = repmat("B", size(tmp.B,1),1);
            T = [tmp.A; tmp.B];
            save(fname, 'T', '-v7.3');
        end

        % Updates the contents of app.ResponseUIAxes
        function update_response_plot(app)
            %UPDATE_RESPONSE_PLOT  Apply the uicontrol filters and view scatter for the remaining rows of response data table.
            data = app.get_filtered_response_subset();
            ntotal = size(data,1);
            if ntotal == 0
                warning("No responses match filter conditions.");
                return;
            end
            [G, TID] = findgroups(data(:, {'X', 'Y'}));
            TID.C = splitapply(@mean, data.Response, G);
            nx = numel(app.xg_)-1;
            ny = numel(app.yg_)-1;
            cdata = zeros(ny, nx);
            ind = sub2ind([ny, nx], ...
                discretize(TID.Y, app.yg_), ...
                discretize(TID.X, app.xg_));
            cdata(ind) = TID.C;
            cdata = conv2(cdata, N3_NHP_Online_Interface.gaus_kernel(-app.kernel_width_:app.kernel_width_));
            set(app.img_, 'CData', cdata, 'XData', app.xlim_, 'YData', app.ylim_);
            app.StimCountLabel.Text = string(sprintf("N = %d", ntotal));
            drawnow();
        end
    end

    methods (Static, Access = private)
        function K = gaus_kernel(x)
            %GAUS_KERNEL  Return filter kernel K given vector x
            K = exp(-sqrt(x.^2 + (x').^2));
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, varargin)
            p = inputParser();
            p.addParameter('Colormap', [0, 0, 0; parula(255)], @(in)(all(isnumeric(in)) && (size(in,2)==3)));
            p.addParameter('IPConfigYaml', fullfile(pwd, 'ipconfig.yaml'), @(in)(all(ischar(in)) || isstring(in)));
            p.addParameter('StimPatternsFolder', fullfile(pwd,'patterns','HP_25'), @isfolder);
            p.parse(varargin{:});
            app.colormap_ = p.Results.Colormap;
            app.patterns_dir_ = string(p.Results.StimPatternsFolder);
            app.parse_stim_txt_files(app.patterns_dir_);
            fparts = strsplit(app.patterns_dir_, filesep);
            app.ExportFolderEditField.Value = strcat(string(strjoin(fparts(1:(end-1)), filesep)), string(filesep), "Exported");
            
            % Initialize the main data table
            app.init_rdata_();

            % Initialize the image that will go onto the main
            % response UIAxes.
            app.init_response_axes_();

            % Set default address/ports and create tcpserver for responses
            cfg = io.yaml.loadFile(p.Results.IPConfigYaml, 'ConvertToArray', true);
            app.StimulationControllerIPEditField.Value = cfg.stim.address;
            app.StimulationControllerPortEditField.Value = cfg.stim.port;
            tags = 'ABCDEFGHIJKLMNOP';
            for ii = 1:numel(cfg.responses.port)
                app.rserver.(tags(ii)) = tcpserver(cfg.responses.address, cfg.responses.port(ii), ...
                    "ConnectionChangedFcn", @app.handle_rserver_connection_change, ...
                    "Timeout", 5);
                app.rserver.(tags(ii)).configureCallback("terminator", @app.handle_rserver_response_message);
            end
        end

        % Button pushed function: StimulationControllerConnectButton
        function StimulationControllerConnectButtonPushed(app, event)
            if app.connected.stimulator
                try %#ok<TRYNC> 
                    delete(app.sclient);
                end
                event.Source.Text = "Connect";
                app.connected.stimulator = false;
                app.StimulationControllerStatusLamp.Color = app.LAMP_DISCONNECTED_COLOR;
            else
                try
                    app.sclient = tcpclient(...
                        app.StimulationControllerIPEditField.Value, ...
                        app.StimulationControllerPortEditField.Value, ...
                        "ConnectTimeout", 5.0, ...
                        "Timeout", 0.5);
                    app.sclient.configureCallback("terminator", @app.handle_sclient_msg_from_stimulator);
                catch
                    app.StimulationControllerStatusLamp.Color = app.LAMP_ERROR_COLOR;
                    return;
                end
                event.Source.Text = "Disconnect";
                app.StimulationControllerStatusLamp.Color = app.LAMP_CONNECTED_COLOR;
                app.connected.stimulator = true;    
                if (size(app.SelectedPatternsUITable.Data, 1) > 0) && ismember(app.StimulationControllerModeDropDown.Value, {'Manual'})
                    app.SendButton.Enable = "on";
                end
            end
        end

        % Value changed function: IntensityEditField
        function IntensityEditFieldValueChanged(app, event)
            value = app.IntensityEditField.Value;
            app.IntensityLabel.Text = string(sprintf('Intensity: %5.2f%%', value));
        end

        % Button pushed function: ChooseOptionsButton
        function ChooseOptionsButtonPushed(app, event)
            selpath = uigetdir(fullfile(pwd, 'patterns'), ...
                "Select folder containing pattern stim-pattern options.");
            if selpath == 0
                return;
            else
                app.patterns_dir_ = string(selpath);
                app.parse_stim_txt_files(app.patterns_dir_);
            end
        end

        % Value changed function: StimulationControllerModeDropDown
        function StimulationControllerModeDropDownValueChanged(app, event)
            value = app.StimulationControllerModeDropDown.Value;
            if ismember(value, {'Manual'})
                if app.connected.stimulator && app.has_patterns && (size(app.SelectedPatternsUITable.Data,1) > 0)
                    app.SendButton.Enable = "on";
                end
                app.QueuedPatternsUITableLabel.Text = "Sent (Awaiting Response)";
                app.SelectedPatternsUITable.Visible = "on";
                app.SelectedPatternsUITableLabel.Visible = "on";
            else
                app.SendButton.Enable = "off";
                if ismember(value, {'Passive'})
                    app.QueuedPatternsUITableLabel.Text = "Received (Awaiting Response)";
                    app.SelectedPatternsUITable.Visible = "off";
                    app.SelectedPatternsUITableLabel.Visible = "off";
                else
                    app.QueuedPatternsUITableLabel.Text = "Sent (Awaiting Response)";
                    app.SelectedPatternsUITable.Visible = "on";
                    app.SelectedPatternsUITableLabel.Visible = "on";
                end
            end
        end

        % Button pushed function: AddSelectedButton
        function AddSelectedButtonPushed(app, event)
            values = app.StimulationOptionsListBox.Value;
            reps = app.RepetitionsEditField.Value;
            amp = app.IntensityEditField.Value;
            for ii = 1:reps
                for ik = 1:numel(values)
                    app.SelectedPatternsUITable.Data = ...
                        [app.SelectedPatternsUITable.Data; ...
                         {char(app.pdata(values(ik)).name), amp}];
                end
            end
            if ismember(app.StimulationControllerModeDropDown.Value, {'Manual'}) && app.connected.stimulator
                app.SendButton.Enable = "on";
            end
        end

        % Button pushed function: SendButton
        function SendButtonPushed(app, event)
            if numel(app.SelectedPatternsUITable.Selection) < 1
                iSel = 1;
            else
                iSel = app.SelectedPatternsUITable.Selection;
            end
            app.UIFigure.Pointer = "watch";
            drawnow;
            for ii = 1:numel(iSel)
                pattern_name = app.SelectedPatternsUITable.Data{iSel(ii),1};
                pattern_amplitude = app.SelectedPatternsUITable.Data{iSel(ii),2};
                app.send_message_to_stimulator(pattern_name, pattern_amplitude);
            end
            app.UIFigure.Pointer = "arrow";
            drawnow;
            app.SelectedPatternsUITable.Data(iSel,:) = [];
            if size(app.SelectedPatternsUITable.Data,1) == 0
                app.SendButton.Enable = "off";
            end
        end

        % Key press function: QueuedPatternsUITable, 
        % ...and 1 other component
        function PatternsUITableKeyPress(app, event)
            key = event.Key;
            sel = unique(event.Source.Selection);
            switch key
                case 'delete'
                    event.Source.Data(sel, :) = [];
            end
        end

        % Value changed function: ResponseAmplitudeFilterEditField, 
        % ...and 3 other components
        function ResponseFilterValueChanged(app, event)
            app.update_response_plot();            
        end

        % Value changed function: CLimEditField
        function CLimEditFieldValueChanged(app, event)
            app.clim_(2) = app.CLimEditField.Value;
            app.init_response_axes_();
        end

        % Button pushed function: RefreshButton
        function RefreshButtonPushed(app, event)
            app.save_rdata_();
            app.init_rdata_();
            app.init_response_axes_();
            app.StimCountLabel.Text = "N = 0";
        end

        % Value changed function: XMinEditField
        function XMinEditFieldValueChanged(app, event)
            value = app.XMinEditField.Value;
            app.xlim_(1) = value;
            app.init_response_axes_();
        end

        % Value changed function: XMaxEditField
        function XMaxEditFieldValueChanged(app, event)
            value = app.XMaxEditField.Value;
            app.xlim_(2) = value;
            app.init_response_axes_();
        end

        % Value changed function: YMinEditField
        function YMinEditFieldValueChanged(app, event)
            value = app.YMinEditField.Value;
            app.ylim_(1) = value;
            app.init_response_axes_();
        end

        % Value changed function: YMaxEditField
        function YMaxEditFieldValueChanged(app, event)
            value = app.YMaxEditField.Value;
            app.ylim_(2) = value;
            app.init_response_axes_();
        end

        % Button pushed function: CreateOptionButton
        function CreateOptionButtonPushed(app, event)
            %CREATEOPTIONBUTTONPUSHED  Callback prompting user with inputdlg to create new pattern file with arbitrary name, in current app.pattern_dir_ folder.
            if strcmpi(app.StimulationOptionsListBox.Items(1), "pattern.txt")
                example_name = "Jsafety_25_x0um_y0um.txt";
            else
                example_name = string(app.StimulationOptionsListBox.Items{1});
            end
            fname = inputdlg(sprintf("New pattern (e.g. %s)", example_name), "Create pattern file", 1, example_name);
            if isempty(fname)
                return;
            else
                fname = string(fname{1});
            end
            filename = fullfile(app.patterns_dir_, fname);
            fid = fopen(filename, 'w');
            fprintf(fid,'# Dummy Pattern\n');
            fclose(fid);
            if isempty(app.pdata)
                try
                    app.pdata = parse_pattern_volume_string(fname);
                catch
                    warning("Invalid pattern name. Must use convention in example.");
                    return;
                end
                opts = fname;
            else
                try
                    app.pdata = [ parse_pattern_volume_string(fname); app.pdata];
                catch
                    warning("Invalid pattern name. Must use convention in example.");
                    return;
                end
                opts = [char(fname), app.StimulationOptionsListBox.Items];
            end
            set(app.StimulationOptionsListBox, 'Items', opts, 'ItemsData', 1:numel(opts), 'Value', 1);
        end

        % Button pushed function: ImportGridSubsetButton
        function ImportGridSubsetButtonPushed(app, event)
            selpath = uigetdir(fullfile(pwd, 'patterns'), ...
                "Select folder containing pattern stim-pattern options.");
            if selpath == 0
                return;
            else
                app.patterns_dir_ = string(selpath);
                app.parse_stim_txt_files(app.patterns_dir_, ...
                    app.DeltaXEditField.Value, app.DeltaYEditField.Value);
            end
        end

        % Button pushed function: ExportCurrentPatternsButton
        function ExportCurrentPatternsButtonPushed(app, event)
            outdir = app.ExportFolderEditField.Value;
            if exist(outdir, 'dir') == 0
                mkdir(outdir);
            end
            for ii = 1:numel(app.pdata)
                copyfile(fullfile(app.patterns_dir_, app.pdata(ii).name), outdir);
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
            app.UIFigure.Color = [0 0 0];
            app.UIFigure.Position = [100 100 720 540];
            app.UIFigure.Name = 'Online Patch Stim/Response Interface';
            app.UIFigure.Icon = fullfile(pathToMLAPP, 'brain_stim_00.jpg');

            % Create MainGridLayout
            app.MainGridLayout = uigridlayout(app.UIFigure);
            app.MainGridLayout.ColumnWidth = {'2x', '2x', '3x', '2x', '1x'};
            app.MainGridLayout.RowHeight = {'1x', '19x'};
            app.MainGridLayout.Padding = [0.5 10 0.5 10];
            app.MainGridLayout.BackgroundColor = [0 0 0];

            % Create TabGroup
            app.TabGroup = uitabgroup(app.MainGridLayout);
            app.TabGroup.Layout.Row = 2;
            app.TabGroup.Layout.Column = [1 5];

            % Create StimTab
            app.StimTab = uitab(app.TabGroup);
            app.StimTab.Title = 'Stimulation';
            app.StimTab.BackgroundColor = [1 1 1];

            % Create StimGridLayout
            app.StimGridLayout = uigridlayout(app.StimTab);
            app.StimGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '4x', '4x', '3x', '1x'};
            app.StimGridLayout.RowHeight = {'1x', '4x', '1x', '4x', '1x', '2x', '2x', '2x', '2x'};
            app.StimGridLayout.BackgroundColor = [1 1 1];

            % Create StimulationControllerConnectButton
            app.StimulationControllerConnectButton = uibutton(app.StimGridLayout, 'push');
            app.StimulationControllerConnectButton.ButtonPushedFcn = createCallbackFcn(app, @StimulationControllerConnectButtonPushed, true);
            app.StimulationControllerConnectButton.Tag = 'stimulator';
            app.StimulationControllerConnectButton.FontName = 'Tahoma';
            app.StimulationControllerConnectButton.FontSize = 20;
            app.StimulationControllerConnectButton.FontWeight = 'bold';
            app.StimulationControllerConnectButton.Tooltip = {'Connect to the stimulation controller tcpserver.'};
            app.StimulationControllerConnectButton.Layout.Row = 8;
            app.StimulationControllerConnectButton.Layout.Column = 7;
            app.StimulationControllerConnectButton.Text = 'Connect';

            % Create StimulationControllerModeDropDownLabel
            app.StimulationControllerModeDropDownLabel = uilabel(app.StimGridLayout);
            app.StimulationControllerModeDropDownLabel.HorizontalAlignment = 'right';
            app.StimulationControllerModeDropDownLabel.FontName = 'Tahoma';
            app.StimulationControllerModeDropDownLabel.FontSize = 16;
            app.StimulationControllerModeDropDownLabel.Layout.Row = 7;
            app.StimulationControllerModeDropDownLabel.Layout.Column = [4 5];
            app.StimulationControllerModeDropDownLabel.Text = 'Stimulation Controller Mode';

            % Create StimulationControllerModeDropDown
            app.StimulationControllerModeDropDown = uidropdown(app.StimGridLayout);
            app.StimulationControllerModeDropDown.Items = {'Passive', 'Manual', 'Adaptive'};
            app.StimulationControllerModeDropDown.ValueChangedFcn = createCallbackFcn(app, @StimulationControllerModeDropDownValueChanged, true);
            app.StimulationControllerModeDropDown.FontName = 'Tahoma';
            app.StimulationControllerModeDropDown.FontSize = 16;
            app.StimulationControllerModeDropDown.Layout.Row = 7;
            app.StimulationControllerModeDropDown.Layout.Column = [6 8];
            app.StimulationControllerModeDropDown.Value = 'Passive';

            % Create StimulationOptionsListBox
            app.StimulationOptionsListBox = uilistbox(app.StimGridLayout);
            app.StimulationOptionsListBox.Items = {'Pattern.txt'};
            app.StimulationOptionsListBox.Multiselect = 'on';
            app.StimulationOptionsListBox.Enable = 'off';
            app.StimulationOptionsListBox.Tooltip = {'Stimulation pattern files which can be highlighted and added to the table by clicking the "Add Selected" pushbutton. Associated intensity amplitude is set in the edit field below. Can add multiple patterns at once.'};
            app.StimulationOptionsListBox.FontName = 'Tahoma';
            app.StimulationOptionsListBox.Layout.Row = [2 6];
            app.StimulationOptionsListBox.Layout.Column = [1 5];
            app.StimulationOptionsListBox.Value = {'Pattern.txt'};

            % Create ChooseOptionsButton
            app.ChooseOptionsButton = uibutton(app.StimGridLayout, 'push');
            app.ChooseOptionsButton.ButtonPushedFcn = createCallbackFcn(app, @ChooseOptionsButtonPushed, true);
            app.ChooseOptionsButton.FontName = 'Tahoma';
            app.ChooseOptionsButton.FontSize = 9;
            app.ChooseOptionsButton.Layout.Row = 1;
            app.ChooseOptionsButton.Layout.Column = [3 4];
            app.ChooseOptionsButton.Text = 'Choose Options...';

            % Create SelectedPatternsUITable
            app.SelectedPatternsUITable = uitable(app.StimGridLayout);
            app.SelectedPatternsUITable.ColumnName = {'Pattern'; 'Amplitude'};
            app.SelectedPatternsUITable.RowName = {};
            app.SelectedPatternsUITable.SelectionType = 'row';
            app.SelectedPatternsUITable.Tooltip = {'Patterns to be sent next to the stimulation controller.'};
            app.SelectedPatternsUITable.Visible = 'off';
            app.SelectedPatternsUITable.KeyPressFcn = createCallbackFcn(app, @PatternsUITableKeyPress, true);
            app.SelectedPatternsUITable.FontName = 'Tahoma';
            app.SelectedPatternsUITable.Layout.Row = [2 3];
            app.SelectedPatternsUITable.Layout.Column = [6 8];

            % Create SelectedPatternsUITableLabel
            app.SelectedPatternsUITableLabel = uilabel(app.StimGridLayout);
            app.SelectedPatternsUITableLabel.HorizontalAlignment = 'center';
            app.SelectedPatternsUITableLabel.FontName = 'Tahoma';
            app.SelectedPatternsUITableLabel.FontSize = 14;
            app.SelectedPatternsUITableLabel.FontWeight = 'bold';
            app.SelectedPatternsUITableLabel.Visible = 'off';
            app.SelectedPatternsUITableLabel.Layout.Row = 1;
            app.SelectedPatternsUITableLabel.Layout.Column = [6 8];
            app.SelectedPatternsUITableLabel.Text = 'To Send';

            % Create IntensityEditField
            app.IntensityEditField = uieditfield(app.StimGridLayout, 'numeric');
            app.IntensityEditField.Limits = [0 100];
            app.IntensityEditField.ValueChangedFcn = createCallbackFcn(app, @IntensityEditFieldValueChanged, true);
            app.IntensityEditField.HorizontalAlignment = 'center';
            app.IntensityEditField.FontName = 'Tahoma';
            app.IntensityEditField.FontSize = 16;
            app.IntensityEditField.Tooltip = {'Set the intensity value for the next-selected pattern'};
            app.IntensityEditField.Layout.Row = 9;
            app.IntensityEditField.Layout.Column = 3;

            % Create AddSelectedButton
            app.AddSelectedButton = uibutton(app.StimGridLayout, 'push');
            app.AddSelectedButton.ButtonPushedFcn = createCallbackFcn(app, @AddSelectedButtonPushed, true);
            app.AddSelectedButton.FontName = 'Tahoma';
            app.AddSelectedButton.FontSize = 9;
            app.AddSelectedButton.Enable = 'off';
            app.AddSelectedButton.Layout.Row = 1;
            app.AddSelectedButton.Layout.Column = 5;
            app.AddSelectedButton.Text = 'Add Selected';

            % Create RepetitionsEditField
            app.RepetitionsEditField = uieditfield(app.StimGridLayout, 'numeric');
            app.RepetitionsEditField.Limits = [1 100];
            app.RepetitionsEditField.RoundFractionalValues = 'on';
            app.RepetitionsEditField.HorizontalAlignment = 'center';
            app.RepetitionsEditField.FontName = 'Tahoma';
            app.RepetitionsEditField.FontSize = 16;
            app.RepetitionsEditField.Tooltip = {'Set the intensity value for the next-selected pattern'};
            app.RepetitionsEditField.Layout.Row = 8;
            app.RepetitionsEditField.Layout.Column = 3;
            app.RepetitionsEditField.Value = 1;

            % Create IntensityEditFieldLabel
            app.IntensityEditFieldLabel = uilabel(app.StimGridLayout);
            app.IntensityEditFieldLabel.HorizontalAlignment = 'center';
            app.IntensityEditFieldLabel.FontName = 'Tahoma';
            app.IntensityEditFieldLabel.FontWeight = 'bold';
            app.IntensityEditFieldLabel.Layout.Row = 9;
            app.IntensityEditFieldLabel.Layout.Column = [1 2];
            app.IntensityEditFieldLabel.Text = 'Intensity';

            % Create RepetitionsEditFieldLabel
            app.RepetitionsEditFieldLabel = uilabel(app.StimGridLayout);
            app.RepetitionsEditFieldLabel.HorizontalAlignment = 'center';
            app.RepetitionsEditFieldLabel.FontName = 'Tahoma';
            app.RepetitionsEditFieldLabel.FontWeight = 'bold';
            app.RepetitionsEditFieldLabel.Layout.Row = 8;
            app.RepetitionsEditFieldLabel.Layout.Column = [1 2];
            app.RepetitionsEditFieldLabel.Text = 'Repetitions';

            % Create QueuedPatternsUITable
            app.QueuedPatternsUITable = uitable(app.StimGridLayout);
            app.QueuedPatternsUITable.BackgroundColor = [0.502 0.502 0.502;0.651 0.651 0.651];
            app.QueuedPatternsUITable.ColumnName = {'Pattern'; 'Amplitude'};
            app.QueuedPatternsUITable.RowName = {};
            app.QueuedPatternsUITable.SelectionType = 'row';
            app.QueuedPatternsUITable.ColumnEditable = [false false];
            app.QueuedPatternsUITable.Tooltip = {'Patterns that have already been sent to the stimulation controller, but which have not yet seen a TTL pulse "ack".'};
            app.QueuedPatternsUITable.ForegroundColor = [1 1 1];
            app.QueuedPatternsUITable.KeyPressFcn = createCallbackFcn(app, @PatternsUITableKeyPress, true);
            app.QueuedPatternsUITable.FontName = 'Tahoma';
            app.QueuedPatternsUITable.Layout.Row = [4 5];
            app.QueuedPatternsUITable.Layout.Column = [6 8];

            % Create QueuedPatternsUITableLabel
            app.QueuedPatternsUITableLabel = uilabel(app.StimGridLayout);
            app.QueuedPatternsUITableLabel.HorizontalAlignment = 'center';
            app.QueuedPatternsUITableLabel.FontName = 'Tahoma';
            app.QueuedPatternsUITableLabel.FontSize = 14;
            app.QueuedPatternsUITableLabel.FontAngle = 'italic';
            app.QueuedPatternsUITableLabel.FontColor = [0.502 0.502 0.502];
            app.QueuedPatternsUITableLabel.Layout.Row = 6;
            app.QueuedPatternsUITableLabel.Layout.Column = [6 8];
            app.QueuedPatternsUITableLabel.Text = 'Received (Awaiting Response)';

            % Create StimulationControllerStatusLamp
            app.StimulationControllerStatusLamp = uilamp(app.StimGridLayout);
            app.StimulationControllerStatusLamp.Layout.Row = 8;
            app.StimulationControllerStatusLamp.Layout.Column = 8;
            app.StimulationControllerStatusLamp.Color = [0.902 0.902 0.902];

            % Create StimulationControllerPortEditFieldLabel
            app.StimulationControllerPortEditFieldLabel = uilabel(app.StimGridLayout);
            app.StimulationControllerPortEditFieldLabel.HorizontalAlignment = 'right';
            app.StimulationControllerPortEditFieldLabel.FontName = 'Tahoma';
            app.StimulationControllerPortEditFieldLabel.FontSize = 16;
            app.StimulationControllerPortEditFieldLabel.Layout.Row = 9;
            app.StimulationControllerPortEditFieldLabel.Layout.Column = [4 5];
            app.StimulationControllerPortEditFieldLabel.Text = 'Stimulation Controller Port';

            % Create StimulationControllerPortEditField
            app.StimulationControllerPortEditField = uieditfield(app.StimGridLayout, 'numeric');
            app.StimulationControllerPortEditField.Limits = [0 Inf];
            app.StimulationControllerPortEditField.RoundFractionalValues = 'on';
            app.StimulationControllerPortEditField.HorizontalAlignment = 'center';
            app.StimulationControllerPortEditField.FontName = 'Tahoma';
            app.StimulationControllerPortEditField.FontSize = 16;
            app.StimulationControllerPortEditField.Layout.Row = 9;
            app.StimulationControllerPortEditField.Layout.Column = 6;
            app.StimulationControllerPortEditField.Value = 6000;

            % Create StimulationControllerIPEditFieldLabel
            app.StimulationControllerIPEditFieldLabel = uilabel(app.StimGridLayout);
            app.StimulationControllerIPEditFieldLabel.HorizontalAlignment = 'right';
            app.StimulationControllerIPEditFieldLabel.FontName = 'Tahoma';
            app.StimulationControllerIPEditFieldLabel.FontSize = 16;
            app.StimulationControllerIPEditFieldLabel.Layout.Row = 8;
            app.StimulationControllerIPEditFieldLabel.Layout.Column = [4 5];
            app.StimulationControllerIPEditFieldLabel.Text = 'Stimulation Controller IP';

            % Create StimulationControllerIPEditField
            app.StimulationControllerIPEditField = uieditfield(app.StimGridLayout, 'text');
            app.StimulationControllerIPEditField.HorizontalAlignment = 'center';
            app.StimulationControllerIPEditField.FontName = 'Tahoma';
            app.StimulationControllerIPEditField.FontSize = 16;
            app.StimulationControllerIPEditField.Layout.Row = 8;
            app.StimulationControllerIPEditField.Layout.Column = 6;
            app.StimulationControllerIPEditField.Value = '172.26.21.247';

            % Create SendButton
            app.SendButton = uibutton(app.StimGridLayout, 'push');
            app.SendButton.ButtonPushedFcn = createCallbackFcn(app, @SendButtonPushed, true);
            app.SendButton.FontName = 'Tahoma';
            app.SendButton.FontSize = 16;
            app.SendButton.FontWeight = 'bold';
            app.SendButton.FontColor = [1 0 0];
            app.SendButton.Enable = 'off';
            app.SendButton.Tooltip = {'Send the next queued message (top of the table) to the stimulation controller.'};
            app.SendButton.Layout.Row = 9;
            app.SendButton.Layout.Column = [7 8];
            app.SendButton.Text = 'Send';

            % Create CreateOptionButton
            app.CreateOptionButton = uibutton(app.StimGridLayout, 'push');
            app.CreateOptionButton.ButtonPushedFcn = createCallbackFcn(app, @CreateOptionButtonPushed, true);
            app.CreateOptionButton.FontName = 'Tahoma';
            app.CreateOptionButton.FontSize = 9;
            app.CreateOptionButton.Layout.Row = 1;
            app.CreateOptionButton.Layout.Column = [1 2];
            app.CreateOptionButton.Text = 'Create Option...';

            % Create PatternsLoadedLabel
            app.PatternsLoadedLabel = uilabel(app.StimGridLayout);
            app.PatternsLoadedLabel.HorizontalAlignment = 'center';
            app.PatternsLoadedLabel.VerticalAlignment = 'top';
            app.PatternsLoadedLabel.FontName = 'Tahoma';
            app.PatternsLoadedLabel.FontWeight = 'bold';
            app.PatternsLoadedLabel.Layout.Row = 7;
            app.PatternsLoadedLabel.Layout.Column = [1 3];
            app.PatternsLoadedLabel.Text = '1 Pattern Loaded';

            % Create ResponseTab
            app.ResponseTab = uitab(app.TabGroup);
            app.ResponseTab.Title = 'Responses';
            app.ResponseTab.BackgroundColor = [1 1 1];

            % Create ResponseGridLayout
            app.ResponseGridLayout = uigridlayout(app.ResponseTab);
            app.ResponseGridLayout.ColumnWidth = {'3x', '2x', '2x', '2x', '3x', '1x'};
            app.ResponseGridLayout.RowHeight = {'2x', '3x', '5x', '5x', '5x', '5x', '5x', '5x', '2x'};
            app.ResponseGridLayout.BackgroundColor = [1 1 1];

            % Create ResponseUIAxes
            app.ResponseUIAxes = uiaxes(app.ResponseGridLayout);
            title(app.ResponseUIAxes, 'Responses')
            xlabel(app.ResponseUIAxes, 'ML (μm)')
            ylabel(app.ResponseUIAxes, 'AP (μm)')
            zlabel(app.ResponseUIAxes, 'Z')
            app.ResponseUIAxes.Toolbar.Visible = 'off';
            app.ResponseUIAxes.FontName = 'Tahoma';
            app.ResponseUIAxes.XLim = [-6500 6500];
            app.ResponseUIAxes.YLim = [-2000 2000];
            app.ResponseUIAxes.NextPlot = 'add';
            app.ResponseUIAxes.Layout.Row = [3 8];
            app.ResponseUIAxes.Layout.Column = [1 6];

            % Create ResponseSAGAFilterDropDown
            app.ResponseSAGAFilterDropDown = uidropdown(app.ResponseGridLayout);
            app.ResponseSAGAFilterDropDown.Items = {'SAGA-A', 'SAGA-B'};
            app.ResponseSAGAFilterDropDown.ItemsData = {'A', 'B'};
            app.ResponseSAGAFilterDropDown.ValueChangedFcn = createCallbackFcn(app, @ResponseFilterValueChanged, true);
            app.ResponseSAGAFilterDropDown.FontName = 'Tahoma';
            app.ResponseSAGAFilterDropDown.Layout.Row = 2;
            app.ResponseSAGAFilterDropDown.Layout.Column = 1;
            app.ResponseSAGAFilterDropDown.Value = 'A';

            % Create ResponseChannelFilterEditField
            app.ResponseChannelFilterEditField = uieditfield(app.ResponseGridLayout, 'numeric');
            app.ResponseChannelFilterEditField.Limits = [1 68];
            app.ResponseChannelFilterEditField.RoundFractionalValues = 'on';
            app.ResponseChannelFilterEditField.ValueChangedFcn = createCallbackFcn(app, @ResponseFilterValueChanged, true);
            app.ResponseChannelFilterEditField.HorizontalAlignment = 'center';
            app.ResponseChannelFilterEditField.FontName = 'Tahoma';
            app.ResponseChannelFilterEditField.Tooltip = {'Filter for channel responses to be displayed. Bipolar channels are indices 65-68.'};
            app.ResponseChannelFilterEditField.Layout.Row = 2;
            app.ResponseChannelFilterEditField.Layout.Column = [2 3];
            app.ResponseChannelFilterEditField.Value = 10;

            % Create ResponseAmplitudeFilterEditField
            app.ResponseAmplitudeFilterEditField = uieditfield(app.ResponseGridLayout, 'numeric');
            app.ResponseAmplitudeFilterEditField.Limits = [0 100];
            app.ResponseAmplitudeFilterEditField.ValueChangedFcn = createCallbackFcn(app, @ResponseFilterValueChanged, true);
            app.ResponseAmplitudeFilterEditField.HorizontalAlignment = 'center';
            app.ResponseAmplitudeFilterEditField.FontName = 'Tahoma';
            app.ResponseAmplitudeFilterEditField.Tooltip = {'Filter for stimulus intensity used to generate responses (to be displayed).'};
            app.ResponseAmplitudeFilterEditField.Layout.Row = 2;
            app.ResponseAmplitudeFilterEditField.Layout.Column = 4;

            % Create ResponseChannelFilterEditFieldLabel
            app.ResponseChannelFilterEditFieldLabel = uilabel(app.ResponseGridLayout);
            app.ResponseChannelFilterEditFieldLabel.HorizontalAlignment = 'center';
            app.ResponseChannelFilterEditFieldLabel.FontName = 'Tahoma';
            app.ResponseChannelFilterEditFieldLabel.FontSize = 8;
            app.ResponseChannelFilterEditFieldLabel.Layout.Row = 1;
            app.ResponseChannelFilterEditFieldLabel.Layout.Column = [2 3];
            app.ResponseChannelFilterEditFieldLabel.Text = 'Channel Filter';

            % Create ResponseSAGAFilterDropDownLabel
            app.ResponseSAGAFilterDropDownLabel = uilabel(app.ResponseGridLayout);
            app.ResponseSAGAFilterDropDownLabel.HorizontalAlignment = 'center';
            app.ResponseSAGAFilterDropDownLabel.FontName = 'Tahoma';
            app.ResponseSAGAFilterDropDownLabel.FontSize = 8;
            app.ResponseSAGAFilterDropDownLabel.Layout.Row = 1;
            app.ResponseSAGAFilterDropDownLabel.Layout.Column = 1;
            app.ResponseSAGAFilterDropDownLabel.Text = 'SAGA Filter';

            % Create ResponseAmplitudeFilterEditFieldLabel
            app.ResponseAmplitudeFilterEditFieldLabel = uilabel(app.ResponseGridLayout);
            app.ResponseAmplitudeFilterEditFieldLabel.HorizontalAlignment = 'center';
            app.ResponseAmplitudeFilterEditFieldLabel.FontName = 'Tahoma';
            app.ResponseAmplitudeFilterEditFieldLabel.FontSize = 8;
            app.ResponseAmplitudeFilterEditFieldLabel.Layout.Row = 1;
            app.ResponseAmplitudeFilterEditFieldLabel.Layout.Column = 4;
            app.ResponseAmplitudeFilterEditFieldLabel.Text = 'Intensity Filter';

            % Create ResponseSweepFilterEditField
            app.ResponseSweepFilterEditField = uieditfield(app.ResponseGridLayout, 'text');
            app.ResponseSweepFilterEditField.ValueChangedFcn = createCallbackFcn(app, @ResponseFilterValueChanged, true);
            app.ResponseSweepFilterEditField.HorizontalAlignment = 'center';
            app.ResponseSweepFilterEditField.FontName = 'Tahoma';
            app.ResponseSweepFilterEditField.Tooltip = {'Name of the "sweep" (first-two ''_''-delimited groupings in .txt filenames).'};
            app.ResponseSweepFilterEditField.Layout.Row = 2;
            app.ResponseSweepFilterEditField.Layout.Column = 5;
            app.ResponseSweepFilterEditField.Value = 'Jsafety_25';

            % Create ResponseSweepFilterEditFieldLabel
            app.ResponseSweepFilterEditFieldLabel = uilabel(app.ResponseGridLayout);
            app.ResponseSweepFilterEditFieldLabel.HorizontalAlignment = 'center';
            app.ResponseSweepFilterEditFieldLabel.FontName = 'Tahoma';
            app.ResponseSweepFilterEditFieldLabel.FontSize = 8;
            app.ResponseSweepFilterEditFieldLabel.Layout.Row = 1;
            app.ResponseSweepFilterEditFieldLabel.Layout.Column = 5;
            app.ResponseSweepFilterEditFieldLabel.Text = 'Sweep Filter';

            % Create CLimEditFieldLabel
            app.CLimEditFieldLabel = uilabel(app.ResponseGridLayout);
            app.CLimEditFieldLabel.HorizontalAlignment = 'center';
            app.CLimEditFieldLabel.FontName = 'Tahoma';
            app.CLimEditFieldLabel.FontSize = 8;
            app.CLimEditFieldLabel.Layout.Row = 1;
            app.CLimEditFieldLabel.Layout.Column = 6;
            app.CLimEditFieldLabel.Text = 'CLim';

            % Create CLimEditField
            app.CLimEditField = uieditfield(app.ResponseGridLayout, 'numeric');
            app.CLimEditField.Limits = [0 Inf];
            app.CLimEditField.ValueDisplayFormat = '%4.2g';
            app.CLimEditField.ValueChangedFcn = createCallbackFcn(app, @CLimEditFieldValueChanged, true);
            app.CLimEditField.HorizontalAlignment = 'center';
            app.CLimEditField.FontName = 'Tahoma';
            app.CLimEditField.Tooltip = {'Change the upper-bound of the Color Limits for determining how the colormap is interpolated based on response values.'};
            app.CLimEditField.Layout.Row = 2;
            app.CLimEditField.Layout.Column = 6;
            app.CLimEditField.Value = 10;

            % Create RefreshButton
            app.RefreshButton = uibutton(app.ResponseGridLayout, 'push');
            app.RefreshButton.ButtonPushedFcn = createCallbackFcn(app, @RefreshButtonPushed, true);
            app.RefreshButton.BackgroundColor = [1 0 0];
            app.RefreshButton.FontName = 'Tahoma';
            app.RefreshButton.FontSize = 8;
            app.RefreshButton.FontWeight = 'bold';
            app.RefreshButton.FontColor = [1 1 1];
            app.RefreshButton.Layout.Row = 9;
            app.RefreshButton.Layout.Column = 1;
            app.RefreshButton.Text = 'Refresh';

            % Create StimCountLabel
            app.StimCountLabel = uilabel(app.ResponseGridLayout);
            app.StimCountLabel.HorizontalAlignment = 'right';
            app.StimCountLabel.FontName = 'Tahoma';
            app.StimCountLabel.FontWeight = 'bold';
            app.StimCountLabel.Layout.Row = 9;
            app.StimCountLabel.Layout.Column = 5;
            app.StimCountLabel.Text = 'N = 0';

            % Create ConfigureTab
            app.ConfigureTab = uitab(app.TabGroup);
            app.ConfigureTab.Title = 'Configure';

            % Create ConfigureGridLayout
            app.ConfigureGridLayout = uigridlayout(app.ConfigureTab);
            app.ConfigureGridLayout.ColumnWidth = {'3x', '2x', '3x', '2x', '3x', '2x'};
            app.ConfigureGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.ConfigureGridLayout.BackgroundColor = [1 1 1];

            % Create XMinmEditFieldLabel
            app.XMinmEditFieldLabel = uilabel(app.ConfigureGridLayout);
            app.XMinmEditFieldLabel.HorizontalAlignment = 'right';
            app.XMinmEditFieldLabel.FontName = 'Tahoma';
            app.XMinmEditFieldLabel.FontSize = 16;
            app.XMinmEditFieldLabel.Layout.Row = 4;
            app.XMinmEditFieldLabel.Layout.Column = 1;
            app.XMinmEditFieldLabel.Text = 'X-Min (μm)';

            % Create XMinEditField
            app.XMinEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.XMinEditField.ValueChangedFcn = createCallbackFcn(app, @XMinEditFieldValueChanged, true);
            app.XMinEditField.HorizontalAlignment = 'center';
            app.XMinEditField.FontName = 'Tahoma';
            app.XMinEditField.FontSize = 16;
            app.XMinEditField.Layout.Row = 4;
            app.XMinEditField.Layout.Column = 2;
            app.XMinEditField.Value = -6500;

            % Create XMaxmEditFieldLabel
            app.XMaxmEditFieldLabel = uilabel(app.ConfigureGridLayout);
            app.XMaxmEditFieldLabel.HorizontalAlignment = 'right';
            app.XMaxmEditFieldLabel.FontName = 'Tahoma';
            app.XMaxmEditFieldLabel.FontSize = 16;
            app.XMaxmEditFieldLabel.Layout.Row = 4;
            app.XMaxmEditFieldLabel.Layout.Column = 5;
            app.XMaxmEditFieldLabel.Text = 'X-Max (μm)';

            % Create XMaxEditField
            app.XMaxEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.XMaxEditField.ValueChangedFcn = createCallbackFcn(app, @XMaxEditFieldValueChanged, true);
            app.XMaxEditField.HorizontalAlignment = 'center';
            app.XMaxEditField.FontName = 'Tahoma';
            app.XMaxEditField.FontSize = 16;
            app.XMaxEditField.Layout.Row = 4;
            app.XMaxEditField.Layout.Column = 6;
            app.XMaxEditField.Value = 6500;

            % Create YMinmEditFieldLabel
            app.YMinmEditFieldLabel = uilabel(app.ConfigureGridLayout);
            app.YMinmEditFieldLabel.HorizontalAlignment = 'right';
            app.YMinmEditFieldLabel.FontName = 'Tahoma';
            app.YMinmEditFieldLabel.FontSize = 16;
            app.YMinmEditFieldLabel.Layout.Row = 5;
            app.YMinmEditFieldLabel.Layout.Column = 1;
            app.YMinmEditFieldLabel.Text = 'Y-Min (μm)';

            % Create YMinEditField
            app.YMinEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.YMinEditField.ValueChangedFcn = createCallbackFcn(app, @YMinEditFieldValueChanged, true);
            app.YMinEditField.HorizontalAlignment = 'center';
            app.YMinEditField.FontName = 'Tahoma';
            app.YMinEditField.FontSize = 16;
            app.YMinEditField.Layout.Row = 5;
            app.YMinEditField.Layout.Column = 2;
            app.YMinEditField.Value = -2500;

            % Create YMaxmEditFieldLabel
            app.YMaxmEditFieldLabel = uilabel(app.ConfigureGridLayout);
            app.YMaxmEditFieldLabel.HorizontalAlignment = 'right';
            app.YMaxmEditFieldLabel.FontName = 'Tahoma';
            app.YMaxmEditFieldLabel.FontSize = 16;
            app.YMaxmEditFieldLabel.Layout.Row = 5;
            app.YMaxmEditFieldLabel.Layout.Column = 5;
            app.YMaxmEditFieldLabel.Text = 'Y-Max (μm)';

            % Create YMaxEditField
            app.YMaxEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.YMaxEditField.ValueChangedFcn = createCallbackFcn(app, @YMaxEditFieldValueChanged, true);
            app.YMaxEditField.HorizontalAlignment = 'center';
            app.YMaxEditField.FontName = 'Tahoma';
            app.YMaxEditField.FontSize = 16;
            app.YMaxEditField.Layout.Row = 5;
            app.YMaxEditField.Layout.Column = 6;
            app.YMaxEditField.Value = 2500;

            % Create XmLabel
            app.XmLabel = uilabel(app.ConfigureGridLayout);
            app.XmLabel.HorizontalAlignment = 'right';
            app.XmLabel.FontName = 'Tahoma';
            app.XmLabel.FontSize = 16;
            app.XmLabel.FontColor = [0.502 0.502 0.502];
            app.XmLabel.Layout.Row = 4;
            app.XmLabel.Layout.Column = 3;
            app.XmLabel.Text = 'ΔX (μm)';

            % Create DeltaXEditField
            app.DeltaXEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.DeltaXEditField.Limits = [1 Inf];
            app.DeltaXEditField.HorizontalAlignment = 'center';
            app.DeltaXEditField.FontName = 'Tahoma';
            app.DeltaXEditField.FontSize = 16;
            app.DeltaXEditField.FontColor = [0.502 0.502 0.502];
            app.DeltaXEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DeltaXEditField.Layout.Row = 4;
            app.DeltaXEditField.Layout.Column = 4;
            app.DeltaXEditField.Value = 500;

            % Create XmLabel_2
            app.XmLabel_2 = uilabel(app.ConfigureGridLayout);
            app.XmLabel_2.HorizontalAlignment = 'right';
            app.XmLabel_2.FontName = 'Tahoma';
            app.XmLabel_2.FontSize = 16;
            app.XmLabel_2.FontColor = [0.502 0.502 0.502];
            app.XmLabel_2.Layout.Row = 5;
            app.XmLabel_2.Layout.Column = 3;
            app.XmLabel_2.Text = 'ΔY (μm)';

            % Create DeltaYEditField
            app.DeltaYEditField = uieditfield(app.ConfigureGridLayout, 'numeric');
            app.DeltaYEditField.Limits = [1 Inf];
            app.DeltaYEditField.HorizontalAlignment = 'center';
            app.DeltaYEditField.FontName = 'Tahoma';
            app.DeltaYEditField.FontSize = 16;
            app.DeltaYEditField.FontColor = [0.502 0.502 0.502];
            app.DeltaYEditField.BackgroundColor = [0.9412 0.9412 0.9412];
            app.DeltaYEditField.Layout.Row = 5;
            app.DeltaYEditField.Layout.Column = 4;
            app.DeltaYEditField.Value = 500;

            % Create ImportGridSubsetButton
            app.ImportGridSubsetButton = uibutton(app.ConfigureGridLayout, 'push');
            app.ImportGridSubsetButton.ButtonPushedFcn = createCallbackFcn(app, @ImportGridSubsetButtonPushed, true);
            app.ImportGridSubsetButton.Icon = fullfile(pathToMLAPP, 'baseline_file_upload_black_24dp.png');
            app.ImportGridSubsetButton.FontName = 'Tahoma';
            app.ImportGridSubsetButton.FontSize = 14;
            app.ImportGridSubsetButton.FontWeight = 'bold';
            app.ImportGridSubsetButton.Layout.Row = 6;
            app.ImportGridSubsetButton.Layout.Column = [1 6];
            app.ImportGridSubsetButton.Text = 'Import Grid Subset';

            % Create ExportFolderEditFieldLabel
            app.ExportFolderEditFieldLabel = uilabel(app.ConfigureGridLayout);
            app.ExportFolderEditFieldLabel.HorizontalAlignment = 'right';
            app.ExportFolderEditFieldLabel.FontName = 'Tahoma';
            app.ExportFolderEditFieldLabel.FontSize = 16;
            app.ExportFolderEditFieldLabel.Layout.Row = 7;
            app.ExportFolderEditFieldLabel.Layout.Column = 1;
            app.ExportFolderEditFieldLabel.Text = 'Export Folder';

            % Create ExportFolderEditField
            app.ExportFolderEditField = uieditfield(app.ConfigureGridLayout, 'text');
            app.ExportFolderEditField.FontSize = 16;
            app.ExportFolderEditField.Layout.Row = 7;
            app.ExportFolderEditField.Layout.Column = [2 6];

            % Create ExportCurrentPatternsButton
            app.ExportCurrentPatternsButton = uibutton(app.ConfigureGridLayout, 'push');
            app.ExportCurrentPatternsButton.ButtonPushedFcn = createCallbackFcn(app, @ExportCurrentPatternsButtonPushed, true);
            app.ExportCurrentPatternsButton.Icon = fullfile(pathToMLAPP, 'baseline_save_black_24dp.png');
            app.ExportCurrentPatternsButton.FontName = 'Tahoma';
            app.ExportCurrentPatternsButton.FontSize = 14;
            app.ExportCurrentPatternsButton.FontWeight = 'bold';
            app.ExportCurrentPatternsButton.Layout.Row = 8;
            app.ExportCurrentPatternsButton.Layout.Column = [1 6];
            app.ExportCurrentPatternsButton.Text = 'Export Current Patterns';

            % Create XLabel
            app.XLabel = uilabel(app.MainGridLayout);
            app.XLabel.FontName = 'Tahoma';
            app.XLabel.FontWeight = 'bold';
            app.XLabel.FontColor = [1 1 1];
            app.XLabel.Layout.Row = 1;
            app.XLabel.Layout.Column = 1;
            app.XLabel.Text = 'X: 0 μm';

            % Create YLabel
            app.YLabel = uilabel(app.MainGridLayout);
            app.YLabel.FontName = 'Tahoma';
            app.YLabel.FontWeight = 'bold';
            app.YLabel.FontColor = [1 1 1];
            app.YLabel.Layout.Row = 1;
            app.YLabel.Layout.Column = 2;
            app.YLabel.Text = 'Y: 0 μm';

            % Create IntensityLabel
            app.IntensityLabel = uilabel(app.MainGridLayout);
            app.IntensityLabel.FontName = 'Tahoma';
            app.IntensityLabel.FontWeight = 'bold';
            app.IntensityLabel.FontColor = [1 1 1];
            app.IntensityLabel.Layout.Row = 1;
            app.IntensityLabel.Layout.Column = 3;
            app.IntensityLabel.Text = 'Intensity: 0%';

            % Create ResponsesOnlineStatusLampLabel
            app.ResponsesOnlineStatusLampLabel = uilabel(app.MainGridLayout);
            app.ResponsesOnlineStatusLampLabel.HorizontalAlignment = 'right';
            app.ResponsesOnlineStatusLampLabel.FontName = 'Tahoma';
            app.ResponsesOnlineStatusLampLabel.FontColor = [1 1 1];
            app.ResponsesOnlineStatusLampLabel.Layout.Row = 1;
            app.ResponsesOnlineStatusLampLabel.Layout.Column = 4;
            app.ResponsesOnlineStatusLampLabel.Text = 'Responses Online';

            % Create ResponsesOnlineStatusLamp
            app.ResponsesOnlineStatusLamp = uilamp(app.MainGridLayout);
            app.ResponsesOnlineStatusLamp.Layout.Row = 1;
            app.ResponsesOnlineStatusLamp.Layout.Column = 5;
            app.ResponsesOnlineStatusLamp.Color = [0.8 0.8 0.8];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = N3_Online_Stim(varargin)

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