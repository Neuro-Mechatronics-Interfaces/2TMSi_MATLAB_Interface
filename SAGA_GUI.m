classdef SAGA_GUI < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        SAGADataViewerUIFigure          matlab.ui.Figure
        TriggerChannelEditField         matlab.ui.control.NumericEditField
        TriggerChannelEditFieldLabel    matlab.ui.control.Label
        TriggerSyncBitEditField         matlab.ui.control.NumericEditField
        TriggerSyncBitEditFieldLabel    matlab.ui.control.Label
        DateTimeLabel                   matlab.ui.control.Label
        SAGALabel                       matlab.ui.control.Label
        TabGroup                        matlab.ui.container.TabGroup
        UnipolarStreamTab               matlab.ui.container.Tab
        UnipolarStreamGridLayout        matlab.ui.container.GridLayout
        UnipolarStreamSettingsPanel     matlab.ui.container.Panel
        UnipolarCARCheckBox             matlab.ui.control.CheckBox
        UnipolarCutoff2EditField        matlab.ui.control.NumericEditField
        Cutoff2HzEditFieldLabel         matlab.ui.control.Label
        UnipolarCutoff1EditField        matlab.ui.control.NumericEditField
        Cutoff1HzEditFieldLabel         matlab.ui.control.Label
        UnipolarFilterCheckBox          matlab.ui.control.CheckBox
        UnipolarPerChannelOffsetEditField  matlab.ui.control.NumericEditField
        PerChannelOffsetVEditFieldLabel  matlab.ui.control.Label
        ToggleAllUnipolarChannelsSwitch  matlab.ui.control.ToggleSwitch
        AllChannelsSwitchLabel          matlab.ui.control.Label
        UnipolarStreamChannelsPanel     matlab.ui.container.Panel
        UNI64SwitchLabel                matlab.ui.control.Label
        UNI64Switch                     matlab.ui.control.Switch
        UNI63SwitchLabel                matlab.ui.control.Label
        UNI63Switch                     matlab.ui.control.Switch
        UNI62SwitchLabel                matlab.ui.control.Label
        UNI62Switch                     matlab.ui.control.Switch
        UNI61SwitchLabel                matlab.ui.control.Label
        UNI61Switch                     matlab.ui.control.Switch
        UNI60SwitchLabel                matlab.ui.control.Label
        UNI60Switch                     matlab.ui.control.Switch
        UNI59SwitchLabel                matlab.ui.control.Label
        UNI59Switch                     matlab.ui.control.Switch
        UNI58SwitchLabel                matlab.ui.control.Label
        UNI58Switch                     matlab.ui.control.Switch
        UNI57SwitchLabel                matlab.ui.control.Label
        UNI57Switch                     matlab.ui.control.Switch
        UNI56SwitchLabel                matlab.ui.control.Label
        UNI56Switch                     matlab.ui.control.Switch
        UNI55SwitchLabel                matlab.ui.control.Label
        UNI55Switch                     matlab.ui.control.Switch
        UNI54SwitchLabel                matlab.ui.control.Label
        UNI54Switch                     matlab.ui.control.Switch
        UNI53SwitchLabel                matlab.ui.control.Label
        UNI53Switch                     matlab.ui.control.Switch
        UNI52SwitchLabel                matlab.ui.control.Label
        UNI52Switch                     matlab.ui.control.Switch
        UNI51SwitchLabel                matlab.ui.control.Label
        UNI51Switch                     matlab.ui.control.Switch
        UNI50SwitchLabel                matlab.ui.control.Label
        UNI50Switch                     matlab.ui.control.Switch
        UNI49SwitchLabel                matlab.ui.control.Label
        UNI49Switch                     matlab.ui.control.Switch
        UNI48SwitchLabel                matlab.ui.control.Label
        UNI48Switch                     matlab.ui.control.Switch
        UNI47SwitchLabel                matlab.ui.control.Label
        UNI47Switch                     matlab.ui.control.Switch
        UNI46SwitchLabel                matlab.ui.control.Label
        UNI46Switch                     matlab.ui.control.Switch
        UNI45SwitchLabel                matlab.ui.control.Label
        UNI45Switch                     matlab.ui.control.Switch
        UNI44SwitchLabel                matlab.ui.control.Label
        UNI44Switch                     matlab.ui.control.Switch
        UNI43SwitchLabel                matlab.ui.control.Label
        UNI43Switch                     matlab.ui.control.Switch
        UNI42SwitchLabel                matlab.ui.control.Label
        UNI42Switch                     matlab.ui.control.Switch
        UNI41SwitchLabel                matlab.ui.control.Label
        UNI41Switch                     matlab.ui.control.Switch
        UNI40SwitchLabel                matlab.ui.control.Label
        UNI40Switch                     matlab.ui.control.Switch
        UNI39SwitchLabel                matlab.ui.control.Label
        UNI39Switch                     matlab.ui.control.Switch
        UNI38SwitchLabel                matlab.ui.control.Label
        UNI38Switch                     matlab.ui.control.Switch
        UNI37SwitchLabel                matlab.ui.control.Label
        UNI37Switch                     matlab.ui.control.Switch
        UNI36SwitchLabel                matlab.ui.control.Label
        UNI36Switch                     matlab.ui.control.Switch
        UNI35SwitchLabel                matlab.ui.control.Label
        UNI35Switch                     matlab.ui.control.Switch
        UNI34SwitchLabel                matlab.ui.control.Label
        UNI34Switch                     matlab.ui.control.Switch
        UNI33SwitchLabel                matlab.ui.control.Label
        UNI33Switch                     matlab.ui.control.Switch
        UNI32SwitchLabel                matlab.ui.control.Label
        UNI32Switch                     matlab.ui.control.Switch
        UNI31SwitchLabel                matlab.ui.control.Label
        UNI31Switch                     matlab.ui.control.Switch
        UNI30SwitchLabel                matlab.ui.control.Label
        UNI30Switch                     matlab.ui.control.Switch
        UNI29SwitchLabel                matlab.ui.control.Label
        UNI29Switch                     matlab.ui.control.Switch
        UNI28SwitchLabel                matlab.ui.control.Label
        UNI28Switch                     matlab.ui.control.Switch
        UNI27SwitchLabel                matlab.ui.control.Label
        UNI27Switch                     matlab.ui.control.Switch
        UNI26SwitchLabel                matlab.ui.control.Label
        UNI26Switch                     matlab.ui.control.Switch
        UNI25SwitchLabel                matlab.ui.control.Label
        UNI25Switch                     matlab.ui.control.Switch
        UNI24SwitchLabel                matlab.ui.control.Label
        UNI24Switch                     matlab.ui.control.Switch
        UNI23SwitchLabel                matlab.ui.control.Label
        UNI23Switch                     matlab.ui.control.Switch
        UNI22SwitchLabel                matlab.ui.control.Label
        UNI22Switch                     matlab.ui.control.Switch
        UNI21SwitchLabel                matlab.ui.control.Label
        UNI21Switch                     matlab.ui.control.Switch
        UNI20SwitchLabel                matlab.ui.control.Label
        UNI20Switch                     matlab.ui.control.Switch
        UNI19SwitchLabel                matlab.ui.control.Label
        UNI19Switch                     matlab.ui.control.Switch
        UNI18SwitchLabel                matlab.ui.control.Label
        UNI18Switch                     matlab.ui.control.Switch
        UNI17SwitchLabel                matlab.ui.control.Label
        UNI17Switch                     matlab.ui.control.Switch
        UNI16SwitchLabel                matlab.ui.control.Label
        UNI16Switch                     matlab.ui.control.Switch
        UNI15SwitchLabel                matlab.ui.control.Label
        UNI15Switch                     matlab.ui.control.Switch
        UNI14SwitchLabel                matlab.ui.control.Label
        UNI14Switch                     matlab.ui.control.Switch
        UNI13SwitchLabel                matlab.ui.control.Label
        UNI13Switch                     matlab.ui.control.Switch
        UNI12SwitchLabel                matlab.ui.control.Label
        UNI12Switch                     matlab.ui.control.Switch
        UNI11SwitchLabel                matlab.ui.control.Label
        UNI11Switch                     matlab.ui.control.Switch
        UNI10SwitchLabel                matlab.ui.control.Label
        UNI10Switch                     matlab.ui.control.Switch
        UNI09SwitchLabel                matlab.ui.control.Label
        UNI09Switch                     matlab.ui.control.Switch
        UNI08SwitchLabel                matlab.ui.control.Label
        UNI08Switch                     matlab.ui.control.Switch
        UNI07SwitchLabel                matlab.ui.control.Label
        UNI07Switch                     matlab.ui.control.Switch
        UNI06SwitchLabel                matlab.ui.control.Label
        UNI06Switch                     matlab.ui.control.Switch
        UNI05SwitchLabel                matlab.ui.control.Label
        UNI05Switch                     matlab.ui.control.Switch
        UNI04SwitchLabel                matlab.ui.control.Label
        UNI04Switch                     matlab.ui.control.Switch
        UNI03SwitchLabel                matlab.ui.control.Label
        UNI03Switch                     matlab.ui.control.Switch
        UNI02SwitchLabel                matlab.ui.control.Label
        UNI02Switch                     matlab.ui.control.Switch
        UNI01Switch                     matlab.ui.control.Switch
        UNI01SwitchLabel                matlab.ui.control.Label
        UnipolarUIAxes                  matlab.ui.control.UIAxes
        UnipolarAverageTab              matlab.ui.container.Tab
        UnipolarAverageGridLayout       matlab.ui.container.GridLayout
        UnipolarAverageSettingsPanel    matlab.ui.container.Panel
        UnipolarAverageRectifyCheckBox  matlab.ui.control.CheckBox
        ResetUnipolarAverageButton      matlab.ui.control.Button
        UnipolarAverageNEditField       matlab.ui.control.NumericEditField
        NEditFieldLabel                 matlab.ui.control.Label
        StopUnipolarAverageSpinner      matlab.ui.control.Spinner
        StopDatamsSpinnerLabel          matlab.ui.control.Label
        StartUnipolarAverageSpinner     matlab.ui.control.Spinner
        StartDatamsSpinnerLabel         matlab.ui.control.Label
        UnipolarAverageCARCheckBox      matlab.ui.control.CheckBox
        UnipolarAverageCutoff2EditField  matlab.ui.control.NumericEditField
        Cutoff2HzEditFieldLabel_2       matlab.ui.control.Label
        UnipolarAverageCutoff1EditField  matlab.ui.control.NumericEditField
        Cutoff1HzEditFieldLabel_2       matlab.ui.control.Label
        UnipolarAverageFilterCheckBox   matlab.ui.control.CheckBox
        UnipolarAverageChannelEditField  matlab.ui.control.NumericEditField
        UNIChannelEditFieldLabel        matlab.ui.control.Label
        UnipolarAverageUIAxes           matlab.ui.control.UIAxes
        UnipolarRasterTab               matlab.ui.container.Tab
        UnipolarRasterGridLayout        matlab.ui.container.GridLayout
        UnipolarRasterSettingsPanel     matlab.ui.container.Panel
        BipolarStreamTab                matlab.ui.container.Tab
        BipolarStreamGridLayout         matlab.ui.container.GridLayout
        BipolarStreamSettingsPanel      matlab.ui.container.Panel
        BipolarCutoff2EditField         matlab.ui.control.NumericEditField
        BipolarCutoff2EditFieldLabel    matlab.ui.control.Label
        BipolarCutoff1EditField         matlab.ui.control.NumericEditField
        BipolarCutoff1EditFieldLabel    matlab.ui.control.Label
        BipolarPerChannelOffsetEditField  matlab.ui.control.NumericEditField
        BipolarPerChannelOffsetVEditFieldLabel  matlab.ui.control.Label
        BipolarFilterCheckBox           matlab.ui.control.CheckBox
        ToggleAllBipolarChannelsSwitch  matlab.ui.control.ToggleSwitch
        ToggleAllBipolarChannelsSwitchLabel  matlab.ui.control.Label
        BipolarStreamChannelsPanel      matlab.ui.container.Panel
        BIP04SwitchLabel                matlab.ui.control.Label
        BIP04Switch                     matlab.ui.control.Switch
        BIP03SwitchLabel                matlab.ui.control.Label
        BIP03Switch                     matlab.ui.control.Switch
        BIP02SwitchLabel                matlab.ui.control.Label
        BIP02Switch                     matlab.ui.control.Switch
        BIP01Switch                     matlab.ui.control.Switch
        BIP01SwitchLabel                matlab.ui.control.Label
        BipolarUIAxes                   matlab.ui.control.UIAxes
        BipolarAverageTab               matlab.ui.container.Tab
        BipolarAverageGridLayout        matlab.ui.container.GridLayout
        BipolarAverageSettingsPanel     matlab.ui.container.Panel
        BipolarAverageRectifyCheckBox   matlab.ui.control.CheckBox
        BipolarAverageNEditField        matlab.ui.control.NumericEditField
        NEditFieldLabel_2               matlab.ui.control.Label
        ResetBipolarAverageButton       matlab.ui.control.Button
        StopBipolarAverageSpinner       matlab.ui.control.Spinner
        StopDatamsSpinner_2Label        matlab.ui.control.Label
        StartBipolarAverageSpinner      matlab.ui.control.Spinner
        StartDatamsSpinner_2Label       matlab.ui.control.Label
        BipolarAverageCutoff2EditField  matlab.ui.control.NumericEditField
        Cutoff2HzEditFieldLabel_3       matlab.ui.control.Label
        BipolarAverageCutoff1EditField  matlab.ui.control.NumericEditField
        Cutoff1HzEditFieldLabel_3       matlab.ui.control.Label
        BipolarAverageChannelEditField  matlab.ui.control.NumericEditField
        BIPChannelLabel                 matlab.ui.control.Label
        BipolarAverageFilterCheckBox    matlab.ui.control.CheckBox
        BipolarAverageUIAxes            matlab.ui.control.UIAxes
        RMSContourTab                   matlab.ui.container.Tab
        RMSContourGridLayout            matlab.ui.container.GridLayout
        RMSContourSettingsPanel         matlab.ui.container.Panel
        ICAStreamTab                    matlab.ui.container.Tab
        ICAStreamGridLayout             matlab.ui.container.GridLayout
        ICAStreamChannelsPanel          matlab.ui.container.Panel
        ToggleAllICAChannelsSwitch      matlab.ui.control.ToggleSwitch
        ToggleAllBipolarChannelsSwitchLabel_2  matlab.ui.control.Label
        ICA20SwitchLabel                matlab.ui.control.Label
        ICA20Switch                     matlab.ui.control.Switch
        ICA19SwitchLabel                matlab.ui.control.Label
        ICA19Switch                     matlab.ui.control.Switch
        ICA18SwitchLabel                matlab.ui.control.Label
        ICA18Switch                     matlab.ui.control.Switch
        ICA17Switch                     matlab.ui.control.Switch
        ICA17SwitchLabel                matlab.ui.control.Label
        ICA16SwitchLabel                matlab.ui.control.Label
        ICA16Switch                     matlab.ui.control.Switch
        ICA15SwitchLabel                matlab.ui.control.Label
        ICA15Switch                     matlab.ui.control.Switch
        ICA14SwitchLabel                matlab.ui.control.Label
        ICA14Switch                     matlab.ui.control.Switch
        ICA13Switch                     matlab.ui.control.Switch
        ICA13SwitchLabel                matlab.ui.control.Label
        ICA12SwitchLabel                matlab.ui.control.Label
        ICA12Switch                     matlab.ui.control.Switch
        ICA11SwitchLabel                matlab.ui.control.Label
        ICA11Switch                     matlab.ui.control.Switch
        ICA10SwitchLabel                matlab.ui.control.Label
        ICA10Switch                     matlab.ui.control.Switch
        ICA09Switch                     matlab.ui.control.Switch
        ICA09SwitchLabel                matlab.ui.control.Label
        ICA08SwitchLabel                matlab.ui.control.Label
        ICA08Switch                     matlab.ui.control.Switch
        ICA07SwitchLabel                matlab.ui.control.Label
        ICA07Switch                     matlab.ui.control.Switch
        ICA06SwitchLabel                matlab.ui.control.Label
        ICA06Switch                     matlab.ui.control.Switch
        ICA05Switch                     matlab.ui.control.Switch
        ICA05SwitchLabel                matlab.ui.control.Label
        ICA04SwitchLabel                matlab.ui.control.Label
        ICA04Switch                     matlab.ui.control.Switch
        ICA03SwitchLabel                matlab.ui.control.Label
        ICA03Switch                     matlab.ui.control.Switch
        ICA02SwitchLabel                matlab.ui.control.Label
        ICA02Switch                     matlab.ui.control.Switch
        ICA01Switch                     matlab.ui.control.Switch
        ICA01SwitchLabel                matlab.ui.control.Label
        ICAUIAxes                       matlab.ui.control.UIAxes
        ICARasterTab                    matlab.ui.container.Tab
        ICARasterGridLayout             matlab.ui.container.GridLayout
        ICARasterSettingsPanel          matlab.ui.container.Panel
        ConfigTab                       matlab.ui.container.Tab
        ConfigGridLayout                matlab.ui.container.GridLayout
        ResponsesStopEditField          matlab.ui.control.NumericEditField
        ResponsesStopEditFIeldLabel     matlab.ui.control.Label
        ResponsesStartEditField         matlab.ui.control.NumericEditField
        ResponsesStartEditFieldLabel    matlab.ui.control.Label
        ResponsesConnectionStatusLamp   matlab.ui.control.Lamp
        ResponsesConnectionStatusLampLabel  matlab.ui.control.Label
        ResponsesConnectButton          matlab.ui.control.Button
        ResponsesPortEditField          matlab.ui.control.NumericEditField
        ResponsesPortEditFieldLabel     matlab.ui.control.Label
        ResponsesIPEditField            matlab.ui.control.EditField
        ResponsesIPAddressEditFieldLabel  matlab.ui.control.Label
    end

    
    properties (Access = public)
        data
    end
    
    properties (Hidden, Access = public)
        CDATA
    end
    
    properties (GetAccess = public, SetAccess = protected)
        tag         % Either "A" or "B"
        cfg         % Parsed configuration struct
        connected = struct('parameters', false, 'data', false, 'responses', false); % True if the parameters server (from controller UI) is connected
        mode (1,1) enum.TMSiPacketMode = enum.TMSiPacketMode.StreamMode % Current "mode" based on selected visualizer tab
        plot_fcn    % Callback to use in handling data
        filters     % Filter coefficients and parameters
        H           % Struct containing the different graphic objects to update
        
        response_data = cell(68, 1); % Store RMS ratio data for all the (enabled) data channels
        n = struct
    end
    
    properties (Hidden, Constant)
        ICA_OFFSET = 3.5
    end

    properties (Access = private)
        in_configuration_mode_ (1,1) logical = false;
        n_new_        (1,1) double = 0;
        data_running_ (1,1) logical = false;
        data_state_   (1,1) enum.TMSiState = enum.TMSiState.IDLE;
        rclient_              % Responses client (secondary visualizer for online stim control/interaction)
        udp_receiver_         % UDP port that receives the data streams
    end
    
    methods (Access = public)

        function handle_udp_data_byte_stream_mode(app, src, ~)
            %HANDLE_UDP_DATA_BYTE_STREAM_MODE  Default stream mode, this is a callback for the udp_receiver_ that parses byte frames
            N = app.n.all_samples;
            tab = app.TabGroup.SelectedTab.tag;
            switch app.mode
                case enum.TMSiPacketMode.StreamMode % Default
                    b = src.read(N+2, "double");
                    x = b(end);
                    if x == 65535
                        ch = b(1);
                        y = b(2:(end-1));
                        switch upper(char(tab))
                            case 'US'
                                if (ch < 65) || (ch == 100)
                                    app.update_unipolar_stream_data(ch, y);
                                else
                                    yf = app.filter_bipolar_data_(ch, y);
                                    snippets = app.parse_snippets_(yf);
                                    app.parse_response_data(ch, snippets);
                                end
                            case 'UA'
                                if (ch < 65) || (ch == 100)
                                    app.update_unipolar_average_data(ch, y);
                                else
                                    yf = app.filter_bipolar_data_(ch, y);
                                    snippets = app.parse_snippets_(yf);
                                    app.parse_response_data(ch, snippets);
                                end
                            case 'BS'
                                if (ch >= 65) || (ch == 0)
                                    app.update_bipolar_stream_data(ch, y);
                                else
                                    yf = app.filter_unipolar_data_(ch, y);
                                    snippets = app.parse_snippets_(yf);
                                    app.parse_response_data(ch, snippets);
                                end
                            case 'BA'
                                if (ch >= 65) || (ch == 0)
                                    app.update_bipolar_average_data(ch, y);
                                else
                                    yf = app.filter_unipolar_data_(ch, y);
                                    snippets = app.parse_snippets_(yf);
                                    app.parse_response_data(ch, snippets);
                                end
                        end
                    else
                        while (src.BytesAvailable > 0) && (x~= 65535)
                            x = src.read(1, "double");
                        end
                    end

                case enum.TMSiPacketMode.RasterMode

                case enum.TMSiPacketMode.ContourMode

            end
        end

        function update_bipolar_stream_data(app, ch, data)
            %UPDATE_BIPOLAR_STREAM_DATA  Update bipolar stream handles
            if (ch > 64) && (ch < 100)
                ch = ch - 64;
                if en(ch)
                    app.H.streams(ch).YData = app.filter_bipolar_data_(ch, data);
                    if app.connected.responses
                        snippets = app.parse_snippets_(data);
                        app.parse_response_data(ch, snippets);
                    end
                end
            elseif ch == 0
                set(app.H.streams, 'XData', data); 
                xl = [data(1) data(app.n.all_samples)];
                set(app.BipolarUIAxes, 'XLim', xl, 'XTick', [xl(1), data(app.n.mid_sample), xl(2)]);
                drawnow;
                if app.connected.responses
                    app.send_response_tcp_message();
                end
            elseif ch == 100
                app.parse_sync_trigs_(data);
            end
        end
        
        function update_unipolar_stream_data(app, ch, data)
            %UPDATE_UNIPOLAR_STREAM_DATA  Update unipolar stream handles
            if (ch > 0) && (ch < 100)
                
                if en(ch)
                    app.H.streams(ch).YData = app.filter_unipolar_data_(ch, data);
                    if app.connected.responses
                        snippets = app.parse_snippets_(data);
                        app.parse_response_data(ch, snippets);
                    end
                end
                
            elseif ch == 0
                set(app.H.streams, 'XData', data);
                xl = [data(1), data(app.n.all_samples)];
                set(app.UnipolarUIAxes, 'XLim', xl, 'XTick', [xl(1), data(app.n.mid_sample), xl(2)]);
                drawnow;
                if app.connected.responses
                    app.send_response_tcp_message();
                end
            elseif ch == 100
                app.parse_sync_trigs_(data);
            end
        end
        
        function update_ica_stream_data(app, ch, data)
            %UPDATE_ICA_STREAM_DATA  Update ICA stream handles
            if (ch > 0) && (ch < 100)
                en = app.cfg.SAGA.Channels.en.ICA;
                if en(ch)
                    app.H.streams(ch).YData = data + sum(en(1:ch))*app.ICA_OFFSET;
                    drawnow;
                end
                if app.connected.responses
                    snippets = app.parse_snippets_(data);
                    app.parse_response_data(ch, snippets);
                end
            elseif ch == 0
                set(app.H.streams, 'XData', data);
                xl = [data(1), data(app.n.all_samples)];
                set(app.ICAUIAxes, 'XLim', xl, 'XTick', [xl(1), data(app.n.mid_sample), xl(2)]);
                drawnow;
                if app.connected.responses
                    app.send_response_tcp_message();
                end
            elseif ch == 100
                app.parse_sync_trigs_(data);
            end
        end
        
        function update_unipolar_average_data(app, ch, data)
            %UPDATE_UNIPOLAR_AVERAGE_DATA  Update unipolar average handles
            if (ch > 0) && (ch < 100) % ch is either 0 (triggers) or (1-indexed data channel)
                if app.filters.UNI_AVG.en
                    data = filter(app.filters.UNI_AVG.b, app.filters.UNI_AVG.a, data);
                end
                if app.filters.UNI_AVG.rectify
                    data = abs(data);
                end
                snippets = app.parse_snippets_(data);
                if ch == app.UnipolarAverageChannelEditField.Value
                    app.shift_in_new_averaging_snippets_(snippets);
                end
                if app.connected.responses
                    app.parse_response_data(ch, snippets);
                end
            elseif ch == 0 % It's "time" channel- this comes after the "data bolus" so just issue command to any listening response server
                if app.connected.responses
                    app.send_response_tcp_message();
                end
            else
                app.parse_sync_trigs_(data);
            end
        end

        function update_bipolar_average_data(app, ch, data)
            %UPDATE_BIPOLAR_AVERAGE_DATA  Update unipolar average handles
            if (ch > 0) && (ch < 100) % ch is either 0 (triggers) or (1-indexed data channel)
                ch = ch - 64;
                if app.filters.BIP_AVG.en
                    data = filter(app.filters.BIP_AVG.b, app.filters.BIP_AVG.a, data);
                end
                if app.filters.BIP_AVG.rectify
                    data = abs(data);
                end
                snippets = app.parse_snippets_(data);
                if ch == app.BipolarAverageChannelEditField.Value
                    app.shift_in_new_averaging_snippets_(snippets);
                end
                if app.connected.responses
                    app.parse_response_data(ch, snippets);
                end
            elseif ch == 0 % It's "time" channel- this comes after the "data bolus" so just issue command to any listening response server
                if app.connected.responses
                    app.send_response_tcp_message();
                end
            else
                app.parse_sync_trigs_(data);
            end
        end

        function parse_response_data(app, ch, snippets)
            %PARSE_RESPONSE_DATA  Send TCP message to "responses" server for RMS data that is used in online stim controller
            fs = app.cfg.Default.Sample_Rate;
            n_new = size(snippets,1);
            rms_data = zeros(n_new, 1);
            i_post = [round(app.ResponsesStartEditField.Value * 1e-3 * fs), ...
                      round(app.ResponsesStopEditField.Value * 1e-3 * fs)];
            vec_post = (app.H.sample_indices >= i_post(1)) & ...
                       (app.H.sample_indices < i_post(2));
            vec_pre = app.H.sample_indices < 0;
            mu = mean(snippets(:, vec_pre), 2);
            for ii = 1:n_new
                pre = mean((snippets(ii, vec_pre) - mu(ii)).^2);
                rms_data(ii) = mean((snippets(ii, vec_post) - mu(ii)).^2) ./ pre;
            end
            app.response_data{ch} = circshift(app.response_data{ch}, n_new, 1);
            app.response_data{ch}(1:n_new) = rms_data;
            app.n_new_ = n_new;
        end

        function send_response_tcp_message(app)
            %SEND_RESPONSE_TCP_MESSAGE  Send TCP message to "responses" server with meta-command like to move to next pulse in queue etc.
            ch = 1:68;
            ch = ch([app.cfg.SAGA.Channels.en.UNI, app.cfg.SAGA.Channels.en.BIP]);
            res = zeros(numel(ch), app.n_new_);
            ii = 0;
            for ich = ch
                ii = ii + 1;
                res(ii,:) = app.response_data{ich}(1:app.n_new_);
            end
            jsondata = msg.json_stim_response(app.tag, app.n_new_, ch, res);
            app.rclient_.writeline(jsonencode(jsondata));
        end

        function setConnectionStatus(app, src, evt) %#ok<INUSL> 
            %SETCONNECTIONSTATUS  Indicate whether the app has a client (the controller application) connected over TCP.
            if evt.Connected
                app.ParametersConnectionStatusLamp.Color = [0.39,0.83,0.07];
                app.connected.parameters = true;
            else
                app.ParametersConnectionStatusLamp.Color = [0.65,0.65,0.65];
                app.connected.parameters = false;
            end
            app.setDateTimeLabel(evt.AbsoluteTime);
        end
        
        function setDateTimeLabel(app, dt)
            %SETDATETIMELABEL Set the text of the datetime label at the top of the interface.
            %
            % Inputs:
            %   dt - Datetime (scalar)
            app.DateTimeLabel.Text = sprintf("%4d-%02d-%02d %02d:%02d:%05.3f", ...
                year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt));
        end
    end
    
    methods (Access = private)
        function filtdata = filter_bipolar_data_(app, ch, data)
            %FILTER_BIPOLAR_DATA  Apply filters to bipolar data
            en = app.cfg.SAGA.Channels.en.BIP;
            b = app.filters.BIP.b;
            a = app.filters.BIP.a;
            apply_filter = app.filters.BIP.en;
            if apply_filter
                [ydata, app.filters.BIP.z(ch,:)] = filter(b,a,(data - mean(data)), app.filters.BIP.z(ch,:));
                filtdata = ydata + sum(en(1:ch))*app.BipolarPerChannelOffsetEditField.Value;
            else
                filtdata = data - mean(data) + (sum(en(1:ch))-1)*app.BipolarPerChannelOffsetEditField.Value;
            end
        end

        function filtdata = filter_unipolar_data_(app, ch, data)
            %FILTER_UNIPOLAR_DATA Apply filters to unipolar data
            en = app.cfg.SAGA.Channels.en.UNI;
            b = app.filters.UNI.b;
            a = app.filters.UNI.a;
            apply_filter = app.filters.UNI.en;
            if apply_filter
                [ydata, app.filters.UNI.z(ch,:)] = filter(b,a,(data - mean(data)), app.filters.UNI.z(ch,:));
                filtdata = ydata + sum(en(1:ch))*app.UnipolarPerChannelOffsetEditField.Value;
            else
                filtdata = data - mean(data) + (sum(en(1:ch))-1)*app.UnipolarPerChannelOffsetEditField.Value;
            end
        end

        function disable_bipolar_stream(app, chnum)
            %DISABLE_BIPOLAR_STREAM  Disable the selected channel(s)
            %
            % Syntax:
            %   app.disable_bipolar_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to disable.
            app.cfg.SAGA.Channels.en.BIP(chnum) = false(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.BipolarStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'off';
                h.Value = 'Off';
            end
        end
        
        function enable_bipolar_stream(app, chnum)
            %ENABLE_BIPOLAR_STREAM  Enable the selected channel(s)
            %
            % Syntax:
            %   app.enable_bipolar_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to enable.
            app.cfg.SAGA.Channels.en.BIP(chnum) = true(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.BipolarStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'on';
                h.Value = 'On';
            end
        end
        
        function disable_unipolar_stream(app, chnum)
            %DISABLE_UNIPOLAR_STREAM  Disable the selected channel(s)
            %
            % Syntax:
            %   app.disable_unipolar_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to disable.
            app.cfg.SAGA.Channels.en.UNI(chnum) = false(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.UnipolarStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'off';
                h.Value = 'Off';
            end
        end
        
        function enable_unipolar_stream(app, chnum)
            %ENABLE_UNIPOLAR_STREAM  Enable the selected channel(s)
            %
            % Syntax:
            %   app.enable_unipolar_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to enable.
            app.cfg.SAGA.Channels.en.UNI(chnum) = true(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.UnipolarStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'on';
                h.Value = 'On';
            end
        end
        
        function disable_ica_stream(app, chnum)
            %DISABLE_ICA_STREAM  Disable the selected channel(s)
            %
            % Syntax:
            %   app.disable_ica_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to disable.
            app.cfg.SAGA.Channels.en.ICA(chnum) = false(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.ICAStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'off';
                h.Value = 'Off';
            end
        end
        
        function enable_ica_stream(app, chnum)
            %ENABLE_ICA_STREAM  Enable the selected channel(s)
            %
            % Syntax:
            %   app.enable_ica_stream(chnum)
            %
            % Inputs:
            %   chnum - Scalar or vector of integers indicating 1-indexed
            %               channel-number(s) to enable.
            app.cfg.SAGA.Channels.en.ICA(chnum) = true(size(chnum));
            for ii = 1:numel(chnum)
                h = findobj(app.ICAStreamChannelsPanel.Children, 'Tag', sprintf('%d', chnum(ii)), 'Type', 'uiswitch');
                app.H.streams(chnum(ii)).Visible = 'on';
                h.Value = 'On';
            end
        end
        
        function c = init_cdata(app)
            %INIT_CDATA Helper function to initialize the colormap stuff
            my_colormap = cm.map('rosette');
            cmobj = cm.cmap([1 size(my_colormap,1)], my_colormap);
            c = struct( ...
                'UNI', double(cmobj(linspace(1,32,64)))./255.0, ...
                'BIP', double(cmobj(linspace(1,32, 4)))./255.0, ...
                'ICA', double(cmobj(linspace(1,32,app.cfg.Default.N_ICs)))./255.0  ...
                );
            app.CDATA = c;
        end
        
        function init_filters(app)
            %INIT_FILTERS Helper function to initialize filter coefficients
            % Setup filters struct
            % 'b' - numerator coefficients
            % 'a' - denominator coefficients
            % 'z' - filter state (final state values from previous
            %           step; rows are channels columns are values for each
            %           state coefficient which depend on filter order;
            %           since we don't allow order to change (2nd order 
            %           butterworth IIR bandpass filter design, so we 
            %           know this will have 4 columns). For UNI, we add 1
            %           more row in case we are filtering the CAR signal.
            % 'en' - Apply BPF?
            app.filters = struct(...
                'UNI', struct('b', [], 'a', [], 'z', zeros(65,4), 'en', app.UnipolarFilterCheckBox.Value, 'CAR', app.UnipolarCARCheckBox.Value), ...
                'BIP', struct('b', [], 'a', [], 'z', zeros(4,4), 'en', app.BipolarFilterCheckBox.Value), ...
                'UNI_AVG', struct('b', [], 'a', [], 'z', zeros(1,4), 'en', app.UnipolarAverageFilterCheckBox.Value, 'CAR', app.UnipolarAverageCARCheckBox.Value, 'rectify', app.UnipolarAverageRectifyCheckBox.Value), ...
                'BIP_AVG', struct('b', [], 'a', [], 'z', zeros(1,4), 'en', app.BipolarAverageFilterCheckBox.Value, 'rectify', app.BipolarAverageRectifyCheckBox.Value));
            [app.filters.UNI.b,app.filters.UNI.a] =  ...
                butter(2,([app.UnipolarCutoff1EditField.Value, app.UnipolarCutoff2EditField.Value])./(app.cfg.Default.Sample_Rate/2), 'bandpass');
            [app.filters.BIP.b,app.filters.BIP.a] =  ...
                butter(2,([app.BipolarCutoff1EditField.Value, app.BipolarCutoff2EditField.Value])./(app.cfg.Default.Sample_Rate/2), 'bandpass');
            [app.filters.UNI_AVG.b,app.filters.UNI_AVG.a] =  ...
                butter(2,([app.UnipolarAverageCutoff1EditField.Value, app.UnipolarAverageCutoff2EditField.Value])./(app.cfg.Default.Sample_Rate/2), 'bandpass');
            [app.filters.BIP_AVG.b,app.filters.BIP_AVG.a] =  ...
                butter(2,([app.BipolarAverageCutoff1EditField.Value, app.BipolarAverageCutoff2EditField.Value])./(app.cfg.Default.Sample_Rate/2), 'bandpass');
        end
        
        function tf = getEnabledChannels(app, tag)
            if nargin < 2
                tag = app.TabGroup.SelectedTab.Tag;
            end
            switch string(upper(tag))
                case {"US", "UA", "UR"}
                    n_ch = numel(app.cfg.SAGA.Channels.UNI);
                    tf = false(n_ch,1);
                    for ii = 1:n_ch
                        name = sprintf("UNI%02dSwitch", ii);
                        try
                            tf(ii) = app.(name).Value;
                        catch me
                            warning("No matching element for name == '%s'", name);
                            rethrow(me);
                        end
                    end
                case {"BS", "BA"}
                    n_ch = numel(app.cfg.SAGA.Channels.BIP);
                    tf = false(n_ch,1);
                    for ii = 1:n_ch
                        name = sprintf("BIP%02dSwitch", ii);
                        tf(ii) = app.(name).Value;
                    end
                case {"IS", "IR"}
                    n_ch = numel(app.cfg.SAGA.Channels.ICA);
                    tf = false(n_ch,1);
                    for ii = 1:n_ch
                        name = sprintf("ICA%02dSwitch", ii);
                        tf(ii) = app.(name).Value;
                    end                
                case "RC"
                    
                otherwise
                    error("Unrecognized tab Tag value: %s", app.TabGroup.SelectedTab.Tag);
            end
        end

        function snippets = parse_snippets_(app, data)
            %PARSE_SNIPPETS_  Get "triggered" snippets for averaging (single-channel)
            %
            % Syntax:
            %   snippets = app.parse_snippets_(data);
            nt = numel(app.H.trigs);
            snippets = nan(nt, numel(app.H.sample_indices));
            for ii = 1:nt
                vec = app.H.sample_indices + app.H.trigs(ii);
                idx = (vec > 0) & (vec < numel(data));
                snippets(ii, idx) = data(vec(idx));
            end
        end

        function send_uni_stream_udp_message(app)
            %SEND_UNI_STREAM_UDP_MESSAGE  Sends message to configure as UDP stream with currently-enabled UNIPOLAR (ARRAY) channel-set.
            ch = char(app.cfg.SAGA.Channels.UNI(app.cfg.SAGA.Channels.en.UNI) + 96);
            message = char(sprintf('%s.%s.%d.%s', app.mode, app.tag, double(app.filters.UNI.CAR), ch));
            app.send_message_(message);
        end

        function send_uni_average_udp_message(app)
            %SEND_UNI_AVERAGE_UDP_MESSAGE  Sends message to configure as UDP averaging with currently-selected array channel.
%             message = char(sprintf('%s.%s.%d.%d', app.mode, app.Tag, double(app.filters.UNI_AVG.CAR), app.cfg.SAGA.Channels.UNI(app.UnipolarAverageChannelEditField.Value)));
            ch = char([app.cfg.SAGA.Channels.UNI(app.cfg.SAGA.Channels.en.UNI), app.cfg.SAGA.Channels.BIP(app.cfg.SAGA.Channels.en.BIP)] + 96);
            message = char(sprintf('%s.%s.%d.%s', app.mode, app.tag, double(app.filters.UNI.CAR), ch));
            app.send_message_(message);
        end

        function send_bip_stream_udp_message(app)
            %SEND_BIP_STREAM_UDP_MESSAGE  Sends message to configure as UDP stream with currently-enabled BIPOLAR channel-set.
            ch = char(app.cfg.SAGA.Channels.BIP(app.cfg.SAGA.Channels.en.BIP) + 96);
            message = char(sprintf('%s.%s.%s', app.mode, app.tag, ch));
            app.send_message_(message);
        end

        function send_bip_average_udp_message(app)
            %SEND_BIP_AVERAGE_UDP_MESSAGE  Sends message to configure as UDP averaging with currently-selected bipolar channel.
%             message = char(sprintf('%s.%s.%d', app.mode, app.Tag, app.cfg.SAGA.Channels.BIP(app.BipolarAverageChannelEditField.Value)));
            ch = char([app.cfg.SAGA.Channels.UNI(app.cfg.SAGA.Channels.en.UNI), app.cfg.SAGA.Channels.BIP(app.cfg.SAGA.Channels.en.BIP)] + 96);
            message = char(sprintf('%s.%s.%d.%s', app.mode, app.tag, double(app.filters.UNI.CAR), ch));
            app.send_message_(message);
        end

        function send_ica_stream_udp_message(app)
            %SEND_ICA_STREAM_UDP_MESSAGE  Sends message to configure as UDP stream with currently-enabled BIPOLAR channel-set.
            ch = char(app.cfg.SAGA.Channels.ICA(app.cfg.SAGA.Channels.en.ICA) + 96);
            message = char(sprintf('%s.%s.%s', app.mode, app.tag, ch));
            app.send_message_(message);
        end

        function send_mode_only_udp_message(app)
            %SEND_MODE_ONLY_UDP_MESSAGE  Sends message to configure as UDP stream with currently-enabled BIPOLAR channel-set.
            message = char(sprintf('%s.%s', app.mode, app.tag));
            app.send_message_(message);
        end
        
        function send_message_(app, message)
            %SEND_MESSAGE_  Sends message via UDP and also to the parameters TCP client.
            if app.data_running_
                fprintf(1,'[SAGA-%s VISUALIZER]\tData is running; no parameter message sent.\n', app.tag);
            else
                fprintf(1,'[SAGA-%s VISUALIZER]\tSending message: %s\n', app.tag, message);
                if app.connected.data
                    app.udp_receiver_.writeline(message, app.cfg.Host.streams, app.cfg.UDP.tmsi.config);
                end
            end
        end
        
        function h = init_uni_stream_tab_graphics(app)
            xvec = (0:(app.cfg.SAGA.Channels.n.samples-1))./app.cfg.Default.Sample_Rate;
            h = struct('streams', gobjects(numel(app.cfg.SAGA.Channels.UNI), 1), 'trigs', []);
            for ii = 1:numel(h.streams)
                offset = app.UnipolarPerChannelOffsetEditField.Value * (ii-1);
                h.streams(ii) = line(app.UnipolarUIAxes, xvec, zeros(size(xvec)) + offset, ...
                    'Color', app.CDATA.UNI(ii,:), ...
                    'LineWidth', 1.5, ...
                    'DisplayName', sprintf('UNI%02d', ii), ...
                    'Visible', 'off' );
                             
            end
        end

        function h = init_uni_average_tab_graphics(app)
            fs = app.cfg.Default.Sample_Rate;
            sample_indices = round(app.StartUnipolarAverageSpinner.Value * fs * 1e-3):round(app.StopUnipolarAverageSpinner.Value * fs * 1e-3);
            t_vec = sample_indices / fs * 1e3;
            h = struct('ax', app.UnipolarAverageUIAxes, 'mean', gobjects(1,1), 'sd', gobjects(1,1), 'history', nan(app.UnipolarAverageNEditField.Value, numel(sample_indices)), 'n', 0, 'n_max', app.UnipolarAverageNEditField.Value, 'sample_indices', sample_indices, 'trigs', []);
            npt= numel(sample_indices);
            faces = [1:2*npt, 1];
            verts = [[t_vec'; flipud(t_vec')], [ones(npt,1); -1.*ones(npt,1)]];
            app.UnipolarAverageUIAxes.Title.String = "(N = 0)";
            h.sd = patch(app.UnipolarAverageUIAxes, 'Faces', faces, 'Vertices', verts, 'FaceColor', [0.65 0.65 0.65], 'DisplayName', '\pm1SD','EdgeColor', 'none');
            h.mean = line(app.UnipolarAverageUIAxes, t_vec, zeros(size(t_vec)), 'Color', 'k', 'LineWidth', 2.5, 'DisplayName', 'Mean');
            
            if app.UnipolarAverageRectifyCheckBox.Value
                set(app.UnipolarAverageUIAxes, 'YLim', [-10 100], 'XLim', [t_vec(1), t_vec(end)]);
            else
                set(app.UnipolarAverageUIAxes, 'YLim', [-100 100], 'XLim', [t_vec(1), t_vec(end)]);
            end
        end

        function h = init_uni_raster_tab_graphics(app)
            h = struct;
        end

        function h = init_bip_stream_tab_graphics(app)

            xvec = (0:(app.cfg.SAGA.Channels.n.samples-1))./app.cfg.Default.Sample_Rate;
            h = struct('streams', gobjects(numel(app.cfg.SAGA.Channels.BIP), 1), 'trigs', []);
            for ii = 1:numel(h.streams)
                offset = app.BipolarPerChannelOffsetEditField.Value * (ii-1);
                h.streams(ii) = line(app.BipolarUIAxes, xvec, zeros(size(xvec)) + offset, ...
                    'Color', app.CDATA.BIP(ii,:), ...
                    'LineWidth', 1.5, ...
                    'DisplayName', sprintf('BIP%02d', ii), ...
                    'Visible', 'off' );              
            end
        end

        function h = init_bip_average_tab_graphics(app)
            fs = app.cfg.Default.Sample_Rate;
            sample_indices = round(app.StartBipolarAverageSpinner.Value * fs * 1e-3):round(app.StopBipolarAverageSpinner.Value * fs * 1e-3);
            t_vec = sample_indices / fs * 1e3;
            h = struct('ax', app.BipolarAverageUIAxes, 'mean', gobjects(1,1), 'sd', gobjects(1,1), 'history', nan(app.BipolarAverageNEditField.Value, numel(sample_indices)), 'n', 0, 'n_max', app.BipolarAverageNEditField.Value, 'sample_indices', sample_indices, 'trigs', []);
            npt= numel(sample_indices);
            faces = [1:2*npt, 1];
            verts = [[t_vec'; flipud(t_vec')], [ones(npt,1); -1.*ones(npt,1)]];
            app.BipolarAverageUIAxes.Title.String = "(N = 0)";
            h.sd = patch(app.BipolarAverageUIAxes, 'Faces', faces, 'Vertices', verts, 'FaceColor', [0.65 0.65 0.65], 'DisplayName', '\pm1SD','EdgeColor', 'none');
            h.mean = line(app.BipolarAverageUIAxes, t_vec, zeros(size(t_vec)), 'Color', 'k', 'LineWidth', 2.5, 'DisplayName', 'Mean');
            
            if app.BipolarAverageRectifyCheckBox.Value
                set(app.BipolarAverageUIAxes, 'YLim', [-10 100], 'XLim', [t_vec(1), t_vec(end)]);
            else
                set(app.BipolarAverageUIAxes, 'YLim', [-100 100], 'XLim', [t_vec(1), t_vec(end)]);
            end
        end

        function h = init_ica_stream_tab_graphics(app)

            xvec = (0:(app.cfg.SAGA.Channels.n.samples-1))./app.cfg.Default.Sample_Rate;
            h = struct('streams', gobjects(app.cfg.Default.N_ICs, 1), 'trigs', []);
            for ii = 1:numel(h.streams)
                offset = app.ICA_OFFSET * (ii-1);
                h.streams(ii) = line(app.ICAUIAxes, xvec, zeros(size(xvec)) + offset, ...
                    'Color', app.CDATA.ICA(ii,:), ...
                    'LineWidth', 1.5, ...
                    'DisplayName', sprintf('ICA%02d', ii), ...
                    'Visible', 'off' );                
            end
        end

        function h = init_ica_raster_tab_graphics(app)
            h = struct;
        end

        function h = init_rms_contour_tab_graphics(app)
            h = struct;
        end
        
        function shift_in_new_averaging_snippets_(app, snippets)
            if isempty(snippets)
                return;
            end
            n_snips = size(snippets,1);
            app.H.n = min(app.H.n+n_snips, app.H.n_max);
            app.H.history = circshift(app.H.history, n_snips, 1);
            app.H.history(1:n_snips,:) = snippets;
            mu = nanmean(app.H.history(1:app.H.n,:), 1); %#ok<*NANMEAN> 
            sd = nanstd(app.H.history(1:app.H.n,:), [], 1); %#ok<*NANSTD> 
            app.H.mean.YData = mu;
            app.H.sd.Vertices(:,2) = [(mu + sd)'; flipud((mu - sd)')];
            app.H.ax.Title.String = sprintf('(N = %d)', app.H.n);
            drawnow;
        end
        
        function parse_sync_trigs_(app, data, n_samples_debounce)
            fs = app.cfg.Default.Sample_Rate;
            if nargin < 3
                n_samples_debounce = fs * 0.100; % 100-ms default
            end
            sync_bit = app.TriggerSyncBitEditField.Value;
            sync_data = bitand(data, 2^sync_bit) ~= 2^sync_bit;
            trigs = find([false; diff(sync_data(:)) > 0]);
            % Remove triggers that don't have the correct pre- or post-
            % sample count:
            trigs(trigs <= (app.StartUnipolarAverageSpinner.Value * fs * -1e-3)) = [];
            trigs(trigs > (numel(data) - (app.StopUnipolarAverageSpinner.Value * fs * 1e-3))) = [];
            % Debounce triggers that are too close together (i.e. multiple
            % pulses within a single stimulus burst; we only want to
            % average in alignment to the rising-edge of the first pulse)
            k = 1;
            curTrig = -inf;
            while k < numel(trigs)
                if (trigs(k) - curTrig) > n_samples_debounce
                    curTrig = trigs(k); % Save this trigger as new "last trig"
                    k = k + 1; % increment counter since we do not drop sample
                else % Otherwise, this trigger is too soon- remove it
                    trigs(k) = []; % k does not increment.
                end
            end
            app.H.trigs = trigs;
        end
    end

    methods (Static, Access = protected)
        function WipeTabGraphics(tab)
            %WIPETABGRAPHICS  Delete all child-axes graphics, given a tab.
            h = findobj(tab.Children, 'Type', 'axes');
            delete(h.Children);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app, tag, config, varargin)
            app.tag = tag;
            % If this is the second SAGA figure move it right.
            if strcmpi(tag, "B")
                app.SAGADataViewerUIFigure.Position(1) = app.SAGADataViewerUIFigure.Position(1) + app.SAGADataViewerUIFigure.Position(3)*0.85;
            end
            % Setup the title and stuff:
            set(app.SAGADataViewerUIFigure, ...
                'Name', sprintf("SAGA-%s Data Viewer", app.tag), ...
                'Tag', sprintf('fig.DataViewer.%s', app.tag));

            % Parse configuration
            if nargin < 3
                config = parse_main_config();
            end
            app.cfg = struct('SAGA', config.SAGA.(tag), ...
                             'Default', config.Default, ...
                             'Host', config.Host, ...
                             'TCP', config.TCP, ...
                             'UDP', config.UDP);    
            f = setdiff(string(fieldnames(app.cfg.SAGA.Channels)), "n");
            for iF = 1:numel(f)
                app.cfg.SAGA.Channels.en.(f(iF)) = false(size(app.cfg.SAGA.Channels.(f(iF))));
            end
            app.cfg.SAGA.Channels.ICA = 1:app.cfg.Default.N_ICs;
            app.cfg.SAGA.Channels.en.ICA = false(size(app.cfg.SAGA.Channels.ICA));
            
            app.udp_receiver_ = udpport("byte", ...
                "LocalHost", "0.0.0.0", ...
                "LocalPort", config.UDP.visualizer.(tag));
            app.udp_receiver_.configureCallback(...
                "byte", 8*(app.cfg.SAGA.Channels.n.samples + 2), ... % 1st sample is the channel; then all data; last is 65535 to indicate end of frame
                @app.handle_udp_data_byte_stream_mode);

            % Initialize stream colors and x-axis sample times vector.
            cdata = app.init_cdata();
            app.n.all_samples = app.cfg.SAGA.Channels.n.samples;
            app.n.mid_sample = round(app.n.all_samples/2);
            
            % Create struct to store the unipolar stream lines in.
            app.H = app.init_uni_stream_tab_graphics();
            for ii = 1:64
                app.(sprintf('UNI%02dSwitch',ii)).FontColor = cdata.UNI(ii,:);
                app.(sprintf('UNI%02dSwitchLabel', ii)).FontColor = cdata.UNI(ii,:);   
            end
            
            % Create struct to store the bipolar stream lines in.
            for ii = 1:numel(app.cfg.SAGA.Channels.BIP)
                app.(sprintf('BIP%02dSwitch',ii)).FontColor = cdata.BIP(ii,:);
                app.(sprintf('BIP%02dSwitchLabel', ii)).FontColor = cdata.BIP(ii,:);                
            end
            
            % Create struct to store the ICA stream lines in.
            for ii = 1:numel(app.cfg.Default.N_ICs)
                app.(sprintf('ICA%02dSwitch',ii)).FontColor = cdata.ICA(ii,:);
                app.(sprintf('ICA%02dSwitchLabel', ii)).FontColor = cdata.ICA(ii,:);                 
            end
            iUnused = 21 - (20 - app.cfg.Default.N_ICs);
            for ii = iUnused:20 % If there are less default N_ICs configured, hide the ones that won't be used.
                app.(sprintf('ICA%02dSwitch',ii)).Visible = 'off';
                app.(sprintf('ICA%02dSwitchLabel', ii)).Visible = 'off';   
            end
            
            app.init_filters();
            
            app.SAGALabel.Text = sprintf("SAGA-%s", app.tag);
            app.setDateTimeLabel(datetime('now'));
            app.enable_unipolar_stream(1:4);
            app.enable_bipolar_stream(1:4);
            app.enable_ica_stream(1:min(4, app.cfg.Default.N_ICs));

            % Settings for the UIAxes
            set(app.UnipolarUIAxes, 'Interactions', [zoomInteraction rulerPanInteraction('Dimension', 'xy')]);
            set(app.BipolarUIAxes, 'Interactions', [zoomInteraction rulerPanInteraction('Dimension', 'xy')]);
            set(app.UnipolarAverageUIAxes, 'Interactions', [zoomInteraction rulerPanInteraction('Dimension', 'xy')]);
            set(app.BipolarAverageUIAxes, 'Interactions', [zoomInteraction rulerPanInteraction('Dimension', 'xy')]);
            set(app.ICAUIAxes, 'Interactions', [zoomInteraction rulerPanInteraction('Dimension', 'xy')]);

            % Populate the response/online stim server with correct
            % defaults per configuration yaml.
            for ii = 1:64
                app.response_data{ii} = zeros(app.UnipolarAverageNEditField.Value, 1);
            end
            for ii = 65:68
                app.response_data{ii} = zeros(app.BipolarAverageNEditField.Value, 1);
            end
            app.ResponsesIPEditField.Value = app.cfg.Host.stimulation.visualizer;
            app.ResponsesPortEditField.Value = app.cfg.UDP.stimulation.visualizer.(tag);
            fprintf(1,'[SAGA-%s VISUALIZER]\t->\tStartup complete: Data-Visualizer-%s\n', app.tag);
        end

        % Value changed function: ToggleAllUnipolarChannelsSwitch
        function ToggleAllUnipolarChannelsSwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                 app.disable_unipolar_stream(1:64);
            else
                app.enable_unipolar_stream(1:64);
            end
            app.send_uni_stream_udp_message();
        end

        % Value changed function: ToggleAllBipolarChannelsSwitch
        function ToggleAllBipolarChannelsSwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                 app.disable_bipolar_stream(1:4);
            else
                app.enable_bipolar_stream(1:4);
            end
            app.send_bip_stream_udp_message();
        end

        % Value changed function: UNI01Switch, UNI02Switch, UNI03Switch, 
        % ...and 61 other components
        function UnipolarChannelSwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                app.disable_unipolar_stream(str2double(event.Source.Tag));
            else
                app.enable_unipolar_stream(str2double(event.Source.Tag));
            end
            app.send_uni_stream_udp_message();
        end

        % Value changed function: BIP01Switch, BIP02Switch, BIP03Switch, 
        % ...and 1 other component
        function BipolarSwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                app.disable_bipolar_stream(str2double(event.Source.Tag));
            else
                app.enable_bipolar_stream(str2double(event.Source.Tag));
            end
            app.send_bip_stream_udp_message();
        end

        % Callback function: BipolarAverageCutoff1EditField, 
        % ...and 23 other components
        function FilterParameterValueChanged(app, event)
            app.init_filters();
            switch app.mode
                case 'UA'
                    SAGA_Data_Visualizer.WipeTabGraphics(app.TabGroup.SelectedTab);
                    app.H = app.init_uni_average_tab_graphics();
                case 'BA'
                    SAGA_Data_Visualizer.WipeTabGraphics(app.TabGroup.SelectedTab);
                    app.H = app.init_bip_average_tab_graphics();
            end
        end

        % Value changed function: BipolarPerChannelOffsetEditField, 
        % ...and 1 other component
        function PerChannelOffsetEditFieldValueChanged(app, event)
            prev = event.PreviousValue;
            value = event.Value;
            dy = value - prev;
            h = app.H.(event.Source.Tag);
            for ii = 1:numel(h)
                new_offset = (ii - 1) * dy;
                h(ii).YData = h(ii).YData + new_offset;
            end
        end

        % Selection change function: TabGroup
        function TabGroupSelectionChanged(app, event)
            %TABGROUPSELECTIONCHANGED  Sends reconfiguration UDP command to the parameter server, so that stream service sends correct data.
            selectedTab = event.NewValue;

            % First, delete unused graphics from the tab we just left.
            previousTab = event.OldValue;
            if ~strcmp(previousTab.Tag, 'Config')
                SAGA_Data_Visualizer.WipeTabGraphics(previousTab);
            end

            % Then, initialize graphics objects on the new tab, and send
            % message to the stream service indicating new configuration
            % for sending data:
            if ~app.in_configuration_mode_
                switch char(selectedTab.Tag)
                    case 'US'
                        app.mode = enum.TMSiPacketMode.StreamMode;
                        app.H = app.init_uni_stream_tab_graphics();
                        if ~app.data_running_
                            app.send_uni_stream_udp_message();
                        end
                    case 'UA'
                        app.mode = enum.TMSiPacketMode.StreamMode;
                        app.H = app.init_uni_average_tab_graphics();
                        if ~app.data_running_
                            app.send_uni_average_udp_message();
                        end
                    case 'BS'
                        app.mode = enum.TMSiPacketMode.StreamMode;
                        app.H = app.init_bip_stream_tab_graphics();
                        if ~app.data_running_
                            app.send_bip_stream_udp_message();
                        end
                    case 'BA'
                        app.mode = enum.TMSiPacketMode.StreamMode;
                        app.H = app.init_bip_average_tab_graphics();
                        if ~app.data_running_
                            app.send_bip_average_udp_message();
                        end
    %                 case 'IS'
    %                     app.mode = enum.TMSiPacketMode.TransformStreamMode;
    %                     app.H = app.init_ica_stream_tab_graphics();
    %                     app.send_ica_stream_udp_message();
    %                 case 'IR'
    %                     app.mode = enum.TMSiPacketMode.RasterMode;
    %                     app.H = app.init_ica_raster_tab_graphics();
    %                     app.send_mode_only_udp_message();  
    %                 case 'UR'
    %                     app.mode = enum.TMSiPacketMode.RasterMode;
    %                     app.H = app.init_uni_raster_tab_graphics();
    %                     app.send_mode_only_udp_message();  
    %                 case 'RC'
    %                     app.mode = enum.TMSiPacketMode.ContourMode;
    %                     app.H = app.init_rms_contour_tab_graphics();
    %                     app.send_mode_only_udp_message();
                    case 'Config'
                        app.in_configuration_mode_;
                end
            else
                if ~strcmp(app.mode, 'Config')
                    app.in_configuration_mode_ = false;
                end
            end
            
        end

        % Value changed function: ToggleAllICAChannelsSwitch
        function ToggleAllICAChannelsSwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                app.disable_ica_stream(1:numel(app.H.streams));
            else
                app.enable_ica_stream(1:numel(app.H.streams));
            end
            app.send_ica_stream_udp_message();
        end

        % Value changed function: ICA01Switch, ICA02Switch, ICA03Switch, 
        % ...and 17 other components
        function ICASwitchValueChanged(app, event)
            if strcmpi(event.PreviousValue, 'On')
                app.disable_ica_stream(str2double(event.Source.Tag));
            else
                app.enable_ica_stream(str2double(event.Source.Tag));
            end
            app.send_ica_stream_udp_message();
        end

        % Value changed function: UnipolarAverageChannelEditField
        function UnipolarAverageChannelEditFieldValueChanged(app, event)
            value = app.UnipolarAverageChannelEditField.Value;
            app.UnipolarAverageUIAxes.Title.String = sprintf("Unipolar Stim-Triggered Average: Ch-%02d", value);  
            SAGA_Data_Visualizer.WipeTabGraphics(app.TabGroup.SelectedTab);
            app.init_filters();
            app.send_bip_average_udp_message();
        end

        % Value changed function: BipolarAverageChannelEditField
        function BipolarAverageChannelEditFieldValueChanged(app, event)
            value = app.BipolarAverageChannelEditField.Value;
            app.BipolarAverageUIAxes.Title.String = sprintf("Bipolar Stim-Triggered Average: Ch-%02d", value);  
            SAGA_Data_Visualizer.WipeTabGraphics(app.TabGroup.SelectedTab);
            app.init_filters();
            app.send_uni_average_udp_message();
        end

        % Button pushed function: ResponsesConnectButton
        function ResponsesConnectButtonPushed(app, event)
            tag = event.Source.Tag;
            if app.connected.(tag)
                try %#ok<TRYNC> 
                    delete(app.rclient_);
                end
                event.Source.Text = "Connect";
                app.connected.(tag) = false;
                app.ResponsesConnectionStatusLamp.Color = [0.65,0.65,0.65];
                
                
            else
                try
                    app.rclient_ = tcpclient(app.ResponsesIPEditField.Value, app.ResponsesPortEditField.Value);
                catch
                    app.ResponsesConnectionStatusLamp.Color = [0.8 0.2 0.2];
                    return;
                end
                event.Source.Text = "Disconnect";
                app.ResponsesConnectionStatusLamp.Color = [0.39,0.83,0.07];
                app.connected.(tag) = true;  
            end
        end

        % Value changed function: TriggerSyncBitEditField
        function TriggerSyncBitEditFieldValueChanged(app, event)
            value = app.TriggerSyncBitEditField.Value;
            
        end

        % Value changed function: TriggerChannelEditField
        function TriggerChannelEditFieldValueChanged(app, event)
            value = app.TriggerChannelEditField.Value;
            
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Get the file path for locating images
            pathToMLAPP = fileparts(mfilename('fullpath'));

            % Create SAGADataViewerUIFigure and hide until all components are created
            app.SAGADataViewerUIFigure = uifigure('Visible', 'off');
            app.SAGADataViewerUIFigure.Color = [0 0.4471 0.7412];
            app.SAGADataViewerUIFigure.Position = [19 35 1011 965];
            app.SAGADataViewerUIFigure.Name = 'SAGA Data Viewer';
            app.SAGADataViewerUIFigure.Icon = fullfile(pathToMLAPP, 'outline_live_tv_black_24dp.png');
            app.SAGADataViewerUIFigure.HandleVisibility = 'on';

            % Create TabGroup
            app.TabGroup = uitabgroup(app.SAGADataViewerUIFigure);
            app.TabGroup.SelectionChangedFcn = createCallbackFcn(app, @TabGroupSelectionChanged, true);
            app.TabGroup.Position = [2 -1 1012 937];

            % Create UnipolarStreamTab
            app.UnipolarStreamTab = uitab(app.TabGroup);
            app.UnipolarStreamTab.Title = 'Unipolar Stream';
            app.UnipolarStreamTab.Tag = 'US';

            % Create UnipolarStreamGridLayout
            app.UnipolarStreamGridLayout = uigridlayout(app.UnipolarStreamTab);
            app.UnipolarStreamGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.UnipolarStreamGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.UnipolarStreamGridLayout.Scrollable = 'on';
            app.UnipolarStreamGridLayout.BackgroundColor = [1 1 1];

            % Create UnipolarUIAxes
            app.UnipolarUIAxes = uiaxes(app.UnipolarStreamGridLayout);
            title(app.UnipolarUIAxes, 'Unipolar Streams')
            xlabel(app.UnipolarUIAxes, 'Time (s)')
            ylabel(app.UnipolarUIAxes, 'Amplitude (\muV)')
            zlabel(app.UnipolarUIAxes, 'Z')
            app.UnipolarUIAxes.FontName = 'Tahoma';
            app.UnipolarUIAxes.NextPlot = 'add';
            app.UnipolarUIAxes.Layout.Row = [1 12];
            app.UnipolarUIAxes.Layout.Column = [4 9];

            % Create UnipolarStreamChannelsPanel
            app.UnipolarStreamChannelsPanel = uipanel(app.UnipolarStreamGridLayout);
            app.UnipolarStreamChannelsPanel.Title = 'Unipolar Stream Channels';
            app.UnipolarStreamChannelsPanel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.UnipolarStreamChannelsPanel.Layout.Row = [1 14];
            app.UnipolarStreamChannelsPanel.Layout.Column = [1 3];
            app.UnipolarStreamChannelsPanel.FontWeight = 'bold';
            app.UnipolarStreamChannelsPanel.Scrollable = 'on';

            % Create UNI01SwitchLabel
            app.UNI01SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI01SwitchLabel.HorizontalAlignment = 'center';
            app.UNI01SwitchLabel.Position = [14 843 40 22];
            app.UNI01SwitchLabel.Text = 'UNI01';

            % Create UNI01Switch
            app.UNI01Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI01Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI01Switch.Tag = '1';
            app.UNI01Switch.Position = [83 843 45 20];

            % Create UNI02Switch
            app.UNI02Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI02Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI02Switch.Tag = '2';
            app.UNI02Switch.Position = [83 817 45 20];

            % Create UNI02SwitchLabel
            app.UNI02SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI02SwitchLabel.HorizontalAlignment = 'center';
            app.UNI02SwitchLabel.Position = [14 816 40 22];
            app.UNI02SwitchLabel.Text = 'UNI02';

            % Create UNI03Switch
            app.UNI03Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI03Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI03Switch.Tag = '3';
            app.UNI03Switch.Position = [83 790 45 20];

            % Create UNI03SwitchLabel
            app.UNI03SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI03SwitchLabel.HorizontalAlignment = 'center';
            app.UNI03SwitchLabel.Position = [14 789 40 22];
            app.UNI03SwitchLabel.Text = 'UNI03';

            % Create UNI04Switch
            app.UNI04Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI04Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI04Switch.Tag = '4';
            app.UNI04Switch.Position = [83 763 45 20];

            % Create UNI04SwitchLabel
            app.UNI04SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI04SwitchLabel.Tag = '4';
            app.UNI04SwitchLabel.HorizontalAlignment = 'center';
            app.UNI04SwitchLabel.Position = [14 762 40 22];
            app.UNI04SwitchLabel.Text = 'UNI04';

            % Create UNI05Switch
            app.UNI05Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI05Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI05Switch.Tag = '5';
            app.UNI05Switch.Position = [83 736 45 20];

            % Create UNI05SwitchLabel
            app.UNI05SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI05SwitchLabel.Tag = '5';
            app.UNI05SwitchLabel.HorizontalAlignment = 'center';
            app.UNI05SwitchLabel.Position = [14 735 40 22];
            app.UNI05SwitchLabel.Text = 'UNI05';

            % Create UNI06Switch
            app.UNI06Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI06Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI06Switch.Tag = '6';
            app.UNI06Switch.Position = [83 709 45 20];

            % Create UNI06SwitchLabel
            app.UNI06SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI06SwitchLabel.Tag = '6';
            app.UNI06SwitchLabel.HorizontalAlignment = 'center';
            app.UNI06SwitchLabel.Position = [14 708 40 22];
            app.UNI06SwitchLabel.Text = 'UNI06';

            % Create UNI07Switch
            app.UNI07Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI07Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI07Switch.Tag = '7';
            app.UNI07Switch.Position = [83 682 45 20];

            % Create UNI07SwitchLabel
            app.UNI07SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI07SwitchLabel.Tag = '7';
            app.UNI07SwitchLabel.HorizontalAlignment = 'center';
            app.UNI07SwitchLabel.Position = [14 681 40 22];
            app.UNI07SwitchLabel.Text = 'UNI07';

            % Create UNI08Switch
            app.UNI08Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI08Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI08Switch.Tag = '8';
            app.UNI08Switch.Position = [83 655 45 20];

            % Create UNI08SwitchLabel
            app.UNI08SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI08SwitchLabel.Tag = '8';
            app.UNI08SwitchLabel.HorizontalAlignment = 'center';
            app.UNI08SwitchLabel.Position = [14 654 40 22];
            app.UNI08SwitchLabel.Text = 'UNI08';

            % Create UNI09Switch
            app.UNI09Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI09Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI09Switch.Tag = '9';
            app.UNI09Switch.Position = [83 628 45 20];

            % Create UNI09SwitchLabel
            app.UNI09SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI09SwitchLabel.HorizontalAlignment = 'center';
            app.UNI09SwitchLabel.Position = [14 627 40 22];
            app.UNI09SwitchLabel.Text = 'UNI09';

            % Create UNI10Switch
            app.UNI10Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI10Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI10Switch.Tag = '10';
            app.UNI10Switch.Position = [83 601 45 20];

            % Create UNI10SwitchLabel
            app.UNI10SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI10SwitchLabel.HorizontalAlignment = 'center';
            app.UNI10SwitchLabel.Position = [14 600 40 22];
            app.UNI10SwitchLabel.Text = 'UNI10';

            % Create UNI11Switch
            app.UNI11Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI11Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI11Switch.Tag = '11';
            app.UNI11Switch.Position = [83 574 45 20];

            % Create UNI11SwitchLabel
            app.UNI11SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI11SwitchLabel.HorizontalAlignment = 'center';
            app.UNI11SwitchLabel.Position = [15 573 38 22];
            app.UNI11SwitchLabel.Text = 'UNI11';

            % Create UNI12Switch
            app.UNI12Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI12Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI12Switch.Tag = '12';
            app.UNI12Switch.Position = [83 547 45 20];

            % Create UNI12SwitchLabel
            app.UNI12SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI12SwitchLabel.Tag = '4';
            app.UNI12SwitchLabel.HorizontalAlignment = 'center';
            app.UNI12SwitchLabel.Position = [14 546 40 22];
            app.UNI12SwitchLabel.Text = 'UNI12';

            % Create UNI13Switch
            app.UNI13Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI13Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI13Switch.Tag = '13';
            app.UNI13Switch.Position = [83 520 45 20];

            % Create UNI13SwitchLabel
            app.UNI13SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI13SwitchLabel.Tag = '5';
            app.UNI13SwitchLabel.HorizontalAlignment = 'center';
            app.UNI13SwitchLabel.Position = [14 519 40 22];
            app.UNI13SwitchLabel.Text = 'UNI13';

            % Create UNI14Switch
            app.UNI14Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI14Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI14Switch.Tag = '14';
            app.UNI14Switch.Position = [83 493 45 20];

            % Create UNI14SwitchLabel
            app.UNI14SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI14SwitchLabel.Tag = '6';
            app.UNI14SwitchLabel.HorizontalAlignment = 'center';
            app.UNI14SwitchLabel.Position = [14 492 40 22];
            app.UNI14SwitchLabel.Text = 'UNI14';

            % Create UNI15Switch
            app.UNI15Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI15Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI15Switch.Tag = '15';
            app.UNI15Switch.Position = [83 466 45 20];

            % Create UNI15SwitchLabel
            app.UNI15SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI15SwitchLabel.Tag = '7';
            app.UNI15SwitchLabel.HorizontalAlignment = 'center';
            app.UNI15SwitchLabel.Position = [14 465 40 22];
            app.UNI15SwitchLabel.Text = 'UNI15';

            % Create UNI16Switch
            app.UNI16Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI16Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI16Switch.Tag = '16';
            app.UNI16Switch.Position = [83 439 45 20];

            % Create UNI16SwitchLabel
            app.UNI16SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI16SwitchLabel.Tag = '8';
            app.UNI16SwitchLabel.HorizontalAlignment = 'center';
            app.UNI16SwitchLabel.Position = [14 438 40 22];
            app.UNI16SwitchLabel.Text = 'UNI16';

            % Create UNI17Switch
            app.UNI17Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI17Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI17Switch.Tag = '17';
            app.UNI17Switch.Position = [83 412 45 20];

            % Create UNI17SwitchLabel
            app.UNI17SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI17SwitchLabel.HorizontalAlignment = 'center';
            app.UNI17SwitchLabel.Position = [14 411 40 22];
            app.UNI17SwitchLabel.Text = 'UNI17';

            % Create UNI18Switch
            app.UNI18Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI18Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI18Switch.Tag = '18';
            app.UNI18Switch.Position = [83 385 45 20];

            % Create UNI18SwitchLabel
            app.UNI18SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI18SwitchLabel.HorizontalAlignment = 'center';
            app.UNI18SwitchLabel.Position = [14 384 40 22];
            app.UNI18SwitchLabel.Text = 'UNI18';

            % Create UNI19Switch
            app.UNI19Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI19Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI19Switch.Tag = '19';
            app.UNI19Switch.Position = [83 358 45 20];

            % Create UNI19SwitchLabel
            app.UNI19SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI19SwitchLabel.HorizontalAlignment = 'center';
            app.UNI19SwitchLabel.Position = [14 357 40 22];
            app.UNI19SwitchLabel.Text = 'UNI19';

            % Create UNI20Switch
            app.UNI20Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI20Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI20Switch.Tag = '20';
            app.UNI20Switch.Position = [83 331 45 20];

            % Create UNI20SwitchLabel
            app.UNI20SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI20SwitchLabel.Tag = '4';
            app.UNI20SwitchLabel.HorizontalAlignment = 'center';
            app.UNI20SwitchLabel.Position = [14 330 40 22];
            app.UNI20SwitchLabel.Text = 'UNI20';

            % Create UNI21Switch
            app.UNI21Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI21Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI21Switch.Tag = '21';
            app.UNI21Switch.Position = [83 304 45 20];

            % Create UNI21SwitchLabel
            app.UNI21SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI21SwitchLabel.Tag = '5';
            app.UNI21SwitchLabel.HorizontalAlignment = 'center';
            app.UNI21SwitchLabel.Position = [14 303 40 22];
            app.UNI21SwitchLabel.Text = 'UNI21';

            % Create UNI22Switch
            app.UNI22Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI22Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI22Switch.Tag = '22';
            app.UNI22Switch.Position = [83 277 45 20];

            % Create UNI22SwitchLabel
            app.UNI22SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI22SwitchLabel.Tag = '6';
            app.UNI22SwitchLabel.HorizontalAlignment = 'center';
            app.UNI22SwitchLabel.Position = [14 276 40 22];
            app.UNI22SwitchLabel.Text = 'UNI22';

            % Create UNI23Switch
            app.UNI23Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI23Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI23Switch.Tag = '23';
            app.UNI23Switch.Position = [83 251 45 20];

            % Create UNI23SwitchLabel
            app.UNI23SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI23SwitchLabel.Tag = '7';
            app.UNI23SwitchLabel.HorizontalAlignment = 'center';
            app.UNI23SwitchLabel.Position = [14 250 40 22];
            app.UNI23SwitchLabel.Text = 'UNI23';

            % Create UNI24Switch
            app.UNI24Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI24Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI24Switch.Tag = '24';
            app.UNI24Switch.Position = [83 225 45 20];

            % Create UNI24SwitchLabel
            app.UNI24SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI24SwitchLabel.Tag = '8';
            app.UNI24SwitchLabel.HorizontalAlignment = 'center';
            app.UNI24SwitchLabel.Position = [14 224 40 22];
            app.UNI24SwitchLabel.Text = 'UNI24';

            % Create UNI25Switch
            app.UNI25Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI25Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI25Switch.Tag = '25';
            app.UNI25Switch.Position = [83 199 45 20];

            % Create UNI25SwitchLabel
            app.UNI25SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI25SwitchLabel.HorizontalAlignment = 'center';
            app.UNI25SwitchLabel.Position = [14 198 40 22];
            app.UNI25SwitchLabel.Text = 'UNI25';

            % Create UNI26Switch
            app.UNI26Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI26Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI26Switch.Tag = '26';
            app.UNI26Switch.Position = [83 173 45 20];

            % Create UNI26SwitchLabel
            app.UNI26SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI26SwitchLabel.HorizontalAlignment = 'center';
            app.UNI26SwitchLabel.Position = [14 172 40 22];
            app.UNI26SwitchLabel.Text = 'UNI26';

            % Create UNI27Switch
            app.UNI27Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI27Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI27Switch.Tag = '27';
            app.UNI27Switch.Position = [83 147 45 20];

            % Create UNI27SwitchLabel
            app.UNI27SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI27SwitchLabel.HorizontalAlignment = 'center';
            app.UNI27SwitchLabel.Position = [14 146 40 22];
            app.UNI27SwitchLabel.Text = 'UNI27';

            % Create UNI28Switch
            app.UNI28Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI28Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI28Switch.Tag = '28';
            app.UNI28Switch.Position = [83 121 45 20];

            % Create UNI28SwitchLabel
            app.UNI28SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI28SwitchLabel.Tag = '4';
            app.UNI28SwitchLabel.HorizontalAlignment = 'center';
            app.UNI28SwitchLabel.Position = [14 120 40 22];
            app.UNI28SwitchLabel.Text = 'UNI28';

            % Create UNI29Switch
            app.UNI29Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI29Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI29Switch.Tag = '29';
            app.UNI29Switch.Position = [83 95 45 20];

            % Create UNI29SwitchLabel
            app.UNI29SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI29SwitchLabel.Tag = '5';
            app.UNI29SwitchLabel.HorizontalAlignment = 'center';
            app.UNI29SwitchLabel.Position = [14 94 40 22];
            app.UNI29SwitchLabel.Text = 'UNI29';

            % Create UNI30Switch
            app.UNI30Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI30Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI30Switch.Tag = '30';
            app.UNI30Switch.Position = [83 69 45 20];

            % Create UNI30SwitchLabel
            app.UNI30SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI30SwitchLabel.Tag = '6';
            app.UNI30SwitchLabel.HorizontalAlignment = 'center';
            app.UNI30SwitchLabel.Position = [14 68 40 22];
            app.UNI30SwitchLabel.Text = 'UNI30';

            % Create UNI31Switch
            app.UNI31Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI31Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI31Switch.Tag = '31';
            app.UNI31Switch.Position = [83 43 45 20];

            % Create UNI31SwitchLabel
            app.UNI31SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI31SwitchLabel.Tag = '7';
            app.UNI31SwitchLabel.HorizontalAlignment = 'center';
            app.UNI31SwitchLabel.Position = [14 42 40 22];
            app.UNI31SwitchLabel.Text = 'UNI31';

            % Create UNI32Switch
            app.UNI32Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI32Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI32Switch.Tag = '32';
            app.UNI32Switch.Position = [83 17 45 20];

            % Create UNI32SwitchLabel
            app.UNI32SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI32SwitchLabel.Tag = '8';
            app.UNI32SwitchLabel.HorizontalAlignment = 'center';
            app.UNI32SwitchLabel.Position = [14 16 40 22];
            app.UNI32SwitchLabel.Text = 'UNI32';

            % Create UNI33Switch
            app.UNI33Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI33Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI33Switch.Tag = '33';
            app.UNI33Switch.Position = [228 843 45 20];

            % Create UNI33SwitchLabel
            app.UNI33SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI33SwitchLabel.HorizontalAlignment = 'center';
            app.UNI33SwitchLabel.Position = [159 843 40 22];
            app.UNI33SwitchLabel.Text = 'UNI33';

            % Create UNI34Switch
            app.UNI34Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI34Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI34Switch.Tag = '34';
            app.UNI34Switch.Position = [228 817 45 20];

            % Create UNI34SwitchLabel
            app.UNI34SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI34SwitchLabel.HorizontalAlignment = 'center';
            app.UNI34SwitchLabel.Position = [159 816 40 22];
            app.UNI34SwitchLabel.Text = 'UNI34';

            % Create UNI35Switch
            app.UNI35Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI35Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI35Switch.Tag = '35';
            app.UNI35Switch.Position = [228 790 45 20];

            % Create UNI35SwitchLabel
            app.UNI35SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI35SwitchLabel.HorizontalAlignment = 'center';
            app.UNI35SwitchLabel.Position = [159 789 40 22];
            app.UNI35SwitchLabel.Text = 'UNI35';

            % Create UNI36Switch
            app.UNI36Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI36Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI36Switch.Tag = '36';
            app.UNI36Switch.Position = [228 763 45 20];

            % Create UNI36SwitchLabel
            app.UNI36SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI36SwitchLabel.Tag = '4';
            app.UNI36SwitchLabel.HorizontalAlignment = 'center';
            app.UNI36SwitchLabel.Position = [159 762 40 22];
            app.UNI36SwitchLabel.Text = 'UNI36';

            % Create UNI37Switch
            app.UNI37Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI37Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI37Switch.Tag = '37';
            app.UNI37Switch.Position = [228 736 45 20];

            % Create UNI37SwitchLabel
            app.UNI37SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI37SwitchLabel.Tag = '5';
            app.UNI37SwitchLabel.HorizontalAlignment = 'center';
            app.UNI37SwitchLabel.Position = [159 735 40 22];
            app.UNI37SwitchLabel.Text = 'UNI37';

            % Create UNI38Switch
            app.UNI38Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI38Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI38Switch.Tag = '38';
            app.UNI38Switch.Position = [228 709 45 20];

            % Create UNI38SwitchLabel
            app.UNI38SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI38SwitchLabel.Tag = '6';
            app.UNI38SwitchLabel.HorizontalAlignment = 'center';
            app.UNI38SwitchLabel.Position = [159 708 40 22];
            app.UNI38SwitchLabel.Text = 'UNI38';

            % Create UNI39Switch
            app.UNI39Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI39Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI39Switch.Tag = '39';
            app.UNI39Switch.Position = [228 682 45 20];

            % Create UNI39SwitchLabel
            app.UNI39SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI39SwitchLabel.Tag = '7';
            app.UNI39SwitchLabel.HorizontalAlignment = 'center';
            app.UNI39SwitchLabel.Position = [159 681 40 22];
            app.UNI39SwitchLabel.Text = 'UNI39';

            % Create UNI40Switch
            app.UNI40Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI40Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI40Switch.Tag = '40';
            app.UNI40Switch.Position = [228 655 45 20];

            % Create UNI40SwitchLabel
            app.UNI40SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI40SwitchLabel.Tag = '8';
            app.UNI40SwitchLabel.HorizontalAlignment = 'center';
            app.UNI40SwitchLabel.Position = [159 654 40 22];
            app.UNI40SwitchLabel.Text = 'UNI40';

            % Create UNI41Switch
            app.UNI41Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI41Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI41Switch.Tag = '41';
            app.UNI41Switch.Position = [228 628 45 20];

            % Create UNI41SwitchLabel
            app.UNI41SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI41SwitchLabel.HorizontalAlignment = 'center';
            app.UNI41SwitchLabel.Position = [159 627 40 22];
            app.UNI41SwitchLabel.Text = 'UNI41';

            % Create UNI42Switch
            app.UNI42Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI42Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI42Switch.Tag = '42';
            app.UNI42Switch.Position = [228 601 45 20];

            % Create UNI42SwitchLabel
            app.UNI42SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI42SwitchLabel.HorizontalAlignment = 'center';
            app.UNI42SwitchLabel.Position = [159 600 40 22];
            app.UNI42SwitchLabel.Text = 'UNI42';

            % Create UNI43Switch
            app.UNI43Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI43Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI43Switch.Tag = '43';
            app.UNI43Switch.Position = [228 574 45 20];

            % Create UNI43SwitchLabel
            app.UNI43SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI43SwitchLabel.HorizontalAlignment = 'center';
            app.UNI43SwitchLabel.Position = [159 573 40 22];
            app.UNI43SwitchLabel.Text = 'UNI43';

            % Create UNI44Switch
            app.UNI44Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI44Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI44Switch.Tag = '44';
            app.UNI44Switch.Position = [228 547 45 20];

            % Create UNI44SwitchLabel
            app.UNI44SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI44SwitchLabel.Tag = '4';
            app.UNI44SwitchLabel.HorizontalAlignment = 'center';
            app.UNI44SwitchLabel.Position = [159 546 40 22];
            app.UNI44SwitchLabel.Text = 'UNI44';

            % Create UNI45Switch
            app.UNI45Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI45Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI45Switch.Tag = '45';
            app.UNI45Switch.Position = [228 520 45 20];

            % Create UNI45SwitchLabel
            app.UNI45SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI45SwitchLabel.Tag = '5';
            app.UNI45SwitchLabel.HorizontalAlignment = 'center';
            app.UNI45SwitchLabel.Position = [159 519 40 22];
            app.UNI45SwitchLabel.Text = 'UNI45';

            % Create UNI46Switch
            app.UNI46Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI46Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI46Switch.Tag = '46';
            app.UNI46Switch.Position = [228 493 45 20];

            % Create UNI46SwitchLabel
            app.UNI46SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI46SwitchLabel.Tag = '6';
            app.UNI46SwitchLabel.HorizontalAlignment = 'center';
            app.UNI46SwitchLabel.Position = [159 492 40 22];
            app.UNI46SwitchLabel.Text = 'UNI46';

            % Create UNI47Switch
            app.UNI47Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI47Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI47Switch.Tag = '47';
            app.UNI47Switch.Position = [228 466 45 20];

            % Create UNI47SwitchLabel
            app.UNI47SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI47SwitchLabel.Tag = '7';
            app.UNI47SwitchLabel.HorizontalAlignment = 'center';
            app.UNI47SwitchLabel.Position = [159 465 40 22];
            app.UNI47SwitchLabel.Text = 'UNI47';

            % Create UNI48Switch
            app.UNI48Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI48Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI48Switch.Tag = '48';
            app.UNI48Switch.Position = [228 439 45 20];

            % Create UNI48SwitchLabel
            app.UNI48SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI48SwitchLabel.Tag = '8';
            app.UNI48SwitchLabel.HorizontalAlignment = 'center';
            app.UNI48SwitchLabel.Position = [159 438 40 22];
            app.UNI48SwitchLabel.Text = 'UNI48';

            % Create UNI49Switch
            app.UNI49Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI49Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI49Switch.Tag = '49';
            app.UNI49Switch.Position = [228 412 45 20];

            % Create UNI49SwitchLabel
            app.UNI49SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI49SwitchLabel.HorizontalAlignment = 'center';
            app.UNI49SwitchLabel.Position = [159 411 40 22];
            app.UNI49SwitchLabel.Text = 'UNI49';

            % Create UNI50Switch
            app.UNI50Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI50Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI50Switch.Tag = '50';
            app.UNI50Switch.Position = [228 385 45 20];

            % Create UNI50SwitchLabel
            app.UNI50SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI50SwitchLabel.HorizontalAlignment = 'center';
            app.UNI50SwitchLabel.Position = [159 384 40 22];
            app.UNI50SwitchLabel.Text = 'UNI50';

            % Create UNI51Switch
            app.UNI51Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI51Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI51Switch.Tag = '51';
            app.UNI51Switch.Position = [228 358 45 20];

            % Create UNI51SwitchLabel
            app.UNI51SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI51SwitchLabel.HorizontalAlignment = 'center';
            app.UNI51SwitchLabel.Position = [159 357 40 22];
            app.UNI51SwitchLabel.Text = 'UNI51';

            % Create UNI52Switch
            app.UNI52Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI52Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI52Switch.Tag = '52';
            app.UNI52Switch.Position = [228 331 45 20];

            % Create UNI52SwitchLabel
            app.UNI52SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI52SwitchLabel.Tag = '4';
            app.UNI52SwitchLabel.HorizontalAlignment = 'center';
            app.UNI52SwitchLabel.Position = [159 330 40 22];
            app.UNI52SwitchLabel.Text = 'UNI52';

            % Create UNI53Switch
            app.UNI53Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI53Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI53Switch.Tag = '53';
            app.UNI53Switch.Position = [228 304 45 20];

            % Create UNI53SwitchLabel
            app.UNI53SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI53SwitchLabel.Tag = '5';
            app.UNI53SwitchLabel.HorizontalAlignment = 'center';
            app.UNI53SwitchLabel.Position = [159 303 40 22];
            app.UNI53SwitchLabel.Text = 'UNI53';

            % Create UNI54Switch
            app.UNI54Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI54Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI54Switch.Tag = '54';
            app.UNI54Switch.Position = [228 277 45 20];

            % Create UNI54SwitchLabel
            app.UNI54SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI54SwitchLabel.Tag = '6';
            app.UNI54SwitchLabel.HorizontalAlignment = 'center';
            app.UNI54SwitchLabel.Position = [159 276 40 22];
            app.UNI54SwitchLabel.Text = 'UNI54';

            % Create UNI55Switch
            app.UNI55Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI55Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI55Switch.Tag = '55';
            app.UNI55Switch.Position = [228 251 45 20];

            % Create UNI55SwitchLabel
            app.UNI55SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI55SwitchLabel.Tag = '7';
            app.UNI55SwitchLabel.HorizontalAlignment = 'center';
            app.UNI55SwitchLabel.Position = [159 250 40 22];
            app.UNI55SwitchLabel.Text = 'UNI55';

            % Create UNI56Switch
            app.UNI56Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI56Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI56Switch.Tag = '56';
            app.UNI56Switch.Position = [228 225 45 20];

            % Create UNI56SwitchLabel
            app.UNI56SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI56SwitchLabel.Tag = '8';
            app.UNI56SwitchLabel.HorizontalAlignment = 'center';
            app.UNI56SwitchLabel.Position = [159 224 40 22];
            app.UNI56SwitchLabel.Text = 'UNI56';

            % Create UNI57Switch
            app.UNI57Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI57Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI57Switch.Tag = '57';
            app.UNI57Switch.Position = [228 199 45 20];

            % Create UNI57SwitchLabel
            app.UNI57SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI57SwitchLabel.HorizontalAlignment = 'center';
            app.UNI57SwitchLabel.Position = [159 198 40 22];
            app.UNI57SwitchLabel.Text = 'UNI57';

            % Create UNI58Switch
            app.UNI58Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI58Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI58Switch.Tag = '58';
            app.UNI58Switch.Position = [228 173 45 20];

            % Create UNI58SwitchLabel
            app.UNI58SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI58SwitchLabel.HorizontalAlignment = 'center';
            app.UNI58SwitchLabel.Position = [159 172 40 22];
            app.UNI58SwitchLabel.Text = 'UNI58';

            % Create UNI59Switch
            app.UNI59Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI59Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI59Switch.Tag = '59';
            app.UNI59Switch.Position = [228 147 45 20];

            % Create UNI59SwitchLabel
            app.UNI59SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI59SwitchLabel.HorizontalAlignment = 'center';
            app.UNI59SwitchLabel.Position = [159 146 40 22];
            app.UNI59SwitchLabel.Text = 'UNI59';

            % Create UNI60Switch
            app.UNI60Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI60Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI60Switch.Tag = '60';
            app.UNI60Switch.Position = [228 121 45 20];

            % Create UNI60SwitchLabel
            app.UNI60SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI60SwitchLabel.Tag = '4';
            app.UNI60SwitchLabel.HorizontalAlignment = 'center';
            app.UNI60SwitchLabel.Position = [159 120 40 22];
            app.UNI60SwitchLabel.Text = 'UNI60';

            % Create UNI61Switch
            app.UNI61Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI61Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI61Switch.Tag = '61';
            app.UNI61Switch.Position = [228 95 45 20];

            % Create UNI61SwitchLabel
            app.UNI61SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI61SwitchLabel.Tag = '5';
            app.UNI61SwitchLabel.HorizontalAlignment = 'center';
            app.UNI61SwitchLabel.Position = [159 94 40 22];
            app.UNI61SwitchLabel.Text = 'UNI61';

            % Create UNI62Switch
            app.UNI62Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI62Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI62Switch.Tag = '62';
            app.UNI62Switch.Position = [228 69 45 20];

            % Create UNI62SwitchLabel
            app.UNI62SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI62SwitchLabel.Tag = '6';
            app.UNI62SwitchLabel.HorizontalAlignment = 'center';
            app.UNI62SwitchLabel.Position = [159 68 40 22];
            app.UNI62SwitchLabel.Text = 'UNI62';

            % Create UNI63Switch
            app.UNI63Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI63Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI63Switch.Tag = '63';
            app.UNI63Switch.Position = [228 43 45 20];

            % Create UNI63SwitchLabel
            app.UNI63SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI63SwitchLabel.Tag = '7';
            app.UNI63SwitchLabel.HorizontalAlignment = 'center';
            app.UNI63SwitchLabel.Position = [159 42 40 22];
            app.UNI63SwitchLabel.Text = 'UNI63';

            % Create UNI64Switch
            app.UNI64Switch = uiswitch(app.UnipolarStreamChannelsPanel, 'slider');
            app.UNI64Switch.ValueChangedFcn = createCallbackFcn(app, @UnipolarChannelSwitchValueChanged, true);
            app.UNI64Switch.Tag = '64';
            app.UNI64Switch.Position = [228 17 45 20];

            % Create UNI64SwitchLabel
            app.UNI64SwitchLabel = uilabel(app.UnipolarStreamChannelsPanel);
            app.UNI64SwitchLabel.Tag = '8';
            app.UNI64SwitchLabel.HorizontalAlignment = 'center';
            app.UNI64SwitchLabel.Position = [159 16 40 22];
            app.UNI64SwitchLabel.Text = 'UNI64';

            % Create UnipolarStreamSettingsPanel
            app.UnipolarStreamSettingsPanel = uipanel(app.UnipolarStreamGridLayout);
            app.UnipolarStreamSettingsPanel.Title = 'Unipolar Stream Settings';
            app.UnipolarStreamSettingsPanel.Layout.Row = [13 14];
            app.UnipolarStreamSettingsPanel.Layout.Column = [4 9];
            app.UnipolarStreamSettingsPanel.FontWeight = 'bold';

            % Create AllChannelsSwitchLabel
            app.AllChannelsSwitchLabel = uilabel(app.UnipolarStreamSettingsPanel);
            app.AllChannelsSwitchLabel.HorizontalAlignment = 'center';
            app.AllChannelsSwitchLabel.Position = [583 95 73 22];
            app.AllChannelsSwitchLabel.Text = 'All Channels';

            % Create ToggleAllUnipolarChannelsSwitch
            app.ToggleAllUnipolarChannelsSwitch = uiswitch(app.UnipolarStreamSettingsPanel, 'toggle');
            app.ToggleAllUnipolarChannelsSwitch.ValueChangedFcn = createCallbackFcn(app, @ToggleAllUnipolarChannelsSwitchValueChanged, true);
            app.ToggleAllUnipolarChannelsSwitch.FontWeight = 'bold';
            app.ToggleAllUnipolarChannelsSwitch.Position = [622 27 18 42];

            % Create PerChannelOffsetVEditFieldLabel
            app.PerChannelOffsetVEditFieldLabel = uilabel(app.UnipolarStreamSettingsPanel);
            app.PerChannelOffsetVEditFieldLabel.HorizontalAlignment = 'right';
            app.PerChannelOffsetVEditFieldLabel.FontName = 'Tahoma';
            app.PerChannelOffsetVEditFieldLabel.FontSize = 16;
            app.PerChannelOffsetVEditFieldLabel.Position = [148 19 174 22];
            app.PerChannelOffsetVEditFieldLabel.Text = 'Per-Channel Offset (µV)';

            % Create UnipolarPerChannelOffsetEditField
            app.UnipolarPerChannelOffsetEditField = uieditfield(app.UnipolarStreamSettingsPanel, 'numeric');
            app.UnipolarPerChannelOffsetEditField.Limits = [0 5000];
            app.UnipolarPerChannelOffsetEditField.RoundFractionalValues = 'on';
            app.UnipolarPerChannelOffsetEditField.ValueChangedFcn = createCallbackFcn(app, @PerChannelOffsetEditFieldValueChanged, true);
            app.UnipolarPerChannelOffsetEditField.Tag = 'UNI';
            app.UnipolarPerChannelOffsetEditField.FontName = 'Tahoma';
            app.UnipolarPerChannelOffsetEditField.FontSize = 16;
            app.UnipolarPerChannelOffsetEditField.Position = [337 19 250 22];
            app.UnipolarPerChannelOffsetEditField.Value = 200;

            % Create UnipolarFilterCheckBox
            app.UnipolarFilterCheckBox = uicheckbox(app.UnipolarStreamSettingsPanel);
            app.UnipolarFilterCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarFilterCheckBox.Text = 'Filter';
            app.UnipolarFilterCheckBox.FontName = 'Tahoma';
            app.UnipolarFilterCheckBox.Position = [33 61 49 22];
            app.UnipolarFilterCheckBox.Value = true;

            % Create Cutoff1HzEditFieldLabel
            app.Cutoff1HzEditFieldLabel = uilabel(app.UnipolarStreamSettingsPanel);
            app.Cutoff1HzEditFieldLabel.HorizontalAlignment = 'right';
            app.Cutoff1HzEditFieldLabel.FontName = 'Tahoma';
            app.Cutoff1HzEditFieldLabel.FontSize = 16;
            app.Cutoff1HzEditFieldLabel.Position = [147 61 97 22];
            app.Cutoff1HzEditFieldLabel.Text = 'Cutoff 1 (Hz)';

            % Create UnipolarCutoff1EditField
            app.UnipolarCutoff1EditField = uieditfield(app.UnipolarStreamSettingsPanel, 'numeric');
            app.UnipolarCutoff1EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarCutoff1EditField.Tag = 'fc_low';
            app.UnipolarCutoff1EditField.FontName = 'Tahoma';
            app.UnipolarCutoff1EditField.FontSize = 16;
            app.UnipolarCutoff1EditField.Position = [259 61 100 22];
            app.UnipolarCutoff1EditField.Value = 25;

            % Create Cutoff2HzEditFieldLabel
            app.Cutoff2HzEditFieldLabel = uilabel(app.UnipolarStreamSettingsPanel);
            app.Cutoff2HzEditFieldLabel.HorizontalAlignment = 'right';
            app.Cutoff2HzEditFieldLabel.FontName = 'Tahoma';
            app.Cutoff2HzEditFieldLabel.FontSize = 16;
            app.Cutoff2HzEditFieldLabel.Position = [375 61 97 22];
            app.Cutoff2HzEditFieldLabel.Text = 'Cutoff 2 (Hz)';

            % Create UnipolarCutoff2EditField
            app.UnipolarCutoff2EditField = uieditfield(app.UnipolarStreamSettingsPanel, 'numeric');
            app.UnipolarCutoff2EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarCutoff2EditField.Tag = 'fc_high';
            app.UnipolarCutoff2EditField.FontName = 'Tahoma';
            app.UnipolarCutoff2EditField.FontSize = 16;
            app.UnipolarCutoff2EditField.Position = [487 61 100 22];
            app.UnipolarCutoff2EditField.Value = 400;

            % Create UnipolarCARCheckBox
            app.UnipolarCARCheckBox = uicheckbox(app.UnipolarStreamSettingsPanel);
            app.UnipolarCARCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarCARCheckBox.Text = 'CAR';
            app.UnipolarCARCheckBox.FontName = 'Tahoma';
            app.UnipolarCARCheckBox.Position = [34 19 44 22];
            app.UnipolarCARCheckBox.Value = true;

            % Create UnipolarAverageTab
            app.UnipolarAverageTab = uitab(app.TabGroup);
            app.UnipolarAverageTab.Title = 'Unipolar Average';
            app.UnipolarAverageTab.BackgroundColor = [1 1 1];
            app.UnipolarAverageTab.Tag = 'UA';

            % Create UnipolarAverageGridLayout
            app.UnipolarAverageGridLayout = uigridlayout(app.UnipolarAverageTab);
            app.UnipolarAverageGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.UnipolarAverageGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.UnipolarAverageGridLayout.BackgroundColor = [1 1 1];

            % Create UnipolarAverageUIAxes
            app.UnipolarAverageUIAxes = uiaxes(app.UnipolarAverageGridLayout);
            title(app.UnipolarAverageUIAxes, 'Unipolar Stim-Triggered Average: Ch-10')
            xlabel(app.UnipolarAverageUIAxes, 'Time (ms)')
            ylabel(app.UnipolarAverageUIAxes, 'EMG Amplitude (\muV)')
            zlabel(app.UnipolarAverageUIAxes, 'Z')
            app.UnipolarAverageUIAxes.FontName = 'Tahoma';
            app.UnipolarAverageUIAxes.TitleHorizontalAlignment = 'right';
            app.UnipolarAverageUIAxes.FontSize = 16;
            app.UnipolarAverageUIAxes.NextPlot = 'add';
            app.UnipolarAverageUIAxes.Layout.Row = [1 13];
            app.UnipolarAverageUIAxes.Layout.Column = [1 5];

            % Create UnipolarAverageSettingsPanel
            app.UnipolarAverageSettingsPanel = uipanel(app.UnipolarAverageGridLayout);
            app.UnipolarAverageSettingsPanel.Title = 'Unipolar Average Settings';
            app.UnipolarAverageSettingsPanel.Layout.Row = [14 15];
            app.UnipolarAverageSettingsPanel.Layout.Column = [1 5];
            app.UnipolarAverageSettingsPanel.FontWeight = 'bold';

            % Create UNIChannelEditFieldLabel
            app.UNIChannelEditFieldLabel = uilabel(app.UnipolarAverageSettingsPanel);
            app.UNIChannelEditFieldLabel.HorizontalAlignment = 'right';
            app.UNIChannelEditFieldLabel.FontName = 'Tahoma';
            app.UNIChannelEditFieldLabel.FontSize = 16;
            app.UNIChannelEditFieldLabel.FontWeight = 'bold';
            app.UNIChannelEditFieldLabel.Position = [27 56 107 22];
            app.UNIChannelEditFieldLabel.Text = 'UNI Channel';

            % Create UnipolarAverageChannelEditField
            app.UnipolarAverageChannelEditField = uieditfield(app.UnipolarAverageSettingsPanel, 'numeric');
            app.UnipolarAverageChannelEditField.ValueChangedFcn = createCallbackFcn(app, @UnipolarAverageChannelEditFieldValueChanged, true);
            app.UnipolarAverageChannelEditField.HorizontalAlignment = 'center';
            app.UnipolarAverageChannelEditField.FontName = 'Tahoma';
            app.UnipolarAverageChannelEditField.FontSize = 16;
            app.UnipolarAverageChannelEditField.FontWeight = 'bold';
            app.UnipolarAverageChannelEditField.Position = [149 56 58 22];
            app.UnipolarAverageChannelEditField.Value = 10;

            % Create UnipolarAverageFilterCheckBox
            app.UnipolarAverageFilterCheckBox = uicheckbox(app.UnipolarAverageSettingsPanel);
            app.UnipolarAverageFilterCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageFilterCheckBox.Text = 'Filter';
            app.UnipolarAverageFilterCheckBox.FontName = 'Tahoma';
            app.UnipolarAverageFilterCheckBox.Position = [468 60 49 22];
            app.UnipolarAverageFilterCheckBox.Value = true;

            % Create Cutoff1HzEditFieldLabel_2
            app.Cutoff1HzEditFieldLabel_2 = uilabel(app.UnipolarAverageSettingsPanel);
            app.Cutoff1HzEditFieldLabel_2.HorizontalAlignment = 'right';
            app.Cutoff1HzEditFieldLabel_2.FontName = 'Tahoma';
            app.Cutoff1HzEditFieldLabel_2.FontSize = 16;
            app.Cutoff1HzEditFieldLabel_2.Position = [531 60 97 22];
            app.Cutoff1HzEditFieldLabel_2.Text = 'Cutoff 1 (Hz)';

            % Create UnipolarAverageCutoff1EditField
            app.UnipolarAverageCutoff1EditField = uieditfield(app.UnipolarAverageSettingsPanel, 'numeric');
            app.UnipolarAverageCutoff1EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageCutoff1EditField.Tag = 'fc_low';
            app.UnipolarAverageCutoff1EditField.FontName = 'Tahoma';
            app.UnipolarAverageCutoff1EditField.FontSize = 16;
            app.UnipolarAverageCutoff1EditField.Position = [643 60 100 22];
            app.UnipolarAverageCutoff1EditField.Value = 25;

            % Create Cutoff2HzEditFieldLabel_2
            app.Cutoff2HzEditFieldLabel_2 = uilabel(app.UnipolarAverageSettingsPanel);
            app.Cutoff2HzEditFieldLabel_2.HorizontalAlignment = 'right';
            app.Cutoff2HzEditFieldLabel_2.FontName = 'Tahoma';
            app.Cutoff2HzEditFieldLabel_2.FontSize = 16;
            app.Cutoff2HzEditFieldLabel_2.Position = [773 60 97 22];
            app.Cutoff2HzEditFieldLabel_2.Text = 'Cutoff 2 (Hz)';

            % Create UnipolarAverageCutoff2EditField
            app.UnipolarAverageCutoff2EditField = uieditfield(app.UnipolarAverageSettingsPanel, 'numeric');
            app.UnipolarAverageCutoff2EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageCutoff2EditField.Tag = 'fc_high';
            app.UnipolarAverageCutoff2EditField.FontName = 'Tahoma';
            app.UnipolarAverageCutoff2EditField.FontSize = 16;
            app.UnipolarAverageCutoff2EditField.Position = [885 60 100 22];
            app.UnipolarAverageCutoff2EditField.Value = 400;

            % Create UnipolarAverageCARCheckBox
            app.UnipolarAverageCARCheckBox = uicheckbox(app.UnipolarAverageSettingsPanel);
            app.UnipolarAverageCARCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageCARCheckBox.Text = 'CAR';
            app.UnipolarAverageCARCheckBox.FontName = 'Tahoma';
            app.UnipolarAverageCARCheckBox.Position = [401 60 44 22];
            app.UnipolarAverageCARCheckBox.Value = true;

            % Create StartDatamsSpinnerLabel
            app.StartDatamsSpinnerLabel = uilabel(app.UnipolarAverageSettingsPanel);
            app.StartDatamsSpinnerLabel.HorizontalAlignment = 'right';
            app.StartDatamsSpinnerLabel.FontName = 'Tahoma';
            app.StartDatamsSpinnerLabel.FontSize = 16;
            app.StartDatamsSpinnerLabel.Position = [514 19 115 22];
            app.StartDatamsSpinnerLabel.Text = 'Start Data (ms)';

            % Create StartUnipolarAverageSpinner
            app.StartUnipolarAverageSpinner = uispinner(app.UnipolarAverageSettingsPanel);
            app.StartUnipolarAverageSpinner.Step = 5;
            app.StartUnipolarAverageSpinner.Limits = [-250 0];
            app.StartUnipolarAverageSpinner.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.StartUnipolarAverageSpinner.FontName = 'Tahoma';
            app.StartUnipolarAverageSpinner.FontSize = 16;
            app.StartUnipolarAverageSpinner.Position = [644 19 100 22];
            app.StartUnipolarAverageSpinner.Value = -20;

            % Create StopDatamsSpinnerLabel
            app.StopDatamsSpinnerLabel = uilabel(app.UnipolarAverageSettingsPanel);
            app.StopDatamsSpinnerLabel.HorizontalAlignment = 'right';
            app.StopDatamsSpinnerLabel.FontName = 'Tahoma';
            app.StopDatamsSpinnerLabel.FontSize = 16;
            app.StopDatamsSpinnerLabel.Position = [755 19 113 22];
            app.StopDatamsSpinnerLabel.Text = 'Stop Data (ms)';

            % Create StopUnipolarAverageSpinner
            app.StopUnipolarAverageSpinner = uispinner(app.UnipolarAverageSettingsPanel);
            app.StopUnipolarAverageSpinner.Step = 5;
            app.StopUnipolarAverageSpinner.Limits = [0 250];
            app.StopUnipolarAverageSpinner.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.StopUnipolarAverageSpinner.FontName = 'Tahoma';
            app.StopUnipolarAverageSpinner.FontSize = 16;
            app.StopUnipolarAverageSpinner.Position = [883 19 100 22];
            app.StopUnipolarAverageSpinner.Value = 40;

            % Create NEditFieldLabel
            app.NEditFieldLabel = uilabel(app.UnipolarAverageSettingsPanel);
            app.NEditFieldLabel.HorizontalAlignment = 'right';
            app.NEditFieldLabel.FontSize = 16;
            app.NEditFieldLabel.FontWeight = 'bold';
            app.NEditFieldLabel.Position = [359 19 25 22];
            app.NEditFieldLabel.Text = 'N';

            % Create UnipolarAverageNEditField
            app.UnipolarAverageNEditField = uieditfield(app.UnipolarAverageSettingsPanel, 'numeric');
            app.UnipolarAverageNEditField.Limits = [1 100];
            app.UnipolarAverageNEditField.RoundFractionalValues = 'on';
            app.UnipolarAverageNEditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageNEditField.HorizontalAlignment = 'center';
            app.UnipolarAverageNEditField.FontName = 'Tahoma';
            app.UnipolarAverageNEditField.FontSize = 16;
            app.UnipolarAverageNEditField.Position = [394 20 65 22];
            app.UnipolarAverageNEditField.Value = 30;

            % Create ResetUnipolarAverageButton
            app.ResetUnipolarAverageButton = uibutton(app.UnipolarAverageSettingsPanel, 'push');
            app.ResetUnipolarAverageButton.ButtonPushedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.ResetUnipolarAverageButton.FontName = 'Tahoma';
            app.ResetUnipolarAverageButton.FontSize = 20;
            app.ResetUnipolarAverageButton.FontWeight = 'bold';
            app.ResetUnipolarAverageButton.FontColor = [1 0 0];
            app.ResetUnipolarAverageButton.Position = [30 10 177 34];
            app.ResetUnipolarAverageButton.Text = 'Reset';

            % Create UnipolarAverageRectifyCheckBox
            app.UnipolarAverageRectifyCheckBox = uicheckbox(app.UnipolarAverageSettingsPanel);
            app.UnipolarAverageRectifyCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.UnipolarAverageRectifyCheckBox.Text = 'Rectify';
            app.UnipolarAverageRectifyCheckBox.FontName = 'Tahoma';
            app.UnipolarAverageRectifyCheckBox.Position = [334 61 58 22];
            app.UnipolarAverageRectifyCheckBox.Value = true;

            % Create UnipolarRasterTab
            app.UnipolarRasterTab = uitab(app.TabGroup);
            app.UnipolarRasterTab.Title = 'Unipolar Raster';
            app.UnipolarRasterTab.BackgroundColor = [1 1 1];
            app.UnipolarRasterTab.Tag = 'UR';

            % Create UnipolarRasterGridLayout
            app.UnipolarRasterGridLayout = uigridlayout(app.UnipolarRasterTab);
            app.UnipolarRasterGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.UnipolarRasterGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.UnipolarRasterGridLayout.BackgroundColor = [1 1 1];

            % Create UnipolarRasterSettingsPanel
            app.UnipolarRasterSettingsPanel = uipanel(app.UnipolarRasterGridLayout);
            app.UnipolarRasterSettingsPanel.Title = 'Unipolar Raster Settings';
            app.UnipolarRasterSettingsPanel.Layout.Row = [14 15];
            app.UnipolarRasterSettingsPanel.Layout.Column = [1 5];
            app.UnipolarRasterSettingsPanel.FontWeight = 'bold';

            % Create BipolarStreamTab
            app.BipolarStreamTab = uitab(app.TabGroup);
            app.BipolarStreamTab.Title = 'Bipolar Stream';
            app.BipolarStreamTab.BackgroundColor = [1 1 1];
            app.BipolarStreamTab.Tag = 'BS';

            % Create BipolarStreamGridLayout
            app.BipolarStreamGridLayout = uigridlayout(app.BipolarStreamTab);
            app.BipolarStreamGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.BipolarStreamGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.BipolarStreamGridLayout.BackgroundColor = [1 1 1];

            % Create BipolarUIAxes
            app.BipolarUIAxes = uiaxes(app.BipolarStreamGridLayout);
            title(app.BipolarUIAxes, 'Bipolar Streams')
            xlabel(app.BipolarUIAxes, 'Time (s)')
            ylabel(app.BipolarUIAxes, 'Amplitude (\muV)')
            zlabel(app.BipolarUIAxes, 'Z')
            app.BipolarUIAxes.NextPlot = 'add';
            app.BipolarUIAxes.Layout.Row = [1 15];
            app.BipolarUIAxes.Layout.Column = [2 5];

            % Create BipolarStreamChannelsPanel
            app.BipolarStreamChannelsPanel = uipanel(app.BipolarStreamGridLayout);
            app.BipolarStreamChannelsPanel.Title = 'Bipolar Stream Channels';
            app.BipolarStreamChannelsPanel.Layout.Row = [1 4];
            app.BipolarStreamChannelsPanel.Layout.Column = 1;
            app.BipolarStreamChannelsPanel.FontWeight = 'bold';

            % Create BIP01SwitchLabel
            app.BIP01SwitchLabel = uilabel(app.BipolarStreamChannelsPanel);
            app.BIP01SwitchLabel.HorizontalAlignment = 'center';
            app.BIP01SwitchLabel.Position = [25 175 38 22];
            app.BIP01SwitchLabel.Text = 'BIP01';

            % Create BIP01Switch
            app.BIP01Switch = uiswitch(app.BipolarStreamChannelsPanel, 'slider');
            app.BIP01Switch.ValueChangedFcn = createCallbackFcn(app, @BipolarSwitchValueChanged, true);
            app.BIP01Switch.Tag = '1';
            app.BIP01Switch.Position = [93 175 45 20];

            % Create BIP02Switch
            app.BIP02Switch = uiswitch(app.BipolarStreamChannelsPanel, 'slider');
            app.BIP02Switch.ValueChangedFcn = createCallbackFcn(app, @BipolarSwitchValueChanged, true);
            app.BIP02Switch.Tag = '2';
            app.BIP02Switch.Position = [92 126 45 20];

            % Create BIP02SwitchLabel
            app.BIP02SwitchLabel = uilabel(app.BipolarStreamChannelsPanel);
            app.BIP02SwitchLabel.HorizontalAlignment = 'center';
            app.BIP02SwitchLabel.Position = [24 125 38 22];
            app.BIP02SwitchLabel.Text = 'BIP02';

            % Create BIP03Switch
            app.BIP03Switch = uiswitch(app.BipolarStreamChannelsPanel, 'slider');
            app.BIP03Switch.ValueChangedFcn = createCallbackFcn(app, @BipolarSwitchValueChanged, true);
            app.BIP03Switch.Tag = '3';
            app.BIP03Switch.Position = [92 77 45 20];

            % Create BIP03SwitchLabel
            app.BIP03SwitchLabel = uilabel(app.BipolarStreamChannelsPanel);
            app.BIP03SwitchLabel.HorizontalAlignment = 'center';
            app.BIP03SwitchLabel.Position = [24 76 38 22];
            app.BIP03SwitchLabel.Text = 'BIP03';

            % Create BIP04Switch
            app.BIP04Switch = uiswitch(app.BipolarStreamChannelsPanel, 'slider');
            app.BIP04Switch.ValueChangedFcn = createCallbackFcn(app, @BipolarSwitchValueChanged, true);
            app.BIP04Switch.Tag = '4';
            app.BIP04Switch.Position = [93 28 45 20];

            % Create BIP04SwitchLabel
            app.BIP04SwitchLabel = uilabel(app.BipolarStreamChannelsPanel);
            app.BIP04SwitchLabel.Tag = '4';
            app.BIP04SwitchLabel.HorizontalAlignment = 'center';
            app.BIP04SwitchLabel.Position = [25 27 38 22];
            app.BIP04SwitchLabel.Text = 'BIP04';

            % Create BipolarStreamSettingsPanel
            app.BipolarStreamSettingsPanel = uipanel(app.BipolarStreamGridLayout);
            app.BipolarStreamSettingsPanel.Title = 'Bipolar Stream Settings';
            app.BipolarStreamSettingsPanel.Layout.Row = [5 15];
            app.BipolarStreamSettingsPanel.Layout.Column = 1;
            app.BipolarStreamSettingsPanel.FontWeight = 'bold';

            % Create ToggleAllBipolarChannelsSwitchLabel
            app.ToggleAllBipolarChannelsSwitchLabel = uilabel(app.BipolarStreamSettingsPanel);
            app.ToggleAllBipolarChannelsSwitchLabel.HorizontalAlignment = 'center';
            app.ToggleAllBipolarChannelsSwitchLabel.Position = [59 591 73 22];
            app.ToggleAllBipolarChannelsSwitchLabel.Text = 'All Channels';

            % Create ToggleAllBipolarChannelsSwitch
            app.ToggleAllBipolarChannelsSwitch = uiswitch(app.BipolarStreamSettingsPanel, 'toggle');
            app.ToggleAllBipolarChannelsSwitch.ValueChangedFcn = createCallbackFcn(app, @ToggleAllBipolarChannelsSwitchValueChanged, true);
            app.ToggleAllBipolarChannelsSwitch.FontWeight = 'bold';
            app.ToggleAllBipolarChannelsSwitch.Position = [86 523 18 42];
            app.ToggleAllBipolarChannelsSwitch.Value = 'On';

            % Create BipolarFilterCheckBox
            app.BipolarFilterCheckBox = uicheckbox(app.BipolarStreamSettingsPanel);
            app.BipolarFilterCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarFilterCheckBox.Text = 'Filter';
            app.BipolarFilterCheckBox.FontName = 'Tahoma';
            app.BipolarFilterCheckBox.Position = [10 459 49 22];
            app.BipolarFilterCheckBox.Value = true;

            % Create BipolarPerChannelOffsetVEditFieldLabel
            app.BipolarPerChannelOffsetVEditFieldLabel = uilabel(app.BipolarStreamSettingsPanel);
            app.BipolarPerChannelOffsetVEditFieldLabel.HorizontalAlignment = 'right';
            app.BipolarPerChannelOffsetVEditFieldLabel.FontName = 'Tahoma';
            app.BipolarPerChannelOffsetVEditFieldLabel.FontSize = 16;
            app.BipolarPerChannelOffsetVEditFieldLabel.Position = [7 373 174 22];
            app.BipolarPerChannelOffsetVEditFieldLabel.Text = 'Per-Channel Offset (µV)';

            % Create BipolarPerChannelOffsetEditField
            app.BipolarPerChannelOffsetEditField = uieditfield(app.BipolarStreamSettingsPanel, 'numeric');
            app.BipolarPerChannelOffsetEditField.ValueChangedFcn = createCallbackFcn(app, @PerChannelOffsetEditFieldValueChanged, true);
            app.BipolarPerChannelOffsetEditField.Tag = 'BIP';
            app.BipolarPerChannelOffsetEditField.FontName = 'Tahoma';
            app.BipolarPerChannelOffsetEditField.FontSize = 16;
            app.BipolarPerChannelOffsetEditField.Position = [6 346 172 22];
            app.BipolarPerChannelOffsetEditField.Value = 200;

            % Create BipolarCutoff1EditFieldLabel
            app.BipolarCutoff1EditFieldLabel = uilabel(app.BipolarStreamSettingsPanel);
            app.BipolarCutoff1EditFieldLabel.HorizontalAlignment = 'right';
            app.BipolarCutoff1EditFieldLabel.FontName = 'Tahoma';
            app.BipolarCutoff1EditFieldLabel.FontSize = 16;
            app.BipolarCutoff1EditFieldLabel.Position = [0 432 97 22];
            app.BipolarCutoff1EditFieldLabel.Text = 'Cutoff 1 (Hz)';

            % Create BipolarCutoff1EditField
            app.BipolarCutoff1EditField = uieditfield(app.BipolarStreamSettingsPanel, 'numeric');
            app.BipolarCutoff1EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarCutoff1EditField.Tag = 'fc_low';
            app.BipolarCutoff1EditField.FontName = 'Tahoma';
            app.BipolarCutoff1EditField.FontSize = 16;
            app.BipolarCutoff1EditField.Position = [112 432 68 22];
            app.BipolarCutoff1EditField.Value = 25;

            % Create BipolarCutoff2EditFieldLabel
            app.BipolarCutoff2EditFieldLabel = uilabel(app.BipolarStreamSettingsPanel);
            app.BipolarCutoff2EditFieldLabel.HorizontalAlignment = 'right';
            app.BipolarCutoff2EditFieldLabel.FontName = 'Tahoma';
            app.BipolarCutoff2EditFieldLabel.FontSize = 16;
            app.BipolarCutoff2EditFieldLabel.Position = [1 405 97 22];
            app.BipolarCutoff2EditFieldLabel.Text = 'Cutoff 2 (Hz)';

            % Create BipolarCutoff2EditField
            app.BipolarCutoff2EditField = uieditfield(app.BipolarStreamSettingsPanel, 'numeric');
            app.BipolarCutoff2EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarCutoff2EditField.Tag = 'fc_high';
            app.BipolarCutoff2EditField.FontName = 'Tahoma';
            app.BipolarCutoff2EditField.FontSize = 16;
            app.BipolarCutoff2EditField.Position = [113 405 67 22];
            app.BipolarCutoff2EditField.Value = 400;

            % Create BipolarAverageTab
            app.BipolarAverageTab = uitab(app.TabGroup);
            app.BipolarAverageTab.Title = 'Bipolar Average';
            app.BipolarAverageTab.BackgroundColor = [1 1 1];
            app.BipolarAverageTab.Tag = 'BA';

            % Create BipolarAverageGridLayout
            app.BipolarAverageGridLayout = uigridlayout(app.BipolarAverageTab);
            app.BipolarAverageGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.BipolarAverageGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.BipolarAverageGridLayout.BackgroundColor = [1 1 1];

            % Create BipolarAverageUIAxes
            app.BipolarAverageUIAxes = uiaxes(app.BipolarAverageGridLayout);
            title(app.BipolarAverageUIAxes, 'Bipolar Stim-Triggered Average: Ch-01')
            xlabel(app.BipolarAverageUIAxes, 'Time (ms)')
            ylabel(app.BipolarAverageUIAxes, 'EMG Amplitude (\muV)')
            zlabel(app.BipolarAverageUIAxes, 'Z')
            app.BipolarAverageUIAxes.FontName = 'Tahoma';
            app.BipolarAverageUIAxes.TitleHorizontalAlignment = 'right';
            app.BipolarAverageUIAxes.FontSize = 16;
            app.BipolarAverageUIAxes.NextPlot = 'add';
            app.BipolarAverageUIAxes.Layout.Row = [1 13];
            app.BipolarAverageUIAxes.Layout.Column = [1 5];

            % Create BipolarAverageSettingsPanel
            app.BipolarAverageSettingsPanel = uipanel(app.BipolarAverageGridLayout);
            app.BipolarAverageSettingsPanel.Title = 'Bipolar Average Settings';
            app.BipolarAverageSettingsPanel.Layout.Row = [14 15];
            app.BipolarAverageSettingsPanel.Layout.Column = [1 5];
            app.BipolarAverageSettingsPanel.FontWeight = 'bold';

            % Create BipolarAverageFilterCheckBox
            app.BipolarAverageFilterCheckBox = uicheckbox(app.BipolarAverageSettingsPanel);
            app.BipolarAverageFilterCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarAverageFilterCheckBox.Text = 'Filter';
            app.BipolarAverageFilterCheckBox.FontName = 'Tahoma';
            app.BipolarAverageFilterCheckBox.Position = [418 59 49 22];
            app.BipolarAverageFilterCheckBox.Value = true;

            % Create BIPChannelLabel
            app.BIPChannelLabel = uilabel(app.BipolarAverageSettingsPanel);
            app.BIPChannelLabel.HorizontalAlignment = 'right';
            app.BIPChannelLabel.FontName = 'Tahoma';
            app.BIPChannelLabel.FontSize = 16;
            app.BIPChannelLabel.FontWeight = 'bold';
            app.BIPChannelLabel.Position = [98 59 105 22];
            app.BIPChannelLabel.Text = 'BIP Channel';

            % Create BipolarAverageChannelEditField
            app.BipolarAverageChannelEditField = uieditfield(app.BipolarAverageSettingsPanel, 'numeric');
            app.BipolarAverageChannelEditField.ValueChangedFcn = createCallbackFcn(app, @BipolarAverageChannelEditFieldValueChanged, true);
            app.BipolarAverageChannelEditField.HorizontalAlignment = 'center';
            app.BipolarAverageChannelEditField.FontName = 'Tahoma';
            app.BipolarAverageChannelEditField.FontSize = 16;
            app.BipolarAverageChannelEditField.FontWeight = 'bold';
            app.BipolarAverageChannelEditField.Position = [218 59 58 22];
            app.BipolarAverageChannelEditField.Value = 1;

            % Create Cutoff1HzEditFieldLabel_3
            app.Cutoff1HzEditFieldLabel_3 = uilabel(app.BipolarAverageSettingsPanel);
            app.Cutoff1HzEditFieldLabel_3.HorizontalAlignment = 'right';
            app.Cutoff1HzEditFieldLabel_3.FontName = 'Tahoma';
            app.Cutoff1HzEditFieldLabel_3.FontSize = 16;
            app.Cutoff1HzEditFieldLabel_3.Position = [507 59 97 22];
            app.Cutoff1HzEditFieldLabel_3.Text = 'Cutoff 1 (Hz)';

            % Create BipolarAverageCutoff1EditField
            app.BipolarAverageCutoff1EditField = uieditfield(app.BipolarAverageSettingsPanel, 'numeric');
            app.BipolarAverageCutoff1EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarAverageCutoff1EditField.Tag = 'fc_low';
            app.BipolarAverageCutoff1EditField.FontName = 'Tahoma';
            app.BipolarAverageCutoff1EditField.FontSize = 16;
            app.BipolarAverageCutoff1EditField.Position = [619 59 100 22];
            app.BipolarAverageCutoff1EditField.Value = 25;

            % Create Cutoff2HzEditFieldLabel_3
            app.Cutoff2HzEditFieldLabel_3 = uilabel(app.BipolarAverageSettingsPanel);
            app.Cutoff2HzEditFieldLabel_3.HorizontalAlignment = 'right';
            app.Cutoff2HzEditFieldLabel_3.FontName = 'Tahoma';
            app.Cutoff2HzEditFieldLabel_3.FontSize = 16;
            app.Cutoff2HzEditFieldLabel_3.Position = [745 59 97 22];
            app.Cutoff2HzEditFieldLabel_3.Text = 'Cutoff 2 (Hz)';

            % Create BipolarAverageCutoff2EditField
            app.BipolarAverageCutoff2EditField = uieditfield(app.BipolarAverageSettingsPanel, 'numeric');
            app.BipolarAverageCutoff2EditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarAverageCutoff2EditField.Tag = 'fc_high';
            app.BipolarAverageCutoff2EditField.FontName = 'Tahoma';
            app.BipolarAverageCutoff2EditField.FontSize = 16;
            app.BipolarAverageCutoff2EditField.Position = [857 59 100 22];
            app.BipolarAverageCutoff2EditField.Value = 400;

            % Create StartDatamsSpinner_2Label
            app.StartDatamsSpinner_2Label = uilabel(app.BipolarAverageSettingsPanel);
            app.StartDatamsSpinner_2Label.HorizontalAlignment = 'right';
            app.StartDatamsSpinner_2Label.FontName = 'Tahoma';
            app.StartDatamsSpinner_2Label.FontSize = 16;
            app.StartDatamsSpinner_2Label.Position = [488 19 115 22];
            app.StartDatamsSpinner_2Label.Text = 'Start Data (ms)';

            % Create StartBipolarAverageSpinner
            app.StartBipolarAverageSpinner = uispinner(app.BipolarAverageSettingsPanel);
            app.StartBipolarAverageSpinner.Step = 5;
            app.StartBipolarAverageSpinner.Limits = [-250 0];
            app.StartBipolarAverageSpinner.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.StartBipolarAverageSpinner.FontName = 'Tahoma';
            app.StartBipolarAverageSpinner.FontSize = 16;
            app.StartBipolarAverageSpinner.Position = [618 19 100 22];
            app.StartBipolarAverageSpinner.Value = -20;

            % Create StopDatamsSpinner_2Label
            app.StopDatamsSpinner_2Label = uilabel(app.BipolarAverageSettingsPanel);
            app.StopDatamsSpinner_2Label.HorizontalAlignment = 'right';
            app.StopDatamsSpinner_2Label.FontName = 'Tahoma';
            app.StopDatamsSpinner_2Label.FontSize = 16;
            app.StopDatamsSpinner_2Label.Position = [729 19 113 22];
            app.StopDatamsSpinner_2Label.Text = 'Stop Data (ms)';

            % Create StopBipolarAverageSpinner
            app.StopBipolarAverageSpinner = uispinner(app.BipolarAverageSettingsPanel);
            app.StopBipolarAverageSpinner.Step = 5;
            app.StopBipolarAverageSpinner.Limits = [0 250];
            app.StopBipolarAverageSpinner.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.StopBipolarAverageSpinner.FontName = 'Tahoma';
            app.StopBipolarAverageSpinner.FontSize = 16;
            app.StopBipolarAverageSpinner.Position = [857 19 100 22];
            app.StopBipolarAverageSpinner.Value = 40;

            % Create ResetBipolarAverageButton
            app.ResetBipolarAverageButton = uibutton(app.BipolarAverageSettingsPanel, 'push');
            app.ResetBipolarAverageButton.ButtonPushedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.ResetBipolarAverageButton.FontName = 'Tahoma';
            app.ResetBipolarAverageButton.FontSize = 20;
            app.ResetBipolarAverageButton.FontWeight = 'bold';
            app.ResetBipolarAverageButton.FontColor = [1 0 0];
            app.ResetBipolarAverageButton.Position = [97 13 177 34];
            app.ResetBipolarAverageButton.Text = 'Reset';

            % Create NEditFieldLabel_2
            app.NEditFieldLabel_2 = uilabel(app.BipolarAverageSettingsPanel);
            app.NEditFieldLabel_2.HorizontalAlignment = 'right';
            app.NEditFieldLabel_2.FontSize = 16;
            app.NEditFieldLabel_2.FontWeight = 'bold';
            app.NEditFieldLabel_2.Position = [358 16 25 22];
            app.NEditFieldLabel_2.Text = 'N';

            % Create BipolarAverageNEditField
            app.BipolarAverageNEditField = uieditfield(app.BipolarAverageSettingsPanel, 'numeric');
            app.BipolarAverageNEditField.Limits = [1 100];
            app.BipolarAverageNEditField.RoundFractionalValues = 'on';
            app.BipolarAverageNEditField.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarAverageNEditField.HorizontalAlignment = 'center';
            app.BipolarAverageNEditField.FontName = 'Tahoma';
            app.BipolarAverageNEditField.FontSize = 16;
            app.BipolarAverageNEditField.Position = [393 17 65 22];
            app.BipolarAverageNEditField.Value = 30;

            % Create BipolarAverageRectifyCheckBox
            app.BipolarAverageRectifyCheckBox = uicheckbox(app.BipolarAverageSettingsPanel);
            app.BipolarAverageRectifyCheckBox.ValueChangedFcn = createCallbackFcn(app, @FilterParameterValueChanged, true);
            app.BipolarAverageRectifyCheckBox.Text = 'Rectify';
            app.BipolarAverageRectifyCheckBox.FontName = 'Tahoma';
            app.BipolarAverageRectifyCheckBox.Position = [345 59 58 22];
            app.BipolarAverageRectifyCheckBox.Value = true;

            % Create RMSContourTab
            app.RMSContourTab = uitab(app.TabGroup);
            app.RMSContourTab.Title = 'RMS Contour';
            app.RMSContourTab.BackgroundColor = [1 1 1];
            app.RMSContourTab.Tag = 'RC';

            % Create RMSContourGridLayout
            app.RMSContourGridLayout = uigridlayout(app.RMSContourTab);
            app.RMSContourGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.RMSContourGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.RMSContourGridLayout.BackgroundColor = [1 1 1];

            % Create RMSContourSettingsPanel
            app.RMSContourSettingsPanel = uipanel(app.RMSContourGridLayout);
            app.RMSContourSettingsPanel.Title = 'RMS Contour Settings';
            app.RMSContourSettingsPanel.Layout.Row = [14 15];
            app.RMSContourSettingsPanel.Layout.Column = [1 5];
            app.RMSContourSettingsPanel.FontWeight = 'bold';

            % Create ICAStreamTab
            app.ICAStreamTab = uitab(app.TabGroup);
            app.ICAStreamTab.Title = 'ICA Stream';
            app.ICAStreamTab.BackgroundColor = [1 1 1];
            app.ICAStreamTab.Tag = 'IS';

            % Create ICAStreamGridLayout
            app.ICAStreamGridLayout = uigridlayout(app.ICAStreamTab);
            app.ICAStreamGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.ICAStreamGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.ICAStreamGridLayout.BackgroundColor = [1 1 1];

            % Create ICAUIAxes
            app.ICAUIAxes = uiaxes(app.ICAStreamGridLayout);
            title(app.ICAUIAxes, 'ICA Streams')
            xlabel(app.ICAUIAxes, 'Time (s)')
            ylabel(app.ICAUIAxes, 'Amplitude (a.u.)')
            zlabel(app.ICAUIAxes, 'Z')
            app.ICAUIAxes.NextPlot = 'add';
            app.ICAUIAxes.Layout.Row = [1 15];
            app.ICAUIAxes.Layout.Column = [2 5];

            % Create ICAStreamChannelsPanel
            app.ICAStreamChannelsPanel = uipanel(app.ICAStreamGridLayout);
            app.ICAStreamChannelsPanel.Title = 'ICA Stream Channels';
            app.ICAStreamChannelsPanel.Layout.Row = [1 15];
            app.ICAStreamChannelsPanel.Layout.Column = 1;
            app.ICAStreamChannelsPanel.FontWeight = 'bold';

            % Create ICA01SwitchLabel
            app.ICA01SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA01SwitchLabel.HorizontalAlignment = 'center';
            app.ICA01SwitchLabel.Position = [29 822 39 22];
            app.ICA01SwitchLabel.Text = 'ICA01';

            % Create ICA01Switch
            app.ICA01Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA01Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA01Switch.Tag = '1';
            app.ICA01Switch.Position = [97 822 45 20];

            % Create ICA02Switch
            app.ICA02Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA02Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA02Switch.Tag = '2';
            app.ICA02Switch.Position = [97 783 45 20];

            % Create ICA02SwitchLabel
            app.ICA02SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA02SwitchLabel.HorizontalAlignment = 'center';
            app.ICA02SwitchLabel.Position = [29 782 39 22];
            app.ICA02SwitchLabel.Text = 'ICA02';

            % Create ICA03Switch
            app.ICA03Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA03Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA03Switch.Tag = '3';
            app.ICA03Switch.Position = [97 743 45 20];

            % Create ICA03SwitchLabel
            app.ICA03SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA03SwitchLabel.HorizontalAlignment = 'center';
            app.ICA03SwitchLabel.Position = [29 742 39 22];
            app.ICA03SwitchLabel.Text = 'ICA03';

            % Create ICA04Switch
            app.ICA04Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA04Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA04Switch.Tag = '4';
            app.ICA04Switch.Position = [97 703 45 20];

            % Create ICA04SwitchLabel
            app.ICA04SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA04SwitchLabel.Tag = '4';
            app.ICA04SwitchLabel.HorizontalAlignment = 'center';
            app.ICA04SwitchLabel.Position = [29 702 39 22];
            app.ICA04SwitchLabel.Text = 'ICA04';

            % Create ICA05SwitchLabel
            app.ICA05SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA05SwitchLabel.HorizontalAlignment = 'center';
            app.ICA05SwitchLabel.Position = [29 662 39 22];
            app.ICA05SwitchLabel.Text = 'ICA05';

            % Create ICA05Switch
            app.ICA05Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA05Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA05Switch.Tag = '5';
            app.ICA05Switch.Position = [97 662 45 20];

            % Create ICA06Switch
            app.ICA06Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA06Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA06Switch.Tag = '6';
            app.ICA06Switch.Position = [97 623 45 20];

            % Create ICA06SwitchLabel
            app.ICA06SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA06SwitchLabel.HorizontalAlignment = 'center';
            app.ICA06SwitchLabel.Position = [29 622 39 22];
            app.ICA06SwitchLabel.Text = 'ICA06';

            % Create ICA07Switch
            app.ICA07Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA07Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA07Switch.Tag = '7';
            app.ICA07Switch.Position = [97 583 45 20];

            % Create ICA07SwitchLabel
            app.ICA07SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA07SwitchLabel.HorizontalAlignment = 'center';
            app.ICA07SwitchLabel.Position = [29 582 39 22];
            app.ICA07SwitchLabel.Text = 'ICA07';

            % Create ICA08Switch
            app.ICA08Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA08Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA08Switch.Tag = '8';
            app.ICA08Switch.Position = [97 543 45 20];

            % Create ICA08SwitchLabel
            app.ICA08SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA08SwitchLabel.Tag = '4';
            app.ICA08SwitchLabel.HorizontalAlignment = 'center';
            app.ICA08SwitchLabel.Position = [29 542 39 22];
            app.ICA08SwitchLabel.Text = 'ICA08';

            % Create ICA09SwitchLabel
            app.ICA09SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA09SwitchLabel.HorizontalAlignment = 'center';
            app.ICA09SwitchLabel.Position = [29 502 39 22];
            app.ICA09SwitchLabel.Text = 'ICA09';

            % Create ICA09Switch
            app.ICA09Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA09Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA09Switch.Tag = '9';
            app.ICA09Switch.Position = [97 502 45 20];

            % Create ICA10Switch
            app.ICA10Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA10Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA10Switch.Tag = '10';
            app.ICA10Switch.Position = [97 464 45 20];

            % Create ICA10SwitchLabel
            app.ICA10SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA10SwitchLabel.HorizontalAlignment = 'center';
            app.ICA10SwitchLabel.Position = [29 463 39 22];
            app.ICA10SwitchLabel.Text = 'ICA10';

            % Create ICA11Switch
            app.ICA11Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA11Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA11Switch.Tag = '11';
            app.ICA11Switch.Position = [97 425 45 20];

            % Create ICA11SwitchLabel
            app.ICA11SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA11SwitchLabel.HorizontalAlignment = 'center';
            app.ICA11SwitchLabel.Position = [30 424 38 22];
            app.ICA11SwitchLabel.Text = 'ICA11';

            % Create ICA12Switch
            app.ICA12Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA12Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA12Switch.Tag = '12';
            app.ICA12Switch.Position = [97 386 45 20];

            % Create ICA12SwitchLabel
            app.ICA12SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA12SwitchLabel.Tag = '4';
            app.ICA12SwitchLabel.HorizontalAlignment = 'center';
            app.ICA12SwitchLabel.Position = [29 385 39 22];
            app.ICA12SwitchLabel.Text = 'ICA12';

            % Create ICA13SwitchLabel
            app.ICA13SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA13SwitchLabel.HorizontalAlignment = 'center';
            app.ICA13SwitchLabel.Position = [29 346 39 22];
            app.ICA13SwitchLabel.Text = 'ICA13';

            % Create ICA13Switch
            app.ICA13Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA13Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA13Switch.Tag = '13';
            app.ICA13Switch.Position = [97 346 45 20];

            % Create ICA14Switch
            app.ICA14Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA14Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA14Switch.Tag = '14';
            app.ICA14Switch.Position = [97 308 45 20];

            % Create ICA14SwitchLabel
            app.ICA14SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA14SwitchLabel.HorizontalAlignment = 'center';
            app.ICA14SwitchLabel.Position = [29 307 39 22];
            app.ICA14SwitchLabel.Text = 'ICA14';

            % Create ICA15Switch
            app.ICA15Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA15Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA15Switch.Tag = '15';
            app.ICA15Switch.Position = [97 269 45 20];

            % Create ICA15SwitchLabel
            app.ICA15SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA15SwitchLabel.HorizontalAlignment = 'center';
            app.ICA15SwitchLabel.Position = [29 268 39 22];
            app.ICA15SwitchLabel.Text = 'ICA15';

            % Create ICA16Switch
            app.ICA16Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA16Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA16Switch.Tag = '16';
            app.ICA16Switch.Position = [97 230 45 20];

            % Create ICA16SwitchLabel
            app.ICA16SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA16SwitchLabel.Tag = '4';
            app.ICA16SwitchLabel.HorizontalAlignment = 'center';
            app.ICA16SwitchLabel.Position = [29 229 39 22];
            app.ICA16SwitchLabel.Text = 'ICA16';

            % Create ICA17SwitchLabel
            app.ICA17SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA17SwitchLabel.HorizontalAlignment = 'center';
            app.ICA17SwitchLabel.Position = [29 190 39 22];
            app.ICA17SwitchLabel.Text = 'ICA17';

            % Create ICA17Switch
            app.ICA17Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA17Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA17Switch.Tag = '17';
            app.ICA17Switch.Position = [97 190 45 20];

            % Create ICA18Switch
            app.ICA18Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA18Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA18Switch.Tag = '18';
            app.ICA18Switch.Position = [97 152 45 20];

            % Create ICA18SwitchLabel
            app.ICA18SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA18SwitchLabel.HorizontalAlignment = 'center';
            app.ICA18SwitchLabel.Position = [29 151 39 22];
            app.ICA18SwitchLabel.Text = 'ICA18';

            % Create ICA19Switch
            app.ICA19Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA19Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA19Switch.Tag = '19';
            app.ICA19Switch.Position = [97 113 45 20];

            % Create ICA19SwitchLabel
            app.ICA19SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA19SwitchLabel.HorizontalAlignment = 'center';
            app.ICA19SwitchLabel.Position = [29 112 39 22];
            app.ICA19SwitchLabel.Text = 'ICA19';

            % Create ICA20Switch
            app.ICA20Switch = uiswitch(app.ICAStreamChannelsPanel, 'slider');
            app.ICA20Switch.ValueChangedFcn = createCallbackFcn(app, @ICASwitchValueChanged, true);
            app.ICA20Switch.Tag = '20';
            app.ICA20Switch.Position = [97 74 45 20];

            % Create ICA20SwitchLabel
            app.ICA20SwitchLabel = uilabel(app.ICAStreamChannelsPanel);
            app.ICA20SwitchLabel.Tag = '4';
            app.ICA20SwitchLabel.HorizontalAlignment = 'center';
            app.ICA20SwitchLabel.Position = [29 73 39 22];
            app.ICA20SwitchLabel.Text = 'ICA20';

            % Create ToggleAllBipolarChannelsSwitchLabel_2
            app.ToggleAllBipolarChannelsSwitchLabel_2 = uilabel(app.ICAStreamChannelsPanel);
            app.ToggleAllBipolarChannelsSwitchLabel_2.HorizontalAlignment = 'center';
            app.ToggleAllBipolarChannelsSwitchLabel_2.Position = [66 39 73 22];
            app.ToggleAllBipolarChannelsSwitchLabel_2.Text = 'All Channels';

            % Create ToggleAllICAChannelsSwitch
            app.ToggleAllICAChannelsSwitch = uiswitch(app.ICAStreamChannelsPanel, 'toggle');
            app.ToggleAllICAChannelsSwitch.Orientation = 'horizontal';
            app.ToggleAllICAChannelsSwitch.ValueChangedFcn = createCallbackFcn(app, @ToggleAllICAChannelsSwitchValueChanged, true);
            app.ToggleAllICAChannelsSwitch.FontWeight = 'bold';
            app.ToggleAllICAChannelsSwitch.Position = [80 16 42 18];

            % Create ICARasterTab
            app.ICARasterTab = uitab(app.TabGroup);
            app.ICARasterTab.Title = 'ICA Raster';
            app.ICARasterTab.BackgroundColor = [1 1 1];
            app.ICARasterTab.Tag = 'IR';

            % Create ICARasterGridLayout
            app.ICARasterGridLayout = uigridlayout(app.ICARasterTab);
            app.ICARasterGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.ICARasterGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.ICARasterGridLayout.BackgroundColor = [1 1 1];

            % Create ICARasterSettingsPanel
            app.ICARasterSettingsPanel = uipanel(app.ICARasterGridLayout);
            app.ICARasterSettingsPanel.Title = 'ICA Raster Settings';
            app.ICARasterSettingsPanel.Layout.Row = [14 15];
            app.ICARasterSettingsPanel.Layout.Column = [1 5];
            app.ICARasterSettingsPanel.FontWeight = 'bold';

            % Create ConfigTab
            app.ConfigTab = uitab(app.TabGroup);
            app.ConfigTab.Title = 'Config';
            app.ConfigTab.BackgroundColor = [1 1 1];
            app.ConfigTab.Tag = 'Config';

            % Create ConfigGridLayout
            app.ConfigGridLayout = uigridlayout(app.ConfigTab);
            app.ConfigGridLayout.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};
            app.ConfigGridLayout.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x', '1x'};
            app.ConfigGridLayout.BackgroundColor = [1 1 1];

            % Create ResponsesIPAddressEditFieldLabel
            app.ResponsesIPAddressEditFieldLabel = uilabel(app.ConfigGridLayout);
            app.ResponsesIPAddressEditFieldLabel.HorizontalAlignment = 'right';
            app.ResponsesIPAddressEditFieldLabel.FontName = 'Tahoma';
            app.ResponsesIPAddressEditFieldLabel.FontSize = 16;
            app.ResponsesIPAddressEditFieldLabel.Layout.Row = 2;
            app.ResponsesIPAddressEditFieldLabel.Layout.Column = 1;
            app.ResponsesIPAddressEditFieldLabel.Text = 'Responses IP Address';

            % Create ResponsesIPEditField
            app.ResponsesIPEditField = uieditfield(app.ConfigGridLayout, 'text');
            app.ResponsesIPEditField.HorizontalAlignment = 'center';
            app.ResponsesIPEditField.FontName = 'Tahoma';
            app.ResponsesIPEditField.FontSize = 20;
            app.ResponsesIPEditField.Layout.Row = 2;
            app.ResponsesIPEditField.Layout.Column = [2 3];
            app.ResponsesIPEditField.Value = '127.0.0.1';

            % Create ResponsesPortEditFieldLabel
            app.ResponsesPortEditFieldLabel = uilabel(app.ConfigGridLayout);
            app.ResponsesPortEditFieldLabel.HorizontalAlignment = 'right';
            app.ResponsesPortEditFieldLabel.FontName = 'Tahoma';
            app.ResponsesPortEditFieldLabel.FontSize = 16;
            app.ResponsesPortEditFieldLabel.Layout.Row = 3;
            app.ResponsesPortEditFieldLabel.Layout.Column = 1;
            app.ResponsesPortEditFieldLabel.Text = 'Responses Port';

            % Create ResponsesPortEditField
            app.ResponsesPortEditField = uieditfield(app.ConfigGridLayout, 'numeric');
            app.ResponsesPortEditField.Limits = [0 Inf];
            app.ResponsesPortEditField.RoundFractionalValues = 'on';
            app.ResponsesPortEditField.HorizontalAlignment = 'center';
            app.ResponsesPortEditField.FontName = 'Tahoma';
            app.ResponsesPortEditField.FontSize = 16;
            app.ResponsesPortEditField.Layout.Row = 3;
            app.ResponsesPortEditField.Layout.Column = [2 3];
            app.ResponsesPortEditField.Value = 6001;

            % Create ResponsesConnectButton
            app.ResponsesConnectButton = uibutton(app.ConfigGridLayout, 'push');
            app.ResponsesConnectButton.ButtonPushedFcn = createCallbackFcn(app, @ResponsesConnectButtonPushed, true);
            app.ResponsesConnectButton.Tag = 'responses';
            app.ResponsesConnectButton.FontName = 'Tahoma';
            app.ResponsesConnectButton.FontSize = 24;
            app.ResponsesConnectButton.FontWeight = 'bold';
            app.ResponsesConnectButton.Tooltip = {'Connect to the "responses" TCP server. This requires the N3_NHP_Online_Interface app to be running before it will work.'};
            app.ResponsesConnectButton.Layout.Row = [2 3];
            app.ResponsesConnectButton.Layout.Column = [4 5];
            app.ResponsesConnectButton.Text = 'Connect';

            % Create ResponsesConnectionStatusLampLabel
            app.ResponsesConnectionStatusLampLabel = uilabel(app.ConfigGridLayout);
            app.ResponsesConnectionStatusLampLabel.HorizontalAlignment = 'right';
            app.ResponsesConnectionStatusLampLabel.Layout.Row = 1;
            app.ResponsesConnectionStatusLampLabel.Layout.Column = 4;
            app.ResponsesConnectionStatusLampLabel.Text = 'Responses Connection Status';

            % Create ResponsesConnectionStatusLamp
            app.ResponsesConnectionStatusLamp = uilamp(app.ConfigGridLayout);
            app.ResponsesConnectionStatusLamp.Layout.Row = 1;
            app.ResponsesConnectionStatusLamp.Layout.Column = 5;
            app.ResponsesConnectionStatusLamp.Color = [0.651 0.651 0.651];

            % Create ResponsesStartEditFieldLabel
            app.ResponsesStartEditFieldLabel = uilabel(app.ConfigGridLayout);
            app.ResponsesStartEditFieldLabel.HorizontalAlignment = 'right';
            app.ResponsesStartEditFieldLabel.Layout.Row = 5;
            app.ResponsesStartEditFieldLabel.Layout.Column = 1;
            app.ResponsesStartEditFieldLabel.Text = 'Start Time for Post-RMS (ms)';

            % Create ResponsesStartEditField
            app.ResponsesStartEditField = uieditfield(app.ConfigGridLayout, 'numeric');
            app.ResponsesStartEditField.HorizontalAlignment = 'center';
            app.ResponsesStartEditField.FontName = 'Tahoma';
            app.ResponsesStartEditField.FontSize = 20;
            app.ResponsesStartEditField.Layout.Row = 5;
            app.ResponsesStartEditField.Layout.Column = [2 3];
            app.ResponsesStartEditField.Value = 12.5;

            % Create ResponsesStopEditFIeldLabel
            app.ResponsesStopEditFIeldLabel = uilabel(app.ConfigGridLayout);
            app.ResponsesStopEditFIeldLabel.HorizontalAlignment = 'right';
            app.ResponsesStopEditFIeldLabel.Layout.Row = 6;
            app.ResponsesStopEditFIeldLabel.Layout.Column = 1;
            app.ResponsesStopEditFIeldLabel.Text = 'Stop Time for Post-RMS (ms)';

            % Create ResponsesStopEditField
            app.ResponsesStopEditField = uieditfield(app.ConfigGridLayout, 'numeric');
            app.ResponsesStopEditField.HorizontalAlignment = 'center';
            app.ResponsesStopEditField.FontName = 'Tahoma';
            app.ResponsesStopEditField.FontSize = 20;
            app.ResponsesStopEditField.Layout.Row = 6;
            app.ResponsesStopEditField.Layout.Column = [2 3];
            app.ResponsesStopEditField.Value = 25;

            % Create SAGALabel
            app.SAGALabel = uilabel(app.SAGADataViewerUIFigure);
            app.SAGALabel.FontSize = 16;
            app.SAGALabel.FontWeight = 'bold';
            app.SAGALabel.FontColor = [1 1 1];
            app.SAGALabel.Position = [15 940 96 22];
            app.SAGALabel.Text = 'SAGA';

            % Create DateTimeLabel
            app.DateTimeLabel = uilabel(app.SAGADataViewerUIFigure);
            app.DateTimeLabel.Position = [173 940 331 22];

            % Create TriggerSyncBitEditFieldLabel
            app.TriggerSyncBitEditFieldLabel = uilabel(app.SAGADataViewerUIFigure);
            app.TriggerSyncBitEditFieldLabel.HorizontalAlignment = 'right';
            app.TriggerSyncBitEditFieldLabel.FontName = 'Tahoma';
            app.TriggerSyncBitEditFieldLabel.FontWeight = 'bold';
            app.TriggerSyncBitEditFieldLabel.Position = [786 940 112 22];
            app.TriggerSyncBitEditFieldLabel.Text = '(Trigger) Sync Bit';

            % Create TriggerSyncBitEditField
            app.TriggerSyncBitEditField = uieditfield(app.SAGADataViewerUIFigure, 'numeric');
            app.TriggerSyncBitEditField.Limits = [0 16];
            app.TriggerSyncBitEditField.RoundFractionalValues = 'on';
            app.TriggerSyncBitEditField.ValueChangedFcn = createCallbackFcn(app, @TriggerSyncBitEditFieldValueChanged, true);
            app.TriggerSyncBitEditField.HorizontalAlignment = 'center';
            app.TriggerSyncBitEditField.FontName = 'Tahoma';
            app.TriggerSyncBitEditField.FontWeight = 'bold';
            app.TriggerSyncBitEditField.Position = [909 940 93 22];
            app.TriggerSyncBitEditField.Value = 9;

            % Create TriggerChannelEditFieldLabel
            app.TriggerChannelEditFieldLabel = uilabel(app.SAGADataViewerUIFigure);
            app.TriggerChannelEditFieldLabel.HorizontalAlignment = 'right';
            app.TriggerChannelEditFieldLabel.FontName = 'Tahoma';
            app.TriggerChannelEditFieldLabel.FontWeight = 'bold';
            app.TriggerChannelEditFieldLabel.Position = [566 940 113 22];
            app.TriggerChannelEditFieldLabel.Text = '(Trigger) Channel';

            % Create TriggerChannelEditField
            app.TriggerChannelEditField = uieditfield(app.SAGADataViewerUIFigure, 'numeric');
            app.TriggerChannelEditField.Limits = [0 100];
            app.TriggerChannelEditField.RoundFractionalValues = 'on';
            app.TriggerChannelEditField.ValueChangedFcn = createCallbackFcn(app, @TriggerChannelEditFieldValueChanged, true);
            app.TriggerChannelEditField.HorizontalAlignment = 'center';
            app.TriggerChannelEditField.FontName = 'Tahoma';
            app.TriggerChannelEditField.FontWeight = 'bold';
            app.TriggerChannelEditField.Position = [690 940 93 22];
            app.TriggerChannelEditField.Value = 72;

            % Show the figure after all components are created
            app.SAGADataViewerUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = SAGA_GUI(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.SAGADataViewerUIFigure)

            % Execute the startup function
            runStartupFcn(app, @(app)startupFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.SAGADataViewerUIFigure)
        end
    end
end