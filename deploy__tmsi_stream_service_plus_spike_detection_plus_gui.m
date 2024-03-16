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
IMPEDANCE_FIGURE_POSITION = [ 280 160 1200 720; ... % A
                             2120 100 1200 720]; % B
% IMPEDANCE_FIGURE_POSITION = [-2249 60 1393 766; ... % A
%                               186 430 1482 787]; % B
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
% config_channels = struct('uni', 1:64, ...
%     'bip', 1:4, ...
%     'dig', 0, ...
%     'acc', 0, ...
%     'aux', 1:3);
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
    setDeviceTag(device, SN, TAG);
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
            setDeviceTag(device, SN, TAG);
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
        setDeviceTag(device, SN, TAG);
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

param = struct(...
    'n_channels', struct('A', [], 'B', []), ...
    'n_spike_channels', config.Default.N_Spike_Channels, ...
    'n_samples_calibration', config.Default.N_Samples_Calibration, ...
    'n_samples_label', config.Default.N_Samples_Label, ...
    'n_total', struct('A', numel(config_channels.A.uni), 'B', numel(config_channels.B.uni)), ...
    'sample_rate', config.Default.Sample_Rate, ...
    'spike_detector', config.Default.Spike_Detector, ...
    'apply_car', config.Default.Apply_CAR, ...
    'hpf', struct('b', [], 'a', []), ...
    'gui', struct('squiggles', struct('enable', config.GUI.Squiggles.Enable, 'fig', [], 'h', [], 'offset', config.GUI.Offset, 'channels', struct('A', [], 'B', []), 'zi', struct('A', [], 'B', []), 'n_samples', config.GUI.N_Samples, 'color', config.GUI.Color), ...
                  'neo', struct('enable', config.GUI.NEO.Enable, 'fig', [], 'h', [], 'saga', "A", 'channel', 1, 'n_samples', config.GUI.N_Samples, 'color', config.GUI.Color, 'state', config.Default.Calibration_State)), ...
    'calibrate', struct('A', true, 'B', true), ...
    'calibration_state', config.Default.Calibration_State, ...
    'calibration_samples_acquired', struct('A', 0, 'B', 0),  ...
    'calibration_data', struct('A', struct(config.Default.Calibration_State, randn(numel(config_channels.A.uni), config.Default.N_Samples_Calibration)), ...
                           'B', struct(config.Default.Calibration_State, randn(numel(config_channels.B.uni), config.Default.N_Samples_Calibration))), ...
    'label', struct('A', false, 'B', false), ...
    'label_state', config.Default.Label_State, ...
    'labeled_samples_acquired', struct('A', 0, 'B', 0), ...
    'labeled_data', struct('A', struct(config.Default.Label_State, randn(numel(config_channels.A.uni), config.Default.N_Samples_Label)), ...
                           'B', struct(config.Default.Label_State, randn(numel(config_channels.B.uni), config.Default.N_Samples_Label))), ...
    'save_location', strrep(config.Default.Folder,'\','/'),  ...            % Save folder
    'save_params', config.Default.Save_Parameters, ...
    'pause_duration', config.Default.Sample_Loop_Pause_Duration, ...
    'transform', struct('A', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels)), ...
                        'B', struct(config.Default.Calibration_State, init_n_channel_transform(config.Default.N_Spike_Channels))), ...
    'threshold', struct('A', struct(config.Default.Calibration_State, inf(1,config.Default.N_Spike_Channels)), ...
                        'B', struct(config.Default.Calibration_State, inf(1,config.Default.N_Spike_Channels))), ...
    'threshold_deviations', config.Default.Threshold_Deviations);
param.gui.squiggles.channels.A = config.GUI.Squiggles.A;
param.gui.squiggles.channels.B = config.GUI.Squiggles.B;
param.gui.squiggles.zi.A = zeros(numel(config.GUI.Squiggles.A),2);
param.gui.squiggles.zi.B = zeros(numel(config.GUI.Squiggles.B),2);
[param.hpf.b, param.hpf.a] = butter(2, config.Default.HPF_Cutoff_Frequency/(param.sample_rate/2), 'high');

ch = device.getActiveChannels();
if ~iscell(ch)
    ch = {ch};
end

param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
neodata = struct('A', [], 'B', []);
spike_rates = struct('A',[],'B',[]);

%% Configuration complete, run main control loop.
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    samples = cell(N_CLIENT,1);
    state = "idle";
    fname = strrep(fullfile(param.save_location, ...
                            config.Default.Subject, ...
                            sprintf("%s_%04d_%02d_%02d_%%s_0.mat", ...
                                    config.Default.Subject, ...
                                    year(today), month(today), day(today))), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    [tmpFolder, tmpFile, ~] = fileparts(fname);
    if exist(tmpFolder,'dir')==0
        mkdir(tmpFolder);
    end
    
    start(device);
    pause(1.0);
    needs_timestamp = struct;
    first_timestamp = struct;
    
    for ii = 1:N_CLIENT % Determine number of channels definitively
        [samples{ii}, num_sets] = device(ii).sample();
        while (num_sets < 1)
            fprintf(1,'[TMSi]::[INIT] Waiting for SAGA-%s to generate samples...\n', device(ii).tag);
            pause(0.5);
        end
        param.n_channels.(device(ii).tag) = size(samples{ii},1);
        needs_timestamp.(device(ii).tag) = false;
        first_timestamp.(device(ii).tag) = datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS', 'TimeZone', 'America/New_York');
    end
    stop(device);
    
    recording = false;
    running = false;
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
            [tmpFolder, tmpFile, ~] = fileparts(fname);
            if exist(tmpFolder,'dir')==0
                mkdir(tmpFolder);
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
                [tmpFolder, tmpFile, ~] = fileparts(fname);
                if exist(tmpFolder,'dir')==0
                    mkdir(tmpFolder);
                end
                fprintf(1, "File name updated: %s\n", fname);
            end

            % Check for a parameter update.
            while udp_param_receiver.NumBytesAvailable > 0
                parameter_data = udp_param_receiver.readline();
                param = parse_parameter_message(parameter_data, param);
            end

            for ii = 1:N_CLIENT
                [samples{ii}, num_sets] = device(ii).sample();
                if needs_timestamp.(device(ii).tag)
                    first_timestamp.(device(ii).tag) =  datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS', 'TimeZone', 'America/New_York') - seconds(size(samples{ii},2)/param.sample_rate);
                end
            end
            % Check for a "control state" update.
            if udp_state_receiver.NumBytesAvailable > 0
                state = readline(udp_state_receiver);
                if strcmpi(state, "rec")
                    if ~recording
                        fprintf(1, "[TMSi]::[RUN > REC]: Buffer created, recording in process...\n");
                        rec_file = struct;
                        for ii = 1:N_CLIENT
                            rec_file.(device(ii).tag) = matfile(strrep(fname, "%s", device(ii).tag), 'Writable', true);
                            rec_file.(device(ii).tag).samples = zeros(param.n_channels.(device(ii).tag),0); % Initialize the variable, with no samples in it.
                            rec_file.(device(ii).tag).channels = ch{ii}.toStruct();
                            rec_file.(device(ii).tag).sample_rate = param.sample_rate;
                            needs_timestamp.(device(ii).tag) = true;
                            if param.save_params
                                params = rmfield(param, "gui");
                                rec_file.(device(ii).tag).params = params;
                            else
                                rec_file.(device(ii).tag).params = [];
                            end
                            rec_file.(device(ii).tag).spikes = struct('SAGA', cell(0,1), 'rate', cell(0,1), 'n', cell(0,1));
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
                            delete(rec_file.(device(ii).tag));
                        end
                    end
                    recording = false;
                end
            end
            % If recording, log the samples in the recording buffer. 
            if recording
                for ii = 1:N_CLIENT
                    if ~isempty(samples{ii})
                        rec_file.(device(ii).tag).samples(:,(end+1):(end+size(samples{ii},2))) = samples{ii};
                        if needs_timestamp.(device(ii).tag)
                            rec_file.(device(ii).tag).time = first_timestamp.(device(ii).tag);
                            needs_timestamp.(device(ii).tag) = false;
                        end
                    end
                end
            end
            % Handle calibration (if required)
            for ii = 1:N_CLIENT
                if param.calibrate.(device(ii).tag) && (size(samples{ii},2) > 0)
                    n_cal_samples = param.calibration_samples_acquired.(device(ii).tag) + size(samples{ii},2);
                    if n_cal_samples >= param.n_samples_calibration
                        last_sample = size(samples{ii},2) - (n_cal_samples - param.n_samples_calibration);
                        param.calibration_data.(device(ii).tag).(param.calibration_state)(:,(param.calibration_samples_acquired.(device(ii).tag)+1):end) = samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,1:last_sample);
                        caldata = param.calibration_data.(device(ii).tag).(param.calibration_state)';
                        if param.apply_car
                            caldata = caldata - mean(caldata,2);
                        end
                        neocaldata = caldata(3:end,:).^2 - caldata(1:(end-2),:).^2; 
                        
                        [param.transform.(device(ii).tag).(param.calibration_state), score] = pca(neocaldata, 'NumComponents', param.n_spike_channels);
                        param.threshold.(device(ii).tag).(param.calibration_state) = median(abs(score), 1) * param.threshold_deviations;
                        param.calibrate.(device(ii).tag) = false;
                        param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
                        fprintf(1,'[TMSi]::[Calibration]::SAGA-%s "%s" calibration complete.\n', device(ii).tag, param.calibration_state);
                    else
                        param.calibration_data.(device(ii).tag).(param.calibration_state)(:,(param.calibration_samples_acquired.(device(ii).tag)+1):n_cal_samples) = samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,:);
                        param.calibration_samples_acquired.(device(ii).tag) = n_cal_samples;
                    end
                end
            end

            % Handle labeling (if required)
            for ii = 1:N_CLIENT
                if param.label.(device(ii).tag) && (size(samples{ii},2) > 0)
                    n_lab_samples = param.labeled_samples_acquired.(device(ii).tag) + size(samples{ii},2);
                    if n_lab_samples >= param.n_samples_calibration
                        last_sample = size(samples{ii},2) - (n_lab_samples - param.n_samples_label);
                        param.labeled_data.(device(ii).tag).(param.label_state)(:,(param.labeled_samples_acquired.(device(ii).tag)+1):end) = samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,1:last_sample);
                        param.label.(device(ii).tag) = false;
                        fprintf(1,'[TMSi]::[Labeling]::SAGA-%s "%s" label complete.\n', device(ii).tag, param.label_state);
                    else
                        param.labeled_data.(device(ii).tag).(param.label_state)(:,(param.labeled_samples_acquired.(device(ii).tag)+1):n_lab_samples) = samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,:);
                        param.labeled_samples_acquired.(device(ii).tag) = n_lab_samples;
                    end
                end
            end

            % Handle spike detection if required
            if param.spike_detector
                for ii = 1:N_CLIENT
                    if size(samples{ii},2) > 3
                        [spike_rates.(device(ii).tag), neodata.(device(ii).tag)] = detect_spikes(samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,:), ...
                            param.transform.(device(ii).tag).(param.calibration_state), ...
                            param.threshold.(device(ii).tag).(param.calibration_state), ...
                            param.apply_car, ...
                            param.sample_rate);
                        spike_data = struct('SAGA', device(ii).tag, 'rate', spike_rates.(device(ii).tag), 'n', size(samples{ii},2));
                        if tcp_spike_server.Connected
                            writeline(tcp_spike_server, jsonencode(spike_data));
                        end
                        if recording
                            rec_file.(device(ii).tag).spikes(end+1,1) = spike_data;
                        end
                    end
                end
            end

            % Handle updating the "Squiggles" GUI if required
            if param.gui.squiggles.enable
                if isvalid(param.gui.squiggles.fig)
                    tmp_offset = 0;
                    for ii = 1:N_CLIENT
                        if size(samples{ii},2) > 0
                            sample_counts = samples{ii}(config.SAGA.(device(ii).tag).Channels.COUNT,:);
                            i_assign = rem([sample_counts-1, sample_counts(end)], param.gui.squiggles.n_samples)+1;
                            for iCh = 1:numel(param.gui.squiggles.channels.(device(ii).tag))
                                if param.apply_car
                                    [ytmp, param.gui.squiggles.zi.(device(ii).tag)(iCh,:)] = filter(param.hpf.b, param.hpf.a, samples{ii}(param.gui.squiggles.channels.(device(ii).tag)(iCh),:) - mean(samples{ii}(config.SAGA.(device(ii).tag).Channels.UNI,:), 1), param.gui.squiggles.zi.(device(ii).tag)(iCh,:));
                                else
                                    [ytmp, param.gui.squiggles.zi.(device(ii).tag)(iCh,:)] = filter(param.hpf.b, param.hpf.a, samples{ii}(param.gui.squiggles.channels.(device(ii).tag)(iCh),:), param.gui.squiggles.zi.(device(ii).tag)(iCh,:));
                                end
                                param.gui.squiggles.h.(device(ii).tag)(iCh).YData(i_assign) = [ytmp + tmp_offset, nan];
                                tmp_offset = tmp_offset + param.gui.squiggles.offset;
                            end
                        else
                            sample_counts = [];
                        end
                    end
                    if ~isempty(sample_counts)
                        i_ts = rem(sample_counts,param.gui.squiggles.n_samples) == round(param.gui.squiggles.n_samples/2);
                        if sum(i_ts) == 1
                            param.gui.squiggles.h.xline.Label = seconds_2_str(sample_counts(i_ts)/param.sample_rate);
                        end
                    end
                else
                    param.gui.squiggles.fig = [];
                    param.gui.squiggles.enable = false;
                    fprintf(1,'[TMSi]::[SQUIGGLES] Gui was closed.\n');
                end
            end

            % Handle updating the "NEO" (spikes) GUI if required
            if param.gui.neo.enable && param.spike_detector
                if isvalid(param.gui.neo.fig)
                    iTag = TAG == param.gui.neo.saga;
                    if size(samples{iTag},2) > 3
                        sample_counts = samples{iTag}(config.SAGA.(param.gui.neo.saga).Channels.COUNT,2:end);
                        i_assign = rem(sample_counts-1, param.gui.neo.n_samples)+1;
                        y = [neodata.(param.gui.neo.saga)(:,param.gui.neo.channel); nan];
                        param.gui.neo.h.data.YData(i_assign) = y;
                        i_ts = rem(sample_counts,param.gui.neo.n_samples) == round(param.gui.neo.n_samples/2);
                        if sum(i_ts) == 1
                            param.gui.neo.h.xline.Label = seconds_2_str(sample_counts(i_ts)/param.sample_rate);
                        end
                    end
                else
                    param.gui.neo.fig = [];
                    param.gui.neo.enable = false;
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
            else
                fprintf("[TMSi]::[STATE] Tried to assign incorrect state (%s) -- check sender port.\n", tmpState);
            end
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "[TMSi]::[IDLE > REC]: Buffer created, recording in process...\n");
                    rec_file = struct;
                    for ii = 1:N_CLIENT
                        rec_file.(device(ii).tag) = matfile(strrep(fname, "%s", device(ii).tag), 'Writable', true);
                        rec_file.(device(ii).tag).samples = zeros(param.n_channels.(device(ii).tag),0); % Initialize the variable, with no samples in it.
                        rec_file.(device(ii).tag).channels = ch{ii}.toStruct();
                        rec_file.(device(ii).tag).sample_rate = param.sample_rate;
                        needs_timestamp.(device(ii).tag) = true;
                        if param.save_params
                            params = rmfield(param, "gui");
                            rec_file.(device(ii).tag).params = params;
                        else
                            rec_file.(device(ii).tag).params = [];
                        end
                        rec_file.(device(ii).tag).spikes = struct('SAGA', cell(0,1), 'rate', cell(0,1), 'n', cell(0,1));
                    end
                end
                recording = true;
                if ~running
                    start(device);
                    running = true;
                end
            elseif strcmpi(state, "run")
                if ~running
                    start(device);
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
                        state = readline(udp_state_receiver);
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
            end
        end
    end
    stop(device);
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
    warning(me.message);
    disp(me.stack);
    clear client udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    close all force;
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
