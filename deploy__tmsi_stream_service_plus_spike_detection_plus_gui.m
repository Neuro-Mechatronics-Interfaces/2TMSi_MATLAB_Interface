%DEPLOY__TMSI_STREAM_SERVICE_PLUS_SPIKE_DETECTION_PLUS_GUI - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) server.
% Starts up the Tablet "Pressure Tracker" GUI (HIGHLY EXPERIMENTAL FEATURE!)
%
% See details in README.MD

%% Handle some basic startup stuff.
clc;
if exist('server', 'var')~=0
    delete(server);
end

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
config_device = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
    'Triggers', true, ...
    'BaseSampleRate', 4000, ...
    'RepairLogging', false, ...
    'ImpedanceMode', false, ...
    'AutoReferenceMethod', false, ...
    'ReferenceMethod', config.Default.Device_Reference_Mode,... % must be 'common' or 'average'
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
    ..."LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.state, ...
    "EnablePortSharing", true);
udp_name_receiver = udpport("byte", ...
    "LocalHost", "0.0.0.0", ...
    ..."LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.name, ...
    "EnablePortSharing", true);
udp_param_receiver = udpport("byte", ...
    "LocalHost", "0.0.0.0", ...
    ... "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.params, ...
    "EnablePortSharing", true);
tcp_spike_server = tcpserver("0.0.0.0", ... % Allow any IP to connect
                             config.TCP.SpikeServer.Port);
tcp_spike_server.ConnectionChangedFcn = @reportSocketConnectionChange;
tcp_rms_server = tcpserver("0.0.0.0", ...
                            config.TCP.RMSServer.Port);
tcp_rms_server.ConnectionChangedFcn = @reportSocketConnectionChange;
tcp_muap_server = tcpserver("0.0.0.0", ...
                            config.TCP.MUAPServer.Port);
tcp_muap_server.ConnectionChangedFcn = @reportSocketConnectionChange;
tcp_squiggles_server = tcpserver("0.0.0.0",config.TCP.SquiggleServer.Port);
tcp_squiggles_server.UserData = struct('current_channel',1,'has_new_channel',true,'SAGA',"A");
tcp_squiggles_server.ConnectionChangedFcn = @reportSocketConnectionChange;
configureCallback(tcp_squiggles_server, "terminator", @handleChannelChangeRequest);
configureCallback(tcp_muap_server, "terminator", @handleMUAPserverMessages);

%% Initialize parameters and parameter sub-fields, figures
param = struct(...
    'n_channels', struct('A', [], 'B', []), ...
    'n_spike_channels', max(numel(config.GUI.Squiggles.A), numel(config.GUI.Squiggles.B)), ...
    'name_tag', struct('A', "A", 'B', "B"), ...
    'selected_spike_channels', struct('A', [4, 24, 55], 'B', [4, 24, 55]), ...
    'n_samples_recording', config.Default.N_Samples_Recording, ...
    'recording_samples_acquired', struct('A', 0, 'B', 0), ...
    'recording_chunk_offset', struct('A', 0, 'B', 0), ...
    'classifier', struct('A', [], 'B', []), ...
    'envelope_regressor', struct('A',[],'B',[]), ...
    'n_total', struct('A', numel(config_channels.A.uni) + numel(config_channels.A.bip), 'B', numel(config_channels.B.uni) + numel(config_channels.B.bip)), ...
    'sample_rate', config.Default.Sample_Rate, ...
    'spike_detector', config.Default.Spike_Detector, ...
    'car_mode', config.Default.CAR_Mode, ...
    'interpolate_grid', config.Default.Interpolate_Grid, ...
    'acquire_mvc',false, ...
    'mvc_samples', config.Default.MVC_Sample_Iterations, ...
    'mvc_data', [], ...
    'hpf', struct('b', [], 'a', []), ...
    'gui', struct('squiggles', struct('enable', config.GUI.Squiggles.Enable, 'fig', [], 'h', [], 'offset', config.GUI.Offset, 'hpf_mode', config.GUI.Squiggles.HPF_Mode, ...
                                      'channels', struct('A', [], 'B', []), 'zi', struct('A', [], 'B', []), 'n_samples', config.GUI.N_Samples, 'color', config.GUI.Color, ...
                                      'acc', struct('enable', config.Accelerometer.Enable, 'differential', config.Accelerometer.Differential, 'saga', config.Accelerometer.SAGA), ...
                                      'triggers', struct('enable', config.Triggers.Enable, 'y_bound', config.GUI.TriggerBound), ...
                                      'tag', struct('A', "A", 'B', "B")), ...
                  'cal', struct('enable', config.GUI.Calibration.Enable, 'fig', [], 'h', [], ...
                                'data', load(config.Default.Calibration_File), ...
                                'file', config.Default.Calibration_File), ...
                  'sch', struct('enable', config.GUI.Single.Enable, 'fig', [], 'h', [], ...
                                'saga', config.GUI.Single.SAGA, ...
                                'channel', config.GUI.Single.Channel,  ...
                                'n_samples', config.GUI.N_Samples, ...
                                'color', config.GUI.Color, ...
                                'state', config.Default.Calibration_State, ...
                                'tag', struct('A', "A", 'B', "B"))), ...
    'calibrate', struct('A', false, 'B', false), ...
    'calibration_running', false, ...
    'calibration_samples_acquired', struct('A', 0, 'B', 0),  ...
    'reinit_calibration_data', false, ...
    'hpf_max', struct('A', ones(1,numel(config_channels.A.uni)+numel(config_channels.A.bip)),'B', ones(1,numel(config_channels.B.uni)+numel(config_channels.B.bip))), ...
    'env_max', struct('A', ones(1,numel(config_channels.A.uni)+numel(config_channels.A.bip)),'B', ones(1,numel(config_channels.B.uni)+numel(config_channels.B.bip))), ...
    'rate_smoothing_alpha', reshape(config.Default.Rate_Smoothing_Alpha,numel(config.Default.Rate_Smoothing_Alpha),1), ...
    'learning_rate', 0.00001, ...
    'save_location', strrep(config.Default.Folder,'\','/'),  ...            % Save folder
    'save_params', config.Default.Save_Parameters, ...
    'pause_duration', config.Default.Sample_Loop_Pause_Duration, ...
    'past_rates', struct('A', zeros(numel(config.Default.Rate_Smoothing_Alpha),64), 'B', zeros(numel(config.Default.Rate_Smoothing_Alpha),64)), ...
    'transform', struct('A', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels)), ...
                        'B', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels))), ...
    'threshold', struct('A', struct(config.Default.Calibration_State, inf(1,numel(config_channels.A.uni)+numel(config_channels.A.bip))), ...
                        'B', struct(config.Default.Calibration_State, inf(1,numel(config_channels.A.uni)+numel(config_channels.A.bip)))), ...
    'threshold_deviations', config.Default.Threshold_Deviations, ...
    'threshold_artifact', config.Default.Artifact_Channel_Proportion_Threshold, ...
    'noise_cluster_id', config.Default.Noise_Cluster_ID, ...
    'min_rms_artifact', config.Default.Minimum_RMS_Per_Channel, ...
    'exclude_by_rms', struct('A', false(1,numel(config.GUI.Squiggles.A)), 'B', false(1,numel(config.GUI.Squiggles.B))), ...
    'threshold_pose', config.Default.Pose_Threshold, ...
    'deadzone_pose', config.Default.Pose_Deadzone_Threshold, ...
    'use_channels', struct('A', [], 'B', []), ...
    'n_device', numel(device), ...
    'pose_smoothing_alpha', config.Default.Pose_Smoothing_Alpha, ...
    'enable_raw_lsl_outlet', config.Default.Enable_Raw_LSL_Outlet, ...
    'enable_envelope_lsl_outlet', config.Default.Enable_Envelope_LSL_Outlet, ...
    'enable_tablet_figure', config.Default.Enable_Tablet_Figure);
param.mvc_data = cell(param.mvc_samples, numel(device));
if param.gui.squiggles.acc.enable && param.gui.squiggles.acc.differential && (numel(config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX) < 6)
    disconnect(device);
    lib.cleanUp();
    close all force;
    error("[TMSi]::[Acc Config Error]::Enabled differential accelerometers, but not enough SAGA %s channels are configured for AUX (check %s)", param.gui.squiggles.acc.saga, config_file);
end
param.gui.squiggles.channels.A = config.GUI.Squiggles.A;
param.gui.squiggles.channels.B = config.GUI.Squiggles.B;
param.use_channels.A = config.GUI.Squiggles.A;
param.use_channels.B = config.GUI.Squiggles.B;
param.gui.squiggles.zi.A = zeros(numel(config.GUI.Squiggles.A),2);
param.gui.squiggles.zi.B = zeros(numel(config.GUI.Squiggles.B),2);
[param.hpf.b, param.hpf.a] = butter(3, config.Default.HPF_Cutoff_Frequency/(param.sample_rate/2), 'high');
[param.b_rms, param.a_rms] = butter(3, 0.1, 'low');
[param.b_env, param.a_env] = butter(3, 1.5/(param.sample_rate/2), 'low');
param.n_samples_calibration = param.gui.cal.data.N;
[~,tmpf,~] = fileparts(config.Default.Calibration_File);
param.calibration_state = matlab.lang.makeValidName(lower(tmpf));
param.calibration_data = struct('A', struct(param.calibration_state, randn(param.n_samples_calibration, param.n_total.A)), ...
                                'B', struct(param.calibration_state, randn(param.n_samples_calibration, param.n_total.B)));
param.gui.cal = init_calibration_gui(param.gui.cal);
if numel(device) > 1
    nTotalChannels = param.n_total.A + param.n_total.B;
    
else
    nTotalChannels = param.n_total.(device.tag);
end
param.gui.cal.W = randn(nTotalChannels+4, 4);
param.gui.cal.W([1:64,69:136],:) = 0;

ch = device.getActiveChannels();
if ~iscell(ch)
    ch = {ch};
end

param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
hpf_data = struct('A', [], 'B', []);
rms_data = struct('A',[],'B',[]);
env_data = struct('A',[],'B',[]);
env_history = struct('A', zeros(3,param.n_total.A), 'B', zeros(3, param.n_total.B));
param.n_mvc_acquired = 0;
rms_zi = struct('A',zeros(3,param.n_spike_channels),'B',zeros(3,param.n_spike_channels));
i_mono = struct('A', config.SAGA.A.Channels.UNI, 'B', config.SAGA.B.Channels.UNI);
i_bip = struct('A', config.SAGA.A.Channels.BIP, 'B', config.SAGA.B.Channels.BIP);
i_all = struct('A', union(i_mono.A, i_bip.A), 'B', union(i_mono.B, i_bip.B));
zi = struct('A',zeros(3,numel(i_all.A)), 'B', zeros(3,numel(i_all.B)));
cur_state = [0, 0, 0, 0];

%% Load the LSL library
lslMatlabFolder = fullfile(pwd, '..', 'liblsl-Matlab');
if exist(lslMatlabFolder,'dir')==0
    lslMatlabFolder = parameters('liblsl_folder');
    if exist(lslMatlabFolder, 'dir')==0
        disp("No valid liblsl-Matlab repository detected on this device.");
        fprintf(1,'\t->\tTried: "%s"\n', fullfile(pwd, '..', 'liblsl-Matlab'));
        fprintf(1,'\t->\tTried: "%s"\n', lslMatlabFolder);
        disp("Please check parameters.m in the 2TMSi_MATLAB_Interface repository, and try again.");
        pause(30);
        error("[TMSi]::Missing liblsl-Matlab repository.");
    end
end
addpath(genpath(lslMatlabFolder)); % Adds liblsl-Matlab
lib_lsl = lsl_loadlib();

%% Initialize the LSL stream information and outlets
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

lsl_info_env = lsl_streaminfo(lib_lsl, ...
        'SAGACombined_Envelope', ...       % Name
        'EMG', ...                    % Type
        64*numel(device), ....           % ChannelCount
        1/param.pause_duration, ...                     % NominalSrate
        'cf_float32', ...             % ChannelFormat
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

%% If tablet pressure stream is enabled, then show this
if param.enable_tablet_figure
    tablet_fig = init_pressure_tracking_fig();
end

%% Configuration complete, run main control loop.
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    samples = cell(N_CLIENT,1);
    envelope_max_sample = zeros(64*N_CLIENT,1);
    cat_iter = 0;
    CAT_ITER_TARGET = 4;
    cat_n = 0;
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
    msgId = uint16(0);
    start(device);
    pause(1.0);
    counter_offset = 0;
    needs_offset = true;
    pose_vec = zeros(6,1);
    if N_CLIENT > 1
        past_state = zeros(2,param.n_total.A + param.n_total.B);
    else
        past_state = zeros(2,param.n_total.(device.tag));
    end
    caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
    param.gui.cal.W = randn(nTotalChannels+4, 4);
    for ii = 1:N_CLIENT % Determine number of channels definitively
        [samples{ii}, num_sets] = device(ii).sample();
        while (num_sets < 1)
            fprintf(1,'[TMSi]::[INIT] Waiting for SAGA-%s to generate samples...\n', device(ii).tag);
            pause(0.5);
        end
        param.n_channels.(device(ii).tag) = size(samples{ii},1);
        % needs_timestamp.(device(ii).tag) = false;
        % first_timestamp.(device(ii).tag) = datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS', 'TimeZone', 'America/New_York');
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
            caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
            param.gui.cal.W = randn(nTotalChannels+4, 4);
        end
        
        while udp_param_receiver.NumBytesAvailable > 0
            parameter_data = udp_param_receiver.readline();
            param = parse_parameter_message(parameter_data, param);
            if param.reinit_calibration_data
                caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
                param.gui.cal.W = randn(nTotalChannels+4, 4);
            end
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

                caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
                param.gui.cal.W = randn(nTotalChannels+4, 4);
                fprintf(1, "File name updated: %s\n", fname);
            end

            % Check for a parameter update.
            while udp_param_receiver.NumBytesAvailable > 0
                parameter_data = udp_param_receiver.readline();
                param = parse_parameter_message(parameter_data, param);
                if param.reinit_calibration_data
                    caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
                    param.gui.cal.W = randn(nTotalChannels+4, 4);
                end
            end

            num_sets = zeros(numel(device),1);
            for ii = 1:N_CLIENT
                [samples{ii}, num_sets(ii)] = device(ii).sample();
                
                if ~isempty(samples{ii})
                    if param.enable_raw_lsl_outlet
                        lsl_outlet_obj.(device(ii).tag).push_chunk(samples{ii});
                    end
                    [hpf_data.(device(ii).tag), zi.(device(ii).tag)] = filter(param.hpf.b,param.hpf.a,samples{ii}(i_all.(device(ii).tag),:)',zi.(device(ii).tag),1);
                    [env_data.(device(ii).tag), env_history.(device(ii).tag)] = filter(param.b_env, param.a_env, abs(hpf_data.(device(ii).tag)), env_history.(device(ii).tag), 1);
                    switch param.car_mode
                        case 1    
                            hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)) = hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)) - mean(hpf_data.(device(ii).tag)(:,param.use_channels.(device(ii).tag)));
                        case 2 
                            iGrid1 = param.use_channels.(device(ii).tag)(param.use_channel.(device(ii).tag) <= 32);
                            iGrid2 = setdiff(param.use_channels.(device(ii).tag), iGrid1);
                            hpf_data.(device(ii).tag)(:,iGrid1) = hpf_data.(device(ii).tag)(:,iGrid1) - mean(hpf_data.(device(ii).tag)(:,iGrid1));
                            hpf_data.(device(ii).tag)(:,iGrid2) = hpf_data.(device(ii).tag)(:,iGrid2) - mean(hpf_data.(device(ii).tag)(:,iGrid2));
                        case 3
                            hpf_data.(device(ii).tag)(:,param.exclude_by_rms.(device(ii).tag)) = missing;
                            tmp = reshape(hpf_data.(device(ii).tag)(:,1:64)', 8, 8, num_sets(ii));
                            if param.interpolate_grid
                                for ik = 1:num_sets(ii)
                                    tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
                                end
                            end
                            hpf_data.(device(ii).tag)(:,1:64) = reshape(del2(tmp),64,num_sets(ii))';
                    end
                    if needs_offset && (ii > 1) && (num_sets(1) > 0)
                        counter_offset = samples{1}(config.SAGA.(device(1).tag).Channels.COUNT, end) - samples{ii}(config.SAGA.(device(ii).tag).Channels.COUNT, end);
                        needs_offset = false;
                    end
                end
            end

            if param.enable_envelope_lsl_outlet 
                for ii = 1:N_CLIENT
                    if ~isempty(env_data.(device(ii).tag))
                        i_assign_max = find(strcmpi(TAG,device(ii).tag));
                        grid_channels = param.use_channels.(device(ii).tag)(param.use_channels.(device(ii).tag) <= 64);
                        envelope_max_sample((1:64)+(i_assign_max-1)*64,1) = max(env_data.(device(ii).tag)(:,grid_channels),[],1)';
                    end
                end
                lsl_outlet_env.push_sample(max(envelope_max_sample,1e-3));
            end

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

            if param.acquire_mvc
                if all(num_sets > 0)
                    param.n_mvc_acquired = param.n_mvc_acquired + 1;
                    for ii = 1:numel(device)
                        param.mvc_data{param.n_mvc_acquired,ii} = hpf_data.(device(ii).tag);
                    end
                    if param.n_mvc_acquired == param.mvc_samples
                        param.acquire_mvc = false;
                        for ii = 1:numel(device)
                            tmpdata = vertcat(param.mvc_data{:,ii});
                            tmpdata(1:100,:) = 0;
                            param.hpf_max.(device(ii).tag) = max(abs(tmpdata),[],1);
                            param.hpf_max.(device(ii).tag)(param.hpf_max.(device(ii).tag) < eps) = 1; % So we don't divide by zero
                            param.env_max.(device(ii).tag) = max(filter(param.b_env,param.a_env,tmpdata,[],1),[],1);
                            param.env_max.(device(ii).tag)(param.env_max.(device(ii).tag) < eps) = 1; % So we don't divide by zero
                            param.calibrate.(device(ii).tag) = true;
                        end
                        param.calibration_running = param.gui.cal.enable;
                        param = init_new_calibration(param, param.calibration_state);
                        param.gui.cal = init_calibration_gui(param.gui.cal);
                        caldata_out = init_caldata_out(ORDERED_TAG, param.gui.cal.data);
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
                if param.enable_tablet_figure
                    
                end
            end
            % Handle calibration (if required)
            for ii = 1:N_CLIENT
                if param.calibrate.(device(ii).tag) && (size(hpf_data.(device(ii).tag),1) > 0)
                    n_cal_samples = param.calibration_samples_acquired.(device(ii).tag) + size(hpf_data.(device(ii).tag),1);
                    if n_cal_samples >= param.n_samples_calibration
                        last_sample = size(hpf_data.(device(ii).tag),1) - (n_cal_samples - param.n_samples_calibration);
                        param.calibration_data.(device(ii).tag).(param.calibration_state)((param.calibration_samples_acquired.(device(ii).tag)+1):param.n_samples_calibration,:) = hpf_data.(device(ii).tag)(1:last_sample,:);
                        % param.hpf_max.(device(ii).tag) = max(max(param.calibration_data.(device(ii).tag).(param.calibration_state),[],1),ones(1,param.n_spike_channels));
                        % param.hpf_max.(device(ii).tag)(param.hpf_max.(device(ii).tag)<eps) = 1;
                        param.exclude_by_rms.(device(ii).tag) = rms(param.calibration_data.(device(ii).tag).(param.calibration_state),1) < param.min_rms_artifact;
                        [param.transform.(device(ii).tag).(param.calibration_state), score] = pca(param.calibration_data.(device(ii).tag).(param.calibration_state), 'NumComponents', param.n_spike_channels);
                        param.threshold.(device(ii).tag).(param.calibration_state) = median(abs(param.calibration_data.(device(ii).tag).(param.calibration_state)), 1) * param.threshold_deviations;
                        param.calibrate.(device(ii).tag) = false;
                        param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
                        caldata_out.(device(ii).tag) = param.calibration_data.(device(ii).tag).(param.calibration_state);
                        caldata_out.sampling_complete(ii) = true;
                        if all(caldata_out.sampling_complete)
                            fname_cal = strrep(strrep(fname,"%s_",""),".poly5",sprintf("_%s_cal.mat",param.calibration_state));
                            save(fname_cal,"-struct","caldata_out");
                        end
                        fprintf(1,'[TMSi]::[Calibration]::SAGA-%s "%s" calibration complete.\n', device(ii).tag, param.calibration_state);
                    else
                        param.calibration_data.(device(ii).tag).(param.calibration_state)((param.calibration_samples_acquired.(device(ii).tag)+1):n_cal_samples,:) = hpf_data.(device(ii).tag);
                        param.calibration_samples_acquired.(device(ii).tag) = n_cal_samples;
                    end
                end
            end

            % Handle spike detection if required
            if param.spike_detector
                for ii = 1:N_CLIENT
                    if size(samples{ii},2) > 3
                        grid_channels = param.use_channels.(device(ii).tag)(param.use_channels.(device(ii).tag) <= 64);
                        tmp_rates = detect_spikes(hpf_data.(device(ii).tag)(:,grid_channels), ...
                            param.threshold.(device(ii).tag).(param.calibration_state)(grid_channels), ...
                            param.sample_rate, ...
                            param.threshold_artifact);
                        param.past_rates.(device(ii).tag) = param.rate_smoothing_alpha.*param.past_rates.(device(ii).tag) + (1-param.rate_smoothing_alpha).*repmat(tmp_rates,numel(param.rate_smoothing_alpha),1);
                        
                        n_samp = size(samples{ii},2);
                        if tcp_spike_server.Connected
                            spike_data = struct('SAGA', device(ii).tag, 'data', param.past_rates.(device(ii).tag), 'n', n_samp);
                            writeline(tcp_spike_server, jsonencode(spike_data));
                        end
                        % if tcp_rms_server.Connected
                        %     [rms_data.(device(ii).tag), rms_zi.(device(ii).tag)] = filter(param.b_rms, param.a_rms, hpf_data.(device(ii).tag), rms_zi.(device(ii).tag),1);
                        %     rms_data = struct('SAGA', device(ii).tag, 'data', rms(rms_data.(device(ii).tag)./param.hpf_max.(device(ii).tag),1), 'n', n_samp);
                        %     writeline(tcp_rms_server, jsonencode(rms_data));
                        % end
                        if tcp_rms_server.Connected
                            if ~isempty(param.envelope_regressor.(device(ii).tag))
                                env_img_data = env_data.(device(ii).tag)(:,1:64)';
                                env_img_data(param.envelope_regressor.(device(ii).tag).ExcludeChannels,:) = 0;
                                Yhat = predict(param.envelope_regressor.(device(ii).tag).Net, reshape(env_img_data,8,8,1,[]));
                                packet = struct('N', n_samp, 'SAGA', device(ii).tag, 'Data', int16(mean(Yhat,1)*100), 'Id', msgId);
                                writeline(tcp_rms_server, jsonencode(packet));
                                msgId = rem(msgId + 1, 65535);
                            end
                        end
                        if tcp_muap_server.Connected
                            if ~isempty(param.classifier.(device(ii).tag))
                                if numel(param.classifier.(device(ii).tag).Channels) == param.classifier.(device(ii).tag).Net.input.size
                                    locs = cell(64,1);
                                    for ik = param.classifier.(device(ii).tag).Channels
                                        locs{ik} = find(abs(hpf_data.(device(ii).tag)(:,ik)) > param.classifier.(device(ii).tag).MinPeakHeight(ik));
                                        if ~isempty(locs{ik})
                                            locs{ik} = locs{ik}([true; diff(locs{ik})>1]);
                                        end
                                    end
                                    all_locs = unique(vertcat(locs{:}));
                                    [~,clus] = max(param.classifier.(device(ii).tag).Net(hpf_data.(device(ii).tag)(all_locs,param.classifier.(device(ii).tag).Channels)'),[],1);
                                    clus(clus == param.classifier.A.Net.outputs{1}.size) = param.noise_cluster_id;
                                    packet = struct('N', n_samp, 'Saga', device(ii).tag, 'Sample', all_locs, 'Cluster', clus, 'Id', msgId);
                                    msgId = rem(msgId + 1,65535);
                                    writeline(tcp_muap_server, jsonencode(packet));
                                end
                            end
                        end
                        if (tcp_squiggles_server.Connected && strcmpi(device(ii).tag, tcp_squiggles_server.UserData.SAGA))
                            if ~isempty(param.classifier.(device(ii).tag))
                                squiggle_data = param.classifier.(device(ii).tag).Net(hpf_data.(device(ii).tag)(:,param.classifier.(device(ii).tag).Channels)');
                            else
                                if param.gui.squiggles.hpf_mode
                                    squiggle_data = hpf_data.(device(ii).tag)';
                                else
                                    squiggle_data = env_data.(device(ii).tag)';
                                end
                            end
                            cat_data = [cat_data; int16(squiggle_data(tcp_squiggles_server.UserData.current_channel,:)'*100)]; %#ok<AGROW>
                            cat_n = cat_n + n_samp;
                            cat_iter = cat_iter + 1;
                            if cat_iter == CAT_ITER_TARGET
                                packet = struct('N', cat_n, 'Saga', tcp_squiggles_server.UserData.SAGA, 'Sample', cat_data, 'Channel', tcp_squiggles_server.UserData.current_channel, 'Id', msgId);
                                msgId = rem(msgId + 1, 65535);
                                writeline(tcp_squiggles_server, jsonencode(packet));
                                cat_n = 0;
                                cat_data = [];
                                cat_iter = 0;
                            end
                            
                        end
                    end
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
                            i_assign.(device(ii).tag) = rem([sample_counts.(device(ii).tag)-1, sample_counts.(device(ii).tag)(end)], param.gui.squiggles.n_samples)+1;
                            grid_channels = param.gui.squiggles.channels.(device(ii).tag)(param.gui.squiggles.channels.(device(ii).tag) <= 64);
                            for iCh = 1:numel(grid_channels)
                                cur_ch = param.gui.squiggles.channels.(device(ii).tag)(iCh);
                                if param.gui.squiggles.hpf_mode
                                    cur_data = hpf_data.(device(ii).tag)(:,cur_ch)';
                                else
                                    cur_data = env_data.(device(ii).tag)(:,cur_ch)';
                                end
                                param.gui.squiggles.h.(device(ii).tag)(iCh).YData(i_assign.(device(ii).tag)) = [cur_data + rem((cur_ch-1),8)*param.gui.squiggles.offset, nan];
                            end
                        else
                            sample_counts.(device(ii).tag) = [];
                            i_assign.(device(ii).tag) = [];
                        end
                    end
                    if param.gui.squiggles.acc.enable && ~isempty(i_assign.(param.gui.squiggles.acc.saga))
                        iTag = strcmpi(ORDERED_TAG,param.gui.squiggles.acc.saga);
                        if param.gui.squiggles.acc.differential
                            iDistal = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX([1,4]); 
                            iMedial = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX([2,5]); 
                            iSuperior = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX([3,6]); 
                            distalData = samples{iTag}(iDistal(1),:) - samples{iTag}(iDistal(2),:);
                            medialData = samples{iTag}(iMedial(1),:) - samples{iTag}(iMedial(2),:);
                            superiorData = samples{iTag}(iSuperior(1),:) - samples{iTag}(iSuperior(2),:);  
                        else
                            iDistal = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX(1); 
                            iMedial = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX(2); 
                            iSuperior = config.SAGA.(param.gui.squiggles.acc.saga).Channels.AUX(3);  
                            distalData = samples{iTag}(iDistal,:);
                            medialData = samples{iTag}(iMedial,:);
                            superiorData = samples{iTag}(iSuperior,:);
                        end
                        param.gui.squiggles.h.Acc.Distal.YData(i_assign.(param.gui.squiggles.acc.saga)) = [distalData, nan];
                        param.gui.squiggles.h.Acc.Medial.YData(i_assign.(param.gui.squiggles.acc.saga)) = [medialData + 7, nan];
                        param.gui.squiggles.h.Acc.Superior.YData(i_assign.(param.gui.squiggles.acc.saga)) = [superiorData + 14, nan];
                        pose_vec = param.pose_smoothing_alpha.*pose_vec + (1-param.pose_smoothing_alpha).*([sum(distalData > param.threshold_pose); ...
                                    sum((-distalData) > param.threshold_pose); ...
                                    sum(medialData > param.threshold_pose); ...
                                    sum((-medialData) > param.threshold_pose); ...
                                    sum(superiorData > param.threshold_pose); ...
                                    sum((-superiorData) > param.threshold_pose)]);

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
                    fprintf(1,'[TMSi]::[SQUIGGLES] Gui was closed.\n');
                end
            end

            % Handle updating the "Calibrator" GUI if required
            if param.gui.cal.enable && param.calibrate.(device(1).tag)
                if isvalid(param.gui.cal.fig) && all(num_sets > 2)
                    cur_samples = param.gui.cal.data.current_samples + param.calibration_samples_acquired.(device(1).tag)+1;
                    cur_samples(cur_samples > param.gui.cal.data.N) = param.gui.cal.data.N;
                    target_plot = param.gui.cal.data.target_data(cur_samples,1:2);
                    % target_state = [target_plot(3:end,:), target_plot(2:(end-1),:), target_plot(1:(end-2),:)];
                    set(param.gui.cal.h.target,'XData',target_plot(:,1),'YData',target_plot(:,2));
                    if param.gui.cal.data.use_feedback
                        %TODO: Add in user feedback for controlling point position here.
                        
                        if numel(device) > 1
                            n_min = min(num_sets);
                            cur_emg = [env_data.A(1:n_min,:), env_data.B(1:n_min,:)];
                            % [xy_state, past_state] = envelope_proj_2_state([env_data.A(1:n_min,:),env_data.B(1:n_min,:)],past_state,param.gui.cal.data.transform.coeff,param.gui.cal.data.transform.mu);
                            % cur_xy = predict(param.gui.cal.data.net,[env_data.A(1:n_min,:), env_data.B(1:n_min,:)]);
                            
                        else
                            cur_emg = env_data.(device.tag);
                            n_min = size(cur_emg,1);
                            % [xy_state, past_state] = envelope_proj_2_state(env_data.(device.tag),past_state,param.gui.cal.data.transform.coeff,param.gui.cal.data.transform.mu);
                            % cur_xy = predict(param.gui.cal.data.net,env_data.(device.tag));
                        end
                        % predState = zeros(n_min,4);
                        % U = zeros(size(cur_emg,1),size(cur_emg,2)+4);
                        % Y = [target_plot(2:(n_min+1),:), target_plot(3:(n_min+2),:)];
                        % for iPred = 1:n_min
                        %     U(iPred,:) = [cur_emg(iPred,:), cur_state];
                        %     predState(iPred,:) = U(iPred,:) * param.gui.cal.W;
                        %     cur_state = predState(iPred,:);
                        % 
                        %     dW = (U(iPred,:)' * (predState(iPred,:) - Y(iPred,:))) / size(U, 1);  % Gradient of loss w.r.t. weights
                        % 
                        %     param.gui.cal.W = param.gui.cal.W - param.learning_rate * dW;  % Update weights
                        % end
                        % Backward pass: Update model parameters (gradient descent)
 
                        % cur_xy = xy_state * param.gui.cal.data.transform.beta;
                        % cur_xy = cur_state(1,[3,4]);
                        prev_xy = [param.gui.cal.h.feedback.XData,param.gui.cal.h.feedback.YData];
                        cur_xy = [mean(cur_emg(:,65)) - mean(cur_emg(:,67)), mean(cur_emg(:,66)) - mean(cur_emg(:,68))];
                        new_xy = 0.25*cur_xy + 0.75*prev_xy;
                        set(param.gui.cal.h.feedback,'XData',new_xy(1,1),'YData',new_xy(1,2));
                        % set(param.gui.cal.h.feedback,'XData',cur_xy(:,1),'YData',cur_xy(:,2));
                    elseif size(target_plot,1)>=5
                        cur_xy = target_plot(5,:);
                        set(param.gui.cal.h.feedback,'XData',cur_xy(1,1),'YData',cur_xy(1,2));
                    end
                end
            end

            % Handle updating the "SCH" (single-channel) GUI if required
            if param.gui.sch.enable && param.spike_detector
                if isvalid(param.gui.sch.fig)
                    iTag = find(ORDERED_TAG == param.gui.sch.saga,1);
                    if size(samples{iTag},2) > 3
                        sample_counts = samples{iTag}(config.SAGA.(param.gui.sch.saga).Channels.COUNT,:) + (iTag-1)*counter_offset;
                        i_assign = rem([sample_counts, sample_counts(end)+1]-1, param.gui.sch.n_samples)+1;
                        y = [hpf_data.(param.gui.sch.saga)(:,param.gui.sch.channel); nan];
                        param.gui.sch.h.data.YData(i_assign) = y;
                        i_ts = rem(sample_counts,param.gui.sch.n_samples) == round(param.gui.sch.n_samples/2);
                        if sum(i_ts) == 1
                            param.gui.sch.h.xline.Label = seconds_2_str(sample_counts(i_ts)/param.sample_rate);
                        end
                    end
                else
                    param.gui.sch.fig = [];
                    param.gui.sch.enable = false;
                    fprintf(1,'[TMSi]::[NEO] Gui was closed.\n');
                end
            end
            pause(param.pause_duration); % Allow the other callbacks to process.
            drawnow;
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
                                drawnow;
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
        delete(lib_lsl);
    end
    clear lsl_info_obj lsl_outlet_obj lib_lsl lsl_outlet_env lsl_info_env
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    close all force;
catch me
    % Stop both devices.
    stop(device);
    disconnect(device);
    writeline(udp_state_receiver, jsonencode(struct('type', 'status', 'value', 'stop')), config.UDP.Socket.RecordingControllerGUI.Address, config.UDP.Socket.RecordingControllerGUI.Port);
    warning(me.message);
    disp(me.stack);
    clear client udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    try %#ok<TRYNC>
        for ii = 1:numel(device)
            delete(lsl_info_obj.(device(ii).tag));
            delete(lsl_outlet_obj.(device(ii).tag));
        end
        delete(lsl_info_env);
        delete(lsl_outlet_env);
        delete(lib_lsl);
    end
    clear lsl_info_obj lsl_outlet_obj lib_lsl lsl_outlet_env lsl_info_env
    close all force;
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
