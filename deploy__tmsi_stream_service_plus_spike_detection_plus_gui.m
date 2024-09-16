%DEPLOY__TMSI_STREAM_SERVICE_PLUS_SPIKE_DETECTION_PLUS_GUI - Script that enables sampling from multiple devices.
%
% Starts up the Tablet "Pressure Tracker" 
%
% See details in README.MD

%% Handle some basic startup stuff.
clc;

if exist('device', 'var')~=0
    disconnect(device);
end
    
if exist('lib', 'var')~=0
    lib.cleanUp();
end

if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all; %#ok<*CLALL>
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

%% SET PARAMETERS
switch getenv("COMPUTERNAME")
    case 'NMLNHP-DELL-C01'
        IMPEDANCE_FIGURE_POSITION = [ 280 160 1200 720; ... % A
                                     2120 100 1200 720];    % B
    case 'NMLVR'
        IMPEDANCE_FIGURE_POSITION = [120   450   900   750; ... % A
                                     1020  450   900   750];     % B
    case 'MAX_LENOVO'
        IMPEDANCE_FIGURE_POSITION = [2      50   766   829; ...
                                     770    50   766   829];
    otherwise
        IMPEDANCE_FIGURE_POSITION = [ 100 300 200 200; ...  % A
                                      300 300 200 200];     % B
end

config_file = parameters('config_stream_service_plus');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);
% addpath('FastICA_25');

%% Setup device configurations.
config_device_impedance = struct('ImpedanceMode', true, ...
    'ReferenceMethod', config.Default.Device_Reference_Mode, ...
    'Triggers', false, ...
    'Dividers', {{'uni', 0; 'bip', -1}});
config_channel_impedance = struct('uni',1:64, ...
    'bip', 0, ...
    'dig', 0, ...
    'acc', 0);
config_device = struct('Dividers', {{'uni', config.Default.Sample_Rate_Divider; 'bip', config.Default.Sample_Rate_Divider}}, ...
    'Triggers', true, ...
    'BaseSampleRate', config.Default.Sample_Rate, ...
    'RepairLogging', false, ...
    'ImpedanceMode', false, ...
    'AutoReferenceMethod', false, ...
    'ReferenceMethod', config.Default.Device_Reference_Mode, ... % must be 'common' or 'average'
    'SyncOutDivider', -1, ...
    'SyncOutDutyCycle', 500);
config_channels = struct(...
    'A', ...
        struct( ...
            'uni', 1:numel(config.SAGA.A.Channels.UNI), ...
            'bip', 1:numel(config.SAGA.A.Channels.BIP), ...
            'dig', ~isempty(1:numel(config.SAGA.A.Channels.DIG)), ...
            'acc', config.SAGA.A.Channels.ACC_EN, ...
            'aux', 1:numel(config.SAGA.A.Channels.AUX)), ...
    'B', ...
        struct( ...
            'uni', 1:numel(config.SAGA.B.Channels.UNI), ...
            'bip', 1:numel(config.SAGA.B.Channels.BIP), ...
            'dig', ~isempty(1:numel(config.SAGA.B.Channels.DIG)), ...
            'acc', config.SAGA.B.Channels.ACC_EN, ...
            'aux', 1:numel(config.SAGA.B.Channels.AUX)));
channels = struct('A', config.SAGA.A.Channels, ...
    'B', config.SAGA.B.Channels);


%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();
try
    % Code within the try-catch to ensure that all devices are stopped and
    % closed properly in case of a failure.
    device = lib.getDevices('usb', config.Default.Interface, 2, 2);
    connect(device);
    ORDERED_TAG = setDeviceTag(device, SN, TAG);
catch e
    if strcmpi(e.identifier, 'MATLAB:narginchk:notEnoughInputs')
        if strcmpi(config.Default.Interface, 'optical')
            device = lib.getDevices('usb', 'electrical', 2, 2);
            if numel(device) < N_CLIENT
                e = addCause(e, MException('MATLAB:TMSiSAGA:InvalidDeviceConnection','Could not detect any hardware connection to data recorder (electrical or optical). Is it on?'));
                lib.cleanUp();
                rethrow(e);
            end
            connect(device);
            for ii = 1:numel(device)
                changeDataRecorderInterfaceTo(device(ii), char(config.Default.Interface));
            end
            connect(device); % Reconnect on new interface
            ORDERED_TAG = setDeviceTag(device, SN, TAG);
        else
            e = addCause(e, MException('MATLAB:TMSiSAGA:InvalidDeviceConnection',sprintf('Could not detect devices on %s hardware interface.', config.Default.Interface)));
            lib.cleanUp();
            rethrow(e);
        end
    else
        % In case of an error close all still active devices and clean up
        lib.cleanUp();

        % Rethrow error to ensure you get a message in console
        rethrow(e);
    end
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.

    info = getDeviceInfo(device);
    enableChannels(device, horzcat({device.channels}));
    for ii = 1:numel(device)
        setSAGA(device(ii).channels, device(ii).tag);
        configStandardMode(device(ii), config_channels.(device(ii).tag), config_device);
    end
    for ii = 1:numel(device)
        fprintf(1,'\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ...
            ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
    end
    if numel(device) < N_CLIENT
        disconnect(device);
        device = lib.getDevices('usb', {'electrical', 'optical'}, 2, 2);
        i_remove = false(size(device));
        for ii = 1:numel(device)
            connect(device(ii))
            if ~strcmpi(device(ii).data_recorder.interface_type,config.Default.Interface)
                changeDataRecorderInterfaceTo(device(ii), char(config.Default.Interface));
            end
        end
        connect(device);
        delete(device(i_remove));
        device(i_remove) = [];
        ORDERED_TAG = setDeviceTag(device, SN, TAG);
    end
    if numel(device) ~= N_CLIENT
        error(1,'Wrong number of devices returned. Something went wrong with hardware connections.\n');
    end
catch e
    disconnect(device);
    lib.cleanUp();
    rethrow(e);
end

%% Create TMSi stream client + udpport
udp_state_receiver = udpport("byte", ...
    "LocalHost", "0.0.0.0", ...
    "LocalPort", config.UDP.Socket.StreamService.Port.state, ...
    "EnablePortSharing", true);
udp_name_receiver = udpport("byte", ...
    "LocalHost", "0.0.0.0", ...
    "LocalPort", config.UDP.Socket.StreamService.Port.name, ...
    "EnablePortSharing", true);
udp_param_receiver = udpport("byte", ...
    "LocalHost", "0.0.0.0", ...
    "LocalPort", config.UDP.Socket.StreamService.Port.params, ...
    "EnablePortSharing", true);

%% Initialize parameters and parameter sub-fields, figures
param = struct(...
    'n_channels', struct('A', [], 'B', []), ...
    'name_tag', struct('A', config.SAGA.A.Array.Location, 'B', config.SAGA.B.Array.Location), ...
    'n_total', struct('A', numel(config_channels.A.uni) + numel(config_channels.A.bip), ...
                      'B', numel(config_channels.B.uni) + numel(config_channels.B.bip)), ...
    'sample_rate', config.Default.Sample_Rate, ...
    'virtual_ref_mode', config.Default.Virtual_Reference_Mode, ...
    'interpolate_grid', config.Default.Interpolate_Grid, ...
    'hpf', struct('b', [], 'a', []), ... % Filter transfer function numerator (b) and denominator (a) coefficients
    'lpf', struct('b', [], 'a', []), ... % Filter transfer function numerator (b) and denominator (a) coefficients
    'gui', struct('squiggles', struct('enable', config.GUI.Squiggles.Enable, ...
                                      'fig', [], ...
                                      'h', [], ...
                                      'offset', config.GUI.Offset, ...
                                      'hpf_mode', config.GUI.Squiggles.HPF_Mode, ...
                                      'whiten', struct('A', false, 'B', false), ...
                                      'channels', struct('A', [], 'B', []), ...
                                      'n_samples', config.GUI.N_Samples, ...
                                      'color', config.GUI.Color, ...
                                      'triggers', struct('enable', config.Triggers.Enable), ...
                                      'tag', struct('A', config.SAGA.A.Array.Location, 'B', config.SAGA.B.Array.Location))), ...
    'save_location', strrep(config.Default.Folder,'\','/'),  ...            % Save folder
    'pause_duration', config.Default.Sample_Loop_Pause_Duration, ...
    'use_channels', struct('A', [], 'B', []), ...
    'n_device', numel(device), ...
    'enable_raw_lsl_outlet', config.Default.Enable_Raw_LSL_Outlet, ...
    'enable_envelope_lsl_outlet', config.Default.Enable_Envelope_LSL_Outlet, ...
    'enable_tablet_figure', config.Default.Enable_Tablet_Figure, ...
    'enable_lsl_gesture_decode', config.Default.Enable_LSL_Gesture_Decode, ...
    'enable_trigger_controller', config.Default.Enable_Trigger_Controller, ...
    'enable_filters', config.Default.Enable_Filters, ...
    'dsp_extension_factor', config.Default.Extension_Factor, ...
    'prev_data', struct('A', zeros(config.Default.Extension_Factor,64), 'B', zeros(config.Default.Extension_Factor,64)), ...
    'parse_from_bits', config.Triggers.Parse_From_Bits, ...
    'trig_out_mask', [2^config.Triggers.Left.Bit, 2^config.Triggers.Right.Bit], ...
    'trig_out_en', [config.Triggers.Left.Enable, config.Triggers.Right.Enable], ...
    'trig_out_chan', [config.Triggers.Left.Channel, config.Triggers.Right.Channel],...
    'trig_out_threshold', [[config.Triggers.Left.RisingThreshold, config.Triggers.Left.FallingThreshold]; [config.Triggers.Right.RisingThreshold, config.Triggers.Right.FallingThreshold]], ...
    'trig_out_sliding_threshold', [config.Triggers.Left.SlidingThreshold, config.Triggers.Right.SlidingThreshold], ...
    'trig_out_debounce_iterations', config.Triggers.Debounce_Loop_Iterations, ...
    'emulate_mouse', config.Triggers.Emulate_Mouse, ...
    'gamepad', struct('client',[],'address',config.TCP.InputUtilities.Address,'port',config.TCP.InputUtilities.Port.Gamepad), ...
    'mouse', struct('client',[],'address',config.TCP.InputUtilities.Address,'port',config.TCP.InputUtilities.Port.Mouse), ...
    'P', struct('A',[],'B',[]));
param = setup_or_teardown_triggers_socket_connection(param);
param.gui.squiggles.channels.A = config.GUI.Squiggles.A;
param.gui.squiggles.channels.B = config.GUI.Squiggles.B;
param.use_channels.A = config.GUI.Squiggles.A;
param.use_channels.B = config.GUI.Squiggles.B;
[param.hpf.b, param.hpf.a] = butter(3, config.Default.HPF_Cutoff_Frequency/(param.sample_rate/2), 'high');
[param.lpf.b, param.lpf.a] = butter(3, 0.5/(param.sample_rate/2), 'low');
if numel(device) > 1
    nTotalChannels = param.n_total.A + param.n_total.B;
else
    nTotalChannels = param.n_total.(device.tag);
end
ch = device.getActiveChannels();
if ~iscell(ch)
    ch = {ch};
end

param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
hpf_data = struct('A', [], 'B', []);
rms_data = struct('A',[],'B',[]);
env_data = struct('A',[],'B',[]);
param.n_mvc_acquired = 0;
i_mono = struct('A', config.SAGA.A.Channels.UNI, 'B', config.SAGA.B.Channels.UNI);
i_bip = struct('A', config.SAGA.A.Channels.BIP, 'B', config.SAGA.B.Channels.BIP);
i_all = struct('A', [config.SAGA.A.Channels.UNI, config.SAGA.A.Channels.BIP], ...
               'B', [config.SAGA.B.Channels.UNI, config.SAGA.B.Channels.BIP]);
zi = struct; % Filter states
zi.squiggles = struct('A',zeros(3,numel(i_all.A)), 'B', zeros(3,numel(i_all.B)));
zi.envelope = struct('A', zeros(3,param.n_total.A), 'B', zeros(3, param.n_total.B));
trig_out_state = [false, false];

%% Load the LSL library
lslMatlabFolder = fullfile(pwd, '..', 'liblsl-Matlab');
if exist(lslMatlabFolder,'dir')==0
    lslMatlabFolder = parameters('liblsl_folder');
    if exist(lslMatlabFolder, 'dir')==0
        lslMatlabFolder2 = 'C:/MyRepos/Libraries/liblsl-Matlab';
        if exist(lslMatlabFolder2,'dir')==0
            disp("No valid liblsl-Matlab repository detected on this device.");
            fprintf(1,'\t->\tTried: "%s"\n', fullfile(pwd, '..', 'liblsl-Matlab'));
            fprintf(1,'\t->\tTried: "%s"\n', lslMatlabFolder);
            fprintf(1,'\t->\tTried: "%s"\n', lslMatlabFolder2);
            disp("Please check parameters.m in the 2TMSi_MATLAB_Interface repository, and try again.");
            pause(30);
            error("[TMSi]::Missing liblsl-Matlab repository.");
        else
            lslMatlabFolder = lslMatlabFolder2;
        end
    end
end
addpath(genpath(lslMatlabFolder)); % Adds liblsl-Matlab
lib_lsl = lsl_loadlib();

%% Initialize the LSL stream information and outlets
if param.enable_raw_lsl_outlet
    lsl_info_obj = struct;
    lsl_outlet_obj = struct;
    for iDev = 1:numel(device)
        tag = device(iDev).tag;
        fprintf(1,'[TMSi]::[LSL]::Creating LSL streaminfo for %s...',config.SAGA.(tag).Unit);
        lsl_info_obj.(tag) = lsl_streaminfo(lib_lsl, ...
            char(config.SAGA.(tag).Unit), ...       % Name
            'EMG', ...                    % Type
            numel(ch{ii}), ....           % ChannelCount
            4000, ...                     % NominalSrate
            'cf_float32', ...             % ChannelFormat
            char(config.SAGA.(tag).Unit));      % Unique ID: SAGAA, SAGAB, SAGA1, ... SAGA5
        chns = lsl_info_obj.(tag).desc().append_child('channels');
        for iCh = 1:numel(ch{ii})
            c = chns.append_child('channel');
            c.append_child_value('name',ch{ii}(iCh).name);
            c.append_child_value('label',ch{ii}(iCh).name);
            c.append_child_value('unit',ch{ii}(iCh).unit_name);
            c.append_child_value('type', TMSiSAGA.TMSiUtils.toChannelTypeString(ch{ii}(iCh).type));
        end    
        lsl_info_obj.(tag).desc().append_child_value('manufacturer', 'NML');
        lsl_info_obj.(tag).desc().append_child_value('layout', 'Grid_8_x_8');
        fprintf(1,'complete\n');
        fprintf('[TMSi]::[LSL]::Opening outlet...');
        lsl_outlet_obj.(tag) = lsl_outlet(lsl_info_obj.(tag));
        fprintf(1,'complete\n');
    end
end
if param.enable_envelope_lsl_outlet
    lsl_info_env = lsl_streaminfo(lib_lsl, ...
            'SAGACombined_Envelope', ...     % Name
            'EMG', ...                       % Type
            64*numel(device), ....           % ChannelCount
            1/param.pause_duration, ...      % NominalSrate
            'cf_float32', ...                % ChannelFormat
            sprintf('StreamService_Envelope_%06d',randi(999999,1)));
    chns = lsl_info_env.desc().append_child('channels');
    for ii = 1:(64*numel(device))
        c = chns.append_child('channel');
        c.append_child_value('name', sprintf('UNI-%03d',ii));
        c.append_child_value('label', sprintf('UNI-%03d',ii));
        c.append_child_value('unit', 'μV');
        c.append_child_value('type','EMG');
    end 
    lsl_info_env.desc().append_child_value('manufacturer', 'NML');
    lsl_outlet_env = lsl_outlet(lsl_info_env);
    
    lsl_info_decode = lsl_streaminfo(lib_lsl, ...
            'SAGACombined_Envelope_Decode', ...       % Name
            'Control', ...                    % Type
            3, ....           % ChannelCount
            1/param.pause_duration, ...                     % NominalSrate
            'cf_float32', ...             % ChannelFormat
            sprintf('StreamService_EnvDecode_%06d',randi(999999,1)));
    chns = lsl_info_decode.desc().append_child('channels');
    c = chns.append_child('channel');
    c.append_child_value('name', 'X');
    c.append_child_value('label', 'X');
    c.append_child_value('unit', 'none');
    c.append_child_value('type','Control');
    c = chns.append_child('channel');
    c.append_child_value('name', 'Y');
    c.append_child_value('label', 'Y');
    c.append_child_value('unit', 'none');
    c.append_child_value('type','Control');
    c = chns.append_child('channel');
    c.append_child_value('name', 'Z');
    c.append_child_value('label', 'Z');
    c.append_child_value('unit', 'none');
    c.append_child_value('type','Control');
    lsl_info_decode.desc().append_child_value('manufacturer', 'NML');
    lsl_outlet_decode = lsl_outlet(lsl_info_decode);
end

%% If tablet pressure stream is enabled, then show this
if param.enable_tablet_figure
    tablet_fig = init_pressure_tracking_fig();
end

%% Configuration complete, run main control loop.
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    samples = cell(N_CLIENT,1);
    envelope_bin_sample = zeros(64*N_CLIENT,1);
    gestures_ready = false(N_CLIENT,1);
    cat_data = [];
    state = "idle";
    dt = datetime("today","Format","uuuu-MM-dd","Locale","system");
    fname = strrep(fullfile(param.save_location, ...
                            config.Default.Subject, ...
                            sprintf("%s_%04d_%02d_%02d_%%s_0.poly5", ...
                                    config.Default.Subject, ...
                                    year(dt), month(dt), day(dt))), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    
    [tmpFolder, tmpFile, tmpExt] = fileparts(fname);
    if exist(tmpFolder,'dir')==0
        mkdir(tmpFolder);
    end
    if strlength(tmpExt) == 0
        fname = strcat(string(fname), ".poly5");
    else
        fname = strrep(fname, tmpExt, ".poly5");
    end
    fname_tablet = strrep(fname,"%s","TABLET");
    fname_tablet = strrep(fname_tablet,'.poly5','.bin');
    start(device);
    pause(1.0);
    counter_offset = 0;
    nTrigsPrev = 0;
    statePrev = [0 0];
    stateDebounceIterations = [0 0];
    needs_offset = true;
    if N_CLIENT > 1
        past_state = zeros(2,param.n_total.A + param.n_total.B);
    else
        past_state = zeros(2,param.n_total.(device.tag));
    end
    grid_ch_uni = struct;
    for ii = 1:N_CLIENT % Determine number of channels definitively
        [samples{ii}, num_sets] = device(ii).sample();
        while (num_sets < 1)
            fprintf(1,'[TMSi]::[INIT] Waiting for SAGA-%s to generate samples...\n', device(ii).tag);
            pause(0.5);
        end
        param.n_channels.(device(ii).tag) = size(samples{ii},1);
        grid_ch_uni.(device(ii).tag) = param.use_channels.(device(ii).tag)(param.use_channels.(device(ii).tag) <= 64);
    end
    stop(device);
    
    recording = false;
    running = false;
    writeline(udp_state_receiver, jsonencode(struct('type', 'status', 'value', 'start')), config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
    fprintf(1, "\n\t\t->\t[%s] SAGA LOOP BEGIN\t\t<-\n\n",string(datetime('now')));

    while ~strcmpi(state, "quit")
        pause(param.pause_duration); % We are in "Idle" state, allow other callbacks to process.
        % 1. We are in "Idle" state. Check for new filename.
        while udp_name_receiver.NumBytesAvailable > 0
            tmp = udp_name_receiver.readline();
            if startsWith(strrep(tmp, "\", "/"), param.save_location)
                fname = tmp;
            else
                fname = strrep(fullfile(param.save_location, tmp), "\", "/");
            end
            [tmpFolder, tmpFile, tmpExt] = fileparts(fname);
            if exist(tmpFolder,'dir')==0
                mkdir(tmpFolder);
            end
            if strlength(tmpExt) == 0
                fname = strcat(string(fname), ".poly5");
            else
                fname = strrep(fname, tmpExt, ".poly5");
            end
            fname_tablet = strrep(fname,"%s","TABLET");
            fname_tablet = strrep(fname_tablet,'.poly5','.bin');
            fprintf(1, "File name updated: %s\n", fname);
        end
        
        % Check for parameter updates.
        while udp_param_receiver.NumBytesAvailable > 0
            parameter_data = udp_param_receiver.readline();
            param = parse_parameter_message(parameter_data, param);
        end

        while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit")) && (~strcmpi(state, "imp"))
            % Check for a filename update.
            while udp_name_receiver.NumBytesAvailable > 0
                tmp = udp_name_receiver.readline();
                if startsWith(strrep(tmp, "\", "/"), param.save_location)
                    fname = tmp;
                else
                    fname = strrep(fullfile(param.save_location, tmp), "\", "/");
                end
                [tmpFolder, tmpFile, tmpExt] = fileparts(fname);
                if exist(tmpFolder,'dir')==0
                    mkdir(tmpFolder);
                end
                if strlength(tmpExt) == 0
                    fname = strcat(string(fname), ".poly5");
                else
                    fname = strrep(fname, tmpExt, ".poly5");
                end
                fname_tablet = strrep(fname,'%s','TABLET');
                fname_tablet = strrep(fname_tablet,'.poly5','.bin');
                fprintf(1, "File name updated: %s\n", fname);
            end

            % Check for a parameter update.
            while udp_param_receiver.NumBytesAvailable > 0
                parameter_data = udp_param_receiver.readline();
                param = parse_parameter_message(parameter_data, param);
            end

            % Sample from both devices (ALWAYS)
            num_sets = zeros(numel(device),1);
            for ii = 1:N_CLIENT
                [samples{ii}, num_sets(ii)] = device(ii).sample();
                while num_sets(ii) < 1
                    pause(0.0001);
                    [samples{ii}, num_sets(ii)] = device(ii).sample();
                end
                % If there are samples present from this device, dump to
                % raw data outlet ( if enabled ), and apply filtering.
                if ~isempty(samples{ii})
                    if param.enable_filters
                        [hpf_data.(device(ii).tag), zi.squiggles.(device(ii).tag)] = filter(param.hpf.b,param.hpf.a,samples{ii}(i_all.(device(ii).tag),:)',zi.squiggles.(device(ii).tag),1);
                        if size(hpf_data.(device(ii).tag),2) >= 64
                            if param.gui.squiggles.whiten.(device(ii).tag) % Then do the Whitening chain
                                cat_data = [param.prev_data.(device(ii).tag); hpf_data.(device(ii).tag)(:,1:64)];
                                edata = fast_extend(cat_data', param.dsp_extension_factor);
                                hpf_data.(device(ii).tag)(:,1:64) = (param.gui.squiggles.offset .* param.P.(device(ii).tag).Wz * param.P.(device(ii).tag).P * edata(:,(param.dsp_extension_factor+1):(end-param.dsp_extension_factor+1)))';
                                param.prev_data.(device(ii).tag) = cat_data((end-param.dsp_extension_factor+1):end,:);
                            else
                                switch param.virtual_ref_mode
                                    case 1    
                                        hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)) = hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)) - mean(hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)));
                                    case 2 
                                        iGrid1 = param.use_channels.(device(ii).tag)(param.use_channels.(device(ii).tag) <= 32);
                                        iGrid2 = setdiff(param.use_channels.(device(ii).tag), iGrid1);
                                        hpf_data.(device(ii).tag)(:,iGrid1) = hpf_data.(device(ii).tag)(:,iGrid1) - mean(hpf_data.(device(ii).tag)(:,iGrid1));
                                        hpf_data.(device(ii).tag)(:,iGrid2) = hpf_data.(device(ii).tag)(:,iGrid2) - mean(hpf_data.(device(ii).tag)(:,iGrid2));
                                    case 3
                                        tmp = reshape(hpf_data.(device(ii).tag)(:,1:64)', 8, 8, num_sets(ii));
                                        if param.interpolate_grid
                                            for ik = 1:num_sets(ii)
                                                tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
                                            end
                                        end
                                        hpf_data.(device(ii).tag)(:,1:64) = reshape(del2(tmp),64,num_sets(ii))';
                                    case 4
                                        % tmp = reshape(hpf_data.(device(ii).tag)(:,1:32)', 8, 4, num_sets(ii));
                                        % tmp2 = reshape(hpf_data.(device(ii).tag)(:,33:64)', 8, 4, num_sets(ii));
                                        % if param.interpolate_grid
                                        %     for ik = 1:num_sets(ii)
                                        %         tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
                                        %         tmp2(:,:,ik) = fillmissing2(tmp2(:,:,ik),'linear');
                                        %     end
                                        % end
                                        % hpf_data.(device(ii).tag)(:,1:32) = reshape(del2(tmp),32,num_sets(ii))';
                                        % hpf_data.(device(ii).tag)(:,33:64) = reshape(del2(tmp2),32,num_sets(ii))';
                                        hpf_data.(device(ii).tag)(:,1:64) = handle_2textile_del2_interp(hpf_data.(device(ii).tag)(:,1:64),param.interpolate_grid);
                                end
                            end
                        end
                        [env_data.(device(ii).tag), zi.envelope.(device(ii).tag)] = filter(param.lpf.b, param.lpf.a, abs(hpf_data.(device(ii).tag)), zi.envelope.(device(ii).tag), 1);
                    end
                    if param.enable_trigger_controller && strcmpi(device(ii).tag,'A') % Only use SAGA-A
                        if param.parse_from_bits
                            trigSamples = samples{ii}(config.SAGA.A.Trigger.Channel,:);
                            disp(size(trigSamples,2));
                            if param.emulate_mouse
                                if param.trig_out_en(1)
                                    if trig_out_state(1)   % If we have been holding the mouse down:
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(1))==0)
                                            writeline(param.mouse.client, 'off,left'); % Release the left D-pad ('ArrowLeft' keypress)
                                            trig_out_state(1) = false;
                                        end
                                    else % Otherwise, check if we should go to mouse-down state
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(1))==param.trig_out_mask(1))
                                            writeline(param.mouse.client, 'on,left'); % Begin the click left D-pad ('ArrowLeft' keypress)
                                            trig_out_state(1) = true;
                                        end
                                    end
                                end
    
                                if param.trig_out_en(2)
                                    if trig_out_state(2) 
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(2))==0)
                                            writeline(param.mouse.client, 'off,right'); % Release the rightD-pad ('ArrowRight' keypress)
                                            trig_out_state(2) = false;
                                        end
                                    else
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(2))==param.trig_out_mask(2))
                                            writeline(param.mouse.client, 'on,right'); % Begin the click right D-pad ('ArrowRight' keypress)
                                            trig_out_state(2) = true;
                                        end
                                    end
                                end
                            else
                                if param.trig_out_en(1)
                                    if trig_out_state(1)  % If we have been holding the mouse down:
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(1))==0)
                                            writeline(param.gamepad.client, '41'); % Release the left D-pad ('ArrowLeft' keypress)
                                            trig_out_state(1) = false;
                                        end
                                    else % Otherwise, check if we should go to mouse-down state
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(1))==param.trig_out_mask(1))
                                            writeline(param.gamepad.client, '40'); % Begin the click left D-pad ('ArrowLeft' keypress)
                                            trig_out_state(1) = true;
                                        end
                                    end
                                end
        
                                if param.trig_out_en(2)
                                    if trig_out_state(2) 
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(2))==0)
                                            writeline(param.gamepad.client, '61'); % Release the rightD-pad ('ArrowRight' keypress)
                                            trig_out_state(2) = false;
                                        end
                                    else
                                        if any(bitand(trigSamples(1,:), param.trig_out_mask(2))==param.trig_out_mask(2))
                                            writeline(param.gamepad.client, '60'); % Begin the click right D-pad ('ArrowRight' keypress)
                                            trig_out_state(2) = true;
                                        end
                                    end
                                end
                            end
                        else
                            if param.enable_filters
                                if param.gui.squiggles.hpf_mode
                                    trigSamples = hpf_data.A(:,param.trig_out_chan)';
                                else
                                    trigSamples = env_data.A(:,param.trig_out_chan)';
                                end
                            else
                                trigSamples = samples{ii}(param.trig_out_chan,:);
                            end
                            
                            nTrigs = size(trigSamples,2);
                            % disp(nTrigs);
                            if param.emulate_mouse
                                if param.trig_out_en(1)
                                    if trig_out_state(1)  % If we have been holding the mouse down:
                                        [makeTransition, statePrev(1,1)] = detectFallingStateTransition(trigSamples(1,:), param.trig_out_sliding_threshold(1,1), param.trig_out_threshold(1,1), nTrigs, statePrev(1,1), nTrigsPrev);
                                        if (stateDebounceIterations(1) > param.trig_out_debounce_iterations)
                                            
                                            if makeTransition
                                                disp('Left FALLING');
                                                writeline(param.mouse.client, 'off,left'); % Release the left D-pad ('ArrowLeft' keypress)
                                                trig_out_state(1) = false;
                                                stateDebounceIterations(1) = 0;
                                            end
                                        else
                                            stateDebounceIterations(1) = stateDebounceIterations(1) + 1;
                                        end
                                    else % Otherwise, check if we should go to mouse-down state
                                        [makeTransition, statePrev(1,1)] = detectRisingStateTransition(trigSamples(1,:), param.trig_out_sliding_threshold(1,1), param.trig_out_threshold(1,2), nTrigs, statePrev(1,1), nTrigsPrev);
                                        if (stateDebounceIterations(1) > param.trig_out_debounce_iterations)
                                            
                                            if makeTransition
                                                disp('Left RISING');
                                                writeline(param.mouse.client, 'on,left'); % Begin the click left D-pad ('ArrowLeft' keypress)
                                                trig_out_state(1) = true;
                                                stateDebounceIterations(1) = 0;
                                            end
                                        else
                                            stateDebounceIterations(1) = stateDebounceIterations(1) + 1;
                                        end
                                    end
                                end
    
                                if param.trig_out_en(2)
                                    if trig_out_state(2) 
                                        [makeTransition, statePrev(1,2)] = detectFallingStateTransition(trigSamples(2,:), param.trig_out_sliding_threshold(1,2), param.trig_out_threshold(2,1), nTrigs, statePrev(1,2), nTrigsPrev);
                                        if (stateDebounceIterations(2) > param.trig_out_debounce_iterations)
                                            
                                            if makeTransition
                                                disp('Right FALLING');
                                                writeline(param.mouse.client, 'off,right'); % Release the rightD-pad ('ArrowRight' keypress)
                                                trig_out_state(2) = false;
                                                stateDebounceIterations(2) = 0;
                                            end
                                        else
                                            stateDebounceIterations(2) = stateDebounceIterations(2) + 1;
                                        end
                                    else
                                        [makeTransition, statePrev(1,2)] = detectRisingStateTransition(trigSamples(2,:), param.trig_out_sliding_threshold(1,2), param.trig_out_threshold(2,2), nTrigs, statePrev(1,2), nTrigsPrev);
                                        if (stateDebounceIterations(2) > param.trig_out_debounce_iterations)
                                            
                                            if makeTransition
                                                disp('Right RISING');
                                                writeline(param.mouse.client, 'on,right'); % Begin the click right D-pad ('ArrowRight' keypress)
                                                trig_out_state(2) = true;
                                                stateDebounceIterations(2) = 0;
                                            end
                                        else
                                            stateDebounceIterations(2) = stateDebounceIterations(2) + 1;
                                        end
                                    end
                                end
                            else
                                if param.trig_out_en(1)
                                    if trig_out_state(1)  % If we have been holding the mouse down:
                                        [makeTransition, statePrev(1,1)] = detectFallingStateTransition(trigSamples(1,:), param.trig_out_sliding_threshold(1,1), param.trig_out_threshold(1,1), nTrigs, statePrev(1,1), nTrigsPrev);
                                        if (stateDebounceIterations(1) > param.trig_out_debounce_iterations)
                                            
                                            if makeTransition
                                                disp('Left FALLING');
                                                writeline(param.gamepad.client, '41'); % Release the left D-pad ('ArrowLeft' keypress)
                                                trig_out_state(1) = false;
                                                stateDebounceIterations(1) = 0;
                                            end
                                        else
                                            stateDebounceIterations(1) = stateDebounceIterations(1) + 1;
                                        end
                                    else % Otherwise, check if we should go to mouse-down state
                                        [makeTransition, statePrev(1,1)] = detectRisingStateTransition(trigSamples(1,:), param.trig_out_sliding_threshold(1,1), param.trig_out_threshold(1,2), nTrigs, statePrev(1,1), nTrigsPrev);
                                        if (stateDebounceIterations(1) > param.trig_out_debounce_iterations)
                                           
                                            if makeTransition
                                                disp('Left RISING');
                                                writeline(param.gamepad.client, '40'); % Begin the click left D-pad ('ArrowLeft' keypress)
                                                trig_out_state(1) = true;
                                                stateDebounceIterations(1) = 0;
                                            end
                                        else
                                            stateDebounceIterations(1) = stateDebounceIterations(1) + 1;
                                        end
                                    end
                                end
        
                                if param.trig_out_en(2)
                                    if trig_out_state(2) 
                                        [makeTransition, statePrev(1,2)] = detectFallingStateTransition(trigSamples(2,:), param.trig_out_sliding_threshold(1,2), param.trig_out_threshold(2,1), nTrigs, statePrev(1,2), nTrigsPrev);
                                        if stateDebounceIterations(2) > param.trig_out_debounce_iterations
                                            if makeTransition
                                                disp('Right FALLING');
                                                writeline(param.gamepad.client, '61'); % Release the rightD-pad ('ArrowRight' keypress)
                                                trig_out_state(2) = false;
                                                stateDebounceIterations(2) = 0;
                                            end
                                        else
                                            stateDebounceIterations(2) = stateDebounceIterations(2) + 1;
                                        end
                                    else
                                        [makeTransition, statePrev(1,2)] = detectRisingStateTransition(trigSamples(2,:), param.trig_out_sliding_threshold(1,2), param.trig_out_threshold(2,2), nTrigs, statePrev(1,2), nTrigsPrev);
                                        if stateDebounceIterations(2) > param.trig_out_debounce_iterations
                                            if makeTransition
                                                disp('Right RISING');
                                                writeline(param.gamepad.client, '60'); % Begin the click right D-pad ('ArrowRight' keypress)
                                                trig_out_state(2) = true;
                                                stateDebounceIterations(2) = 0;
                                            end
                                        else
                                            stateDebounceIterations(2) = stateDebounceIterations(2) + 1;
                                        end
                                    end
                                end
                            end
                            nTrigsPrev = nTrigs;
                        end
                    
                    end
                    if param.enable_raw_lsl_outlet
                        lsl_outlet_obj.(device(ii).tag).push_chunk(samples{ii});
                    end
                    
                    if needs_offset && (ii > 1) && (num_sets(1) > 0)
                        counter_offset = samples{1}(config.SAGA.(device(1).tag).Channels.COUNT, end) - samples{ii}(config.SAGA.(device(ii).tag).Channels.COUNT, end);
                        needs_offset = false;
                    end
                end
            end

            % Dump envelope samples to LSL outlet (if required)
            if param.enable_envelope_lsl_outlet 
                for ii = 1:N_CLIENT
                    if ~isempty(env_data.(device(ii).tag))
                        i_assign_max = find(strcmpi(TAG,device(ii).tag));
                        envelope_bin_sample((1:64)+(i_assign_max-1)*64,1) = max(env_data.(device(ii).tag)(:,grid_ch_uni.(device(ii).tag)),[],1)';
                    end
                end
                lsl_outlet_env.push_sample(max(envelope_bin_sample,1e-3));
            end

            % Handle using TABLET figure (if required)
            if param.enable_tablet_figure
                pkt = WinTabMex(5);
                if ~isempty(pkt)
                    tmp = WinTabMex(5);
                    while ~isempty(tmp) % Always grab the last event in queue.
                        pkt = tmp;
                        tmp = WinTabMex(5);
                    end
                    tablet_fig.UserData.PressureLine.h.YData(tablet_fig.UserData.PressureLine.idx) = pkt(9);
                    tablet_fig.UserData.PressureLine.idx = rem(tablet_fig.UserData.PressureLine.idx,1000)+1;
                    tablet_fig.UserData.PressureLine.h.YData(tablet_fig.UserData.PressureLine.idx) = nan;
                    
                    if pkt(9) > 0
                        tablet_fig.UserData.PressureSpots.h.XData(tablet_fig.UserData.PressureSpots.idx) = pkt(1);
                        tablet_fig.UserData.PressureSpots.h.YData(tablet_fig.UserData.PressureSpots.idx) = pkt(2);
                        tablet_fig.UserData.PressureSpots.h.CData = circshift(tablet_fig.UserData.PressureSpots.h.CData,-1);
                        tablet_fig.UserData.PressureSpots.h.SizeData(tablet_fig.UserData.PressureSpots.idx) = pkt(9)/10;
                        tablet_fig.UserData.PressureSpots.idx = rem(tablet_fig.UserData.PressureSpots.idx,1000)+1;
                    end
                    if recording
                        fwrite(rec_file_tablet, uint32([samples{1}(end,end),pkt(1),pkt(2),pkt(9)]), 'uint32');
                    end
                end
            end

            % Check for a "control state" update.
            if udp_state_receiver.NumBytesAvailable > 0
                tmpState = lower(string(readline(udp_state_receiver)));
                if ismember(tmpState, ["rec", "idle", "quit", "imp", "run"])
                    state = tmpState;
                elseif startsWith(tmpState, "ping")
                    msgParts = strsplit(tmpState, ":");
                    switch numel(msgParts)
                        case 1
                            writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 2
                            writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                msgParts{2}, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 3
                            writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                msgParts{2}, str2double(msgParts{3}));
                    end
                elseif startsWith(tmpState, "name")
                    msgParts = strsplit(tmpState, ":");
                    switch numel(msgParts)
                        case 1
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 2
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                msgParts{2}, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 3
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                msgParts{2}, str2double(msgParts{3}));
                    end
                else
                    fprintf("[TMSi]::[STATE] Tried to assign incorrect state (%s) -- check sender port.\n", tmpState);
                end
                if strcmpi(state, "rec")
                    if ~recording
                        fprintf(1, "[TMSi]::[RUN > REC]: Buffer created, recording in process...\n");
                        rec_file = struct;
                        for ii = 1:N_CLIENT
                            rec_file.(device(ii).tag) = TMSiSAGA.Poly5(strrep(fname,"%s",param.name_tag.(device(ii).tag)), device(ii).sample_rate, ch{ii}.toStruct(), 'w');
                        end
                        if param.enable_tablet_figure
                            rec_file_tablet = fopen(fname_tablet, 'w');
                            % Write header with creation time and column names
                            creationTime = datestr(now, 'yyyy-mm-dd HH:MM:SS'); %#ok<TNOW1,DATST>
                            headerLine1 = sprintf('Creation Time: %s\n', creationTime);
                            headerLine2 = sprintf('%s\n',char(param.name_tag.(device(1).tag)));
                            headerLine3 = sprintf('Index | X | Y | Pressure\n');
                            fprintf(rec_file_tablet, headerLine1);
                            fprintf(rec_file_tablet, headerLine2);
                            fprintf(rec_file_tablet, headerLine3);
                        end
                    end
                    recording = true;
                    running = true;
                else
                    running = strcmpi(state, "run");
                    if ~running
                        stop(device);
                    end
                    if recording
                        fprintf(1, "[TMSi]::[REC > RUN]: Recording complete\n\t->\t(%s)\n", fname);
                        for ii = 1:N_CLIENT
                            % delete(rec_file.(device(ii).tag));
                            rec_file.(device(ii).tag).close();
                        end
                        if param.enable_tablet_figure
                            fclose(rec_file_tablet);
                        end
                    end
                    recording = false;
                end
            end
            
            % If recording, log the samples in the recording buffer. 
            if recording
                for ii = 1:N_CLIENT
                    if ~isempty(samples{ii})
                        rec_file.(device(ii).tag).append(samples{ii});
                    end
                end
                % If using tablet mex, log samples from tablet
                if param.enable_tablet_figure
                    
                end
            end

            % Handle updating the "Squiggles" GUI if required
            if param.gui.squiggles.enable
                if isvalid(param.gui.squiggles.fig)
                    sample_counts = struct;
                    i_assign = struct;
                    for ii = 1:N_CLIENT
                        if size(samples{ii},2) > 0
                            sample_counts.(device(ii).tag) = samples{ii}(config.SAGA.(device(ii).tag).Channels.COUNT,:) + counter_offset*(ii-1);
                            i_assign.(device(ii).tag) = mod([sample_counts.(device(ii).tag)-1, sample_counts.(device(ii).tag)(end)], param.gui.squiggles.n_samples)+1;
                            % grid_channels = param.gui.squiggles.channels.(device(ii).tag)(param.gui.squiggles.channels.(device(ii).tag) <= 64);
                            for iCh = 1:numel(grid_ch_uni.(device(ii).tag))
                                cur_ch = param.gui.squiggles.channels.(device(ii).tag)(iCh);
                                if param.gui.squiggles.hpf_mode
                                    cur_data = hpf_data.(device(ii).tag)(:,cur_ch)';
                                else
                                    cur_data = env_data.(device(ii).tag)(:,cur_ch)';
                                end
                                param.gui.squiggles.h.(device(ii).tag)(iCh).YData(i_assign.(device(ii).tag)) = [cur_data + (8-rem((cur_ch-1),8))*param.gui.squiggles.offset, nan];
                            end
                        else
                            sample_counts.(device(ii).tag) = [];
                            i_assign.(device(ii).tag) = [];
                        end
                    end
                    if param.gui.squiggles.triggers.enable 
                        for ii = 1:N_CLIENT
                            if ~isempty(i_assign.(device(ii).tag))
                                param.gui.squiggles.h.Triggers.(device(ii).tag).YData(i_assign.(device(ii).tag)) = [samples{ii}(config.SAGA.(device(ii).tag).Trigger.Channel,:), nan];
                            end
                        end
                    end
                else
                    param.gui.squiggles.fig = [];
                    param.gui.squiggles.enable = false;
                    fprintf(1,'[TMSi]::[Squiggles GUI] Gui was closed.\n');
                end
            end
            pause(param.pause_duration); % Allow the other callbacks to process.
            drawnow limitrate;
        end % END: while running or recording
        while udp_state_receiver.NumBytesAvailable > 0
            tmpState = lower(string(readline(udp_state_receiver)));
            if ismember(tmpState, ["rec", "idle", "quit", "imp", "run"])
                state = tmpState;
            elseif startsWith(tmpState, "ping")
                msgParts = strsplit(tmpState, ":");
                switch numel(msgParts)
                    case 1
                        writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                            config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
                    case 2
                        writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                            msgParts{2}, config.UDP.Socket.RecordingControllerGUI.Port);
                    case 3
                        writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                            msgParts{2}, str2double(msgParts{3}));
                end
            elseif startsWith(tmpState, "name")
                    msgParts = strsplit(tmpState, ":");
                    switch numel(msgParts)
                        case 1
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 2
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                msgParts{2}, config.UDP.Socket.RecordingControllerGUI.Port);
                        case 3
                            writeline(udp_state_receiver, jsonencode(struct('type', 'name', 'value', fname)), ...
                                msgParts{2}, str2double(msgParts{3}));
                    end
            else
                fprintf("[TMSi]::[STATE] Tried to assign incorrect state (%s) -- check sender port.\n", tmpState);
            end
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "[TMSi]::[IDLE > REC]: Buffer created, recording in process...\n");
                    rec_file = struct;
                    for ii = 1:N_CLIENT
                        rec_file.(device(ii).tag) = TMSiSAGA.Poly5(strrep(fname,"%s",param.name_tag.(device(ii).tag)), device(ii).sample_rate, ch{ii}.toStruct(), 'w');
                        
                    end
                end
                recording = true;
                if ~running
                    start(device);
                    needs_offset = true;
                    counter_offset = 0;
                    running = true;
                end
            elseif strcmpi(state, "run")
                if ~running
                    start(device);
                    needs_offset = true;
                    counter_offset = 0;
                    running = true;
                end
            end
            % If we are in impedance mode, change device config and show
            % impedances for each device, sequentially.
            if strcmpi(state, "imp")
                iPlot = cell(size(device));
                s = cell(size(device));
                fig = gobjects(1, numel(device));
                for ii = 1:numel(device)
                    configImpedanceMode(device(ii), config_channel_impedance, config_device_impedance);
                    start(device(ii));
                    channel_names = getName(getActiveChannels(device(ii)));
                    fig(ii) = uifigure(...
                        'Name', sprintf('Impedance Plot: SAGA-%s', device(ii).tag), ...
                        'Color', 'w', ...
                        'Icon', 'Impedance-Symbol.png', ...
                        'HandleVisibility', 'on', ...
                        'Position', IMPEDANCE_FIGURE_POSITION(ii,:));
                    iPlot{ii} = TMSiSAGA.ImpedancePlot(fig(ii), channel_names);
                end

                while any(isvalid(fig)) || ~strcmpi(state, "imp")
                    if udp_state_receiver.NumBytesAvailable > 0
                        tmpState = lower(string(readline(udp_state_receiver)));
                        if ismember(tmpState, ["rec", "idle", "quit", "imp", "run"])
                            state = tmpState;
                        elseif startsWith(tmpState, "ping")
                            msgParts = strsplit(tmpState, ":");
                            switch numel(msgParts)
                                case 1
                                    writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                        config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
                                case 2
                                    writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                        msgParts{2}, config.UDP.Socket.RecordingControllerGUI.Port);
                                case 3
                                    writeline(udp_state_receiver, jsonencode(struct('type', 'res', 'value', state)), ...
                                        msgParts{2}, str2double(msgParts{3}));
                            end
                        else
                            fprintf("[TMSi]::[STATE] Tried to assign incorrect state (%s) -- check sender port.\n", tmpState);
                        end
                    end
                    for ii = 1:numel(device)
                        if isvalid(fig(ii))
                            [samples{ii}, num_sets] = device(ii).sample();
                            % Append samples to the plot and redraw
                            if num_sets > 0
                                s{ii} = samples{ii} ./ 10^6; % need to divide by 10^6
                                iPlot{ii}.grid_layout(s{ii});
                                drawnow limitrate;
                            end
                            pause(param.pause_duration);
                        end
                    end
                end

                for ii = 1:numel(device)
                    device(ii).stop();
                    enableChannels(device(ii), device(ii).channels);
                    configStandardMode(device(ii), config_channels.(device(ii).tag), config_device);
                    impedance_saver_helper(fname, device(ii).tag, s{ii});
                end
                if strcmpi(state, "imp")
                    state = "idle";
                end
                writeline(udp_state_receiver, jsonencode(struct('type', 'status', 'value', 'resume')), config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
    
            end
        end
    end
    stop(device);
    writeline(udp_state_receiver, jsonencode(struct('type', 'status', 'value', 'stop')), config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
    state = "idle";
    recording = false;
    running = false;
    disconnect(device);
    clear client udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    try %#ok<TRYNC>
        for ii = 1:numel(device)
            delete(lsl_info_obj.(device(ii).tag));
            delete(lsl_outlet_obj.(device(ii).tag));
        end
        delete(lsl_info_env);
        delete(lsl_outlet_env);
        delete(lsl_info_decode);
        delete(lsl_outlet_decode);
        delete(lib_lsl);
    end
    if ~isempty(param.mouse.client)
        delete(param.mouse.client);
    end
    if ~isempty(param.gamepad.client)
        delete(param.gamepad.client);
    end
    clear lsl_info_obj lsl_outlet_obj lib_lsl lsl_outlet_env lsl_info_env lsl_outlet_decode lsl_info_decode
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    close all force;
catch me
    % Stop both devices.
    stop(device);
    disconnect(device);
    writeline(udp_state_receiver, jsonencode(struct('type', 'status', 'value', 'stop')), config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
    warning(me.message);
    disp(me.stack);
    if ~isempty(param.mouse.client)
        delete(param.mouse.client);
    end
    if ~isempty(param.gamepad.client)
        delete(param.gamepad.client);
    end
    clear client udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    try %#ok<TRYNC>
        for ii = 1:numel(device)
            delete(lsl_info_obj.(device(ii).tag));
            delete(lsl_outlet_obj.(device(ii).tag));
        end
        delete(lsl_info_env);
        delete(lsl_outlet_env);
        delete(lsl_info_decode);
        delete(lsl_outlet_decode);
        delete(lib_lsl);
    end
    clear lsl_info_obj lsl_outlet_obj lib_lsl lsl_outlet_env lsl_info_env lsl_info_decode lsl_outlet_decode
    close all force;
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
