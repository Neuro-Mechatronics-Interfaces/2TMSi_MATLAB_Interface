%DEPLOY__TMSI_STREAM_SERVICE - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) server.
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
% IMPEDANCE_FIGURE_POSITION = [10 250 1250 950; ... % A - 125k
%     1250 250 1250 950];

% TODO: Add something that will increment a sub-block index so that it
% auto-saves if the buffer overflows, maybe using a flag on the buffer
% object to do this or subclassing to a new buffer class that is
% specifically meant for saving stream records.

config_file = parameters('config_stream_service_plus');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);
addpath('FastICA_25');
pause(1.5);
%% Setup device configurations.
config_device_impedance = struct('ImpedanceMode', true, ...
    'ReferenceMethod', 'common', ...
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
    'ReferenceMethod', 'common',...
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
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.state, ...
    "EnablePortSharing", true);
udp_name_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.name, ...
    "EnablePortSharing", true);
udp_param_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.params, ...
    "EnablePortSharing", false);
tcp_spike_server = tcpserver("0.0.0.0", ... % Allow any IP to connect
                             config.TCP.SpikeServer.Port);
tcp_rms_server = tcpserver("0.0.0.0", ...
                            config.TCP.RMSServer.Port);
tcp_muap_server = tcpserver("0.0.0.0", ...
                            config.TCP.MUAPServer.Port);
%% Initialize parameters and parameter sub-fields, figures
param = struct(...
    'n_channels', struct('A', [], 'B', []), ...
    ...'n_spike_channels', config.Default.N_Spike_Channels, ...
    'n_spike_channels', max(numel(config.GUI.Squiggles.A), numel(config.GUI.Squiggles.B)), ...
    'name_tag', struct('A', "A", 'B', "B"), ...
    'selected_spike_channels', struct('A', [4, 24, 55], 'B', [4, 24, 55]), ...
    'n_samples_recording', config.Default.N_Samples_Recording, ...
    'recording_samples_acquired', struct('A', 0, 'B', 0), ...
    'recording_chunk_offset', struct('A', 0, 'B', 0), ...
    'classifier', struct('A', [], 'B', []), ...
    'n_samples_calibration', config.Default.N_Samples_Calibration, ...
    'n_samples_label', config.Default.N_Samples_Label, ...
    'n_total', struct('A', numel(config_channels.A.uni) + numel(config_channels.A.bip), 'B', numel(config_channels.B.uni) + numel(config_channels.B.bip)), ...
    'sample_rate', config.Default.Sample_Rate, ...
    'spike_detector', config.Default.Spike_Detector, ...
    'car_mode', config.Default.CAR_Mode, ...
    'hpf', struct('b', [], 'a', []), ...
    'gui', struct('squiggles', struct('enable', config.GUI.Squiggles.Enable, 'fig', [], 'h', [], 'offset', config.GUI.Offset, ...
                                      'channels', struct('A', [], 'B', []), 'zi', struct('A', [], 'B', []), 'n_samples', config.GUI.N_Samples, 'color', config.GUI.Color, ...
                                      'acc', struct('enable', config.Accelerometer.Enable, 'differential', config.Accelerometer.Differential, 'saga', config.Accelerometer.SAGA), ...
                                      'triggers', struct('enable', config.Triggers.Enable), ...
                                      'tag', struct('A', "A", 'B', "B")), ...
                  'sch', struct('enable', config.GUI.Single.Enable, 'fig', [], 'h', [], ...
                                'saga', config.GUI.Single.SAGA, ...
                                'channel', config.GUI.Single.Channel,  ...
                                'n_samples', config.GUI.N_Samples, ...
                                'color', config.GUI.Color, ...
                                'state', config.Default.Calibration_State, ...
                                'tag', struct('A', "A", 'B', "B"))), ...
    'calibrate', struct('A', true, 'B', true), ...
    'calibration_state', config.Default.Calibration_State, ...
    'calibration_samples_acquired', struct('A', 0, 'B', 0),  ...
    'calibration_data', struct('A', struct(config.Default.Calibration_State, randn(config.Default.N_Samples_Calibration, numel(config_channels.A.uni)+numel(config_channels.A.bip))), ...
                               'B', struct(config.Default.Calibration_State, randn(config.Default.N_Samples_Calibration, numel(config_channels.B.uni)+numel(config_channels.B.bip)))), ...
    'hpf_max', struct('A', ones(1,numel(config_channels.A.uni)+numel(config_channels.A.bip)),'B', ones(1,numel(config_channels.B.uni)+numel(config_channels.B.bip))), ...
    'label', struct('A', false, 'B', false), ...
    'label_state', config.Default.Label_State, ...
    'labeled_samples_acquired', struct('A', 0, 'B', 0), ...
    'labeled_data', struct('A', struct(config.Default.Label_State, randn(numel(config_channels.A.uni), config.Default.N_Samples_Label)), ...
                           'B', struct(config.Default.Label_State, randn(numel(config_channels.B.uni), config.Default.N_Samples_Label))), ...
    'rate_smoothing_alpha', reshape(config.Default.Rate_Smoothing_Alpha,numel(config.Default.Rate_Smoothing_Alpha),1), ...
    'save_location', strrep(config.Default.Folder,'\','/'),  ...            % Save folder
    'save_params', config.Default.Save_Parameters, ...
    'pause_duration', config.Default.Sample_Loop_Pause_Duration, ...
    'past_rates', struct('A', zeros(numel(config.Default.Rate_Smoothing_Alpha),config.Default.N_Spike_Channels), 'B', zeros(numel(config.Default.Rate_Smoothing_Alpha),config.Default.N_Spike_Channels)), ...
    'transform', struct('A', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels)), ...
                        'B', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels))), ...
    'threshold', struct('A', struct(config.Default.Calibration_State, inf(1,numel(config_channels.A.uni)+numel(config_channels.A.bip))), ...
                        'B', struct(config.Default.Calibration_State, inf(1,numel(config_channels.A.uni)+numel(config_channels.A.bip)))), ...
    'threshold_deviations', config.Default.Threshold_Deviations, ...
    'threshold_artifact', config.Default.Artifact_Channel_Proportion_Threshold, ...
    'min_rms_artifact', config.Default.Minimum_RMS_Per_Channel, ...
    'exclude_by_rms', struct('A', false(1,numel(config.GUI.Squiggles.A)), 'B', false(1,numel(config.GUI.Squiggles.B))), ...
    'threshold_pose', config.Default.Pose_Threshold, ...
    'deadzone_pose', config.Default.Pose_Deadzone_Threshold, ...
    'use_channels', struct('A', [], 'B', []), ...
    'pose_smoothing_alpha', config.Default.Pose_Smoothing_Alpha);
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

ch = device.getActiveChannels();
if ~iscell(ch)
    ch = {ch};
end

param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
hpf_data = struct('A', [], 'B', []);
rms_data = struct('A',[],'B',[]);
rms_zi = struct('A',zeros(3,param.n_spike_channels),'B',zeros(3,param.n_spike_channels));
i_mono = struct('A', config.SAGA.A.Channels.UNI, 'B', config.SAGA.B.Channels.UNI);
i_bip = struct('A', config.SAGA.A.Channels.BIP, 'B', config.SAGA.B.Channels.BIP);
i_all = struct('A', union(i_mono.A, i_bip.A), 'B', union(i_mono.B, i_bip.B));
zi = struct('A',zeros(3,numel(i_all.A)), 'B', zeros(3,numel(i_all.B)));

%% Configuration complete, run main control loop.
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    samples = cell(N_CLIENT,1);
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
    
    start(device);
    pause(1.0);
    % needs_timestamp = struct;
    % first_timestamp = struct;
    counter_offset = 0;
    needs_offset = true;
    pose_vec = zeros(6,1);

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
            fprintf(1, "File name updated: %s\n", fname);
        end
        
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
                fprintf(1, "File name updated: %s\n", fname);
            end

            % Check for a parameter update.
            while udp_param_receiver.NumBytesAvailable > 0
                parameter_data = udp_param_receiver.readline();
                param = parse_parameter_message(parameter_data, param);
            end

            num_sets = zeros(numel(device),1);
            for ii = 1:N_CLIENT
                [samples{ii}, num_sets(ii)] = device(ii).sample();
                if num_sets(ii) > 0
                    [hpf_data.(device(ii).tag), zi.(device(ii).tag)] = filter(param.hpf.b,param.hpf.a,samples{ii}(i_all.(device(ii).tag),:)',zi.(device(ii).tag),1);
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
                            for ik = 1:num_sets(ii)
                                tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
                            end
                            hpf_data.(device(ii).tag)(:,1:64) = reshape(del2(tmp),64,num_sets(ii))';
                    end
                    if needs_offset && (ii > 1) && (num_sets(1) > 0)
                        counter_offset = samples{1}(config.SAGA.(device(1).tag).Channels.COUNT, end) - samples{ii}(config.SAGA.(device(ii).tag).Channels.COUNT, end);
                        needs_offset = false;
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
            end
            % Handle calibration (if required)
            for ii = 1:N_CLIENT
                if param.calibrate.(device(ii).tag) && (size(hpf_data.(device(ii).tag),1) > 0)
                    n_cal_samples = param.calibration_samples_acquired.(device(ii).tag) + size(hpf_data.(device(ii).tag),1);
                    if n_cal_samples >= param.n_samples_calibration
                        last_sample = size(hpf_data.(device(ii).tag),1) - (n_cal_samples - param.n_samples_calibration);
                        param.calibration_data.(device(ii).tag).(param.calibration_state)((param.calibration_samples_acquired.(device(ii).tag)+1):param.n_samples_calibration,:) = hpf_data.(device(ii).tag)(1:last_sample,:);
                        param.hpf_max.(device(ii).tag) = max(max(param.calibration_data.(device(ii).tag).(param.calibration_state),[],1),ones(1,param.n_spike_channels));
                        param.exclude_by_rms.(device(ii).tag) = rms(param.calibration_data.(device(ii).tag).(param.calibration_state),1) < param.min_rms_artifact;
                        [param.transform.(device(ii).tag).(param.calibration_state), score] = pca(param.calibration_data.(device(ii).tag).(param.calibration_state), 'NumComponents', param.n_spike_channels);
                        param.threshold.(device(ii).tag).(param.calibration_state) = median(abs(param.calibration_data.(device(ii).tag).(param.calibration_state)), 1) * param.threshold_deviations;
                        param.calibrate.(device(ii).tag) = false;
                        param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
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
                        if param.gui.squiggles.acc.enable
                            [max_pose, acc_pose_val] = max(pose_vec);
                            if max_pose < param.deadzone_pose
                                acc_pose = "Rest";
                            else
                                acc_pose = string(TMSiAccPose(acc_pose_val));
                            end
                            if ~isempty(param.gui.squiggles.fig)
                                if isvalid(param.gui.squiggles.fig)
                                    updatePose(param.gui.squiggles, acc_pose);
                                end
                            end
                        else
                            acc_pose = "Unknown";
                        end
                        n_samp = size(samples{ii},2);
                        if tcp_spike_server.Connected
                            spike_data = struct('SAGA', device(ii).tag, 'data', param.past_rates.(device(ii).tag), 'n', n_samp);
                            writeline(tcp_spike_server, jsonencode(spike_data));
                        end
                        if tcp_rms_server.Connected
                            [rms_data.(device(ii).tag), rms_zi.(device(ii).tag)] = filter(param.b_rms, param.a_rms, hpf_data.(device(ii).tag), rms_zi.(device(ii).tag),1);
                            rms_data = struct('SAGA', device(ii).tag, 'data', rms(rms_data.(device(ii).tag)./param.hpf_max.(device(ii).tag),1), 'n', n_samp);
                            writeline(tcp_rms_server, jsonencode(rms_data));
                        end
                        if tcp_muap_server.Connected
                            if ~isempty(param.classifier.(device(ii).tag))
                                if numel(param.classifier.(device(ii).tag).Channels) == param.classifier.(device(ii).tag).Net.input.size
                                    locs = cell(64,1);
                                    for ik = param.classifier.(device(ii).tag).Channels
                                        locs{ik} = find(abs(hpf_data.(device(ii).tag)(:,ik)) > param.classifier.(device(ii).tag).MinPeakHeight);
                                        if ~isempty(locs{ik})
                                            locs{ik} = locs{ik}([true; diff(locs{ik})>1]);
                                        end
                                    end
                                    all_locs = unique(vertcat(locs{:}));
                                    [~,clus] = max(param.classifier.(device(ii).tag).Net(hpf_data.(device(ii).tag)(all_locs,param.classifier.(device(ii).tag).Channels)'),[],1);
                                    for ik = 1:param.classifier.(device(ii).tag).Net.output.size
                                        param.classifier.(device(ii).tag).Out.Data(ik) = sum(clus == ik);
                                    end
                                    param.classifier.(device(ii).tag).Out.n = n_samp;
                                    writeline(tcp_muaps_server, jsonencode(param.classifier.(device(ii).tag).Out));
                                end
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
                                param.gui.squiggles.h.(device(ii).tag)(iCh).YData(i_assign.(device(ii).tag)) = [hpf_data.(device(ii).tag)(:,cur_ch)' + rem((cur_ch-1),8)*param.gui.squiggles.offset, nan];
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
                                param.gui.squiggles.h.Triggers.(device(ii).tag).YData(i_assign.(device(ii).tag)) = [samples{ii}(config.SAGA.(device(ii).tag).Trigger.Channel,:) + 32*(ii-1), nan];
                            end
                        end
                    end
                else
                    param.gui.squiggles.fig = [];
                    param.gui.squiggles.enable = false;
                    fprintf(1,'[TMSi]::[SQUIGGLES] Gui was closed.\n');
                end
            end

            % Handle updating the "NEO" (spikes) GUI if required
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
    close all force;
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
