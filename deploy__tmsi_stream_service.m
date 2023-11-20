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
% IMPEDANCE_FIGURE_POSITION = [-2249 60 1393 766; ... % A
%                               186 430 1482 787]; % B
IMPEDANCE_FIGURE_POSITION = [10 250 1250 950; ... % A - 125k
                             1250 250 1250 950];

% TODO: Add something that will increment a sub-block index so that it
% auto-saves if the buffer overflows, maybe using a flag on the buffer
% object to do this or subclassing to a new buffer class that is
% specifically meant for saving stream records.

config_file = parameters('config');
fprintf(1, "[TMSi]::Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);
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
config_channels = struct('uni', 1:64, ...
                         'bip', 0, ...
                         'dig', 0, ...
                         'acc', 0, ...
						 'aux', 1:3);
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
    end
    configStandardMode(device, config_channels, config_device);
    for ii = 1:numel(device)
        fprintf(1,'\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
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
udp_state_receiver = udpport("byte", "LocalHost", config.Server.Address.UDP, "LocalPort", config.Server.UDP.state, "EnablePortSharing", true);
udp_name_receiver = udpport("byte", "LocalHost", config.Server.Address.UDP, "LocalPort", config.Server.UDP.name, "EnablePortSharing", true);
if config.Default.Use_Param_Server
    udp_extra_receiver = udpport("byte","LocalHost",config.Server.Address.UDP, "LocalPort", config.Server.UDP.extra, "EnablePortSharing", true);
end
udp_param_receiver = udpport("byte", "LocalHost", config.Server.Address.UDP, "LocalPort", config.Server.UDP.params, "EnablePortSharing", false);
param = struct('n', config.Default.Rec_Samples, 'f', strrep(config.Default.Folder,'\','/'));

% "mode" codes (see tab 'Tag' properties in SAGA_Data_Visualizer app):
%   "US" - Unipolar Stream
%   "BS" - Bipolar Stream
%   "UA" - Unipolar Average
%   "BA" - Bipolar Average
%   "UR" - Unipolar Raster
%   "IR" - ICA Raster
%   "RC" - RMS Contour
packet_mode = struct('A','US','B','US');

if config.Default.Use_Visualizer
	visualizer = struct;
	for ii = 1:N_CLIENT
		visualizer.(device(ii).tag) = tcpclient(config.Server.Address.TCP, config.Server.TCP.(device(ii).tag).Viewer);
	end
else
	visualizer = [];
end
worker = struct('A', [], 'B', []);
if config.Default.Use_Worker_Server
    for ii = 1:N_CLIENT
        worker.(device(ii).tag) = tcpclient(config.Server.Address.Worker, config.Server.TCP.(device(ii).tag).Worker);
    end
end

ch = device.getActiveChannels();
if ~iscell(ch)
    ch = {ch};
end
buffer = struct;
for ii = 1:N_CLIENT
    buffer.(device(ii).tag) = StreamBuffer(ch{ii}, ...
        channels.(device(ii).tag).n.samples, ...
        device(ii).tag, ...
        device(ii).sample_rate);
end

if config.Default.Use_Visualizer
	buffer_event_listener = struct;
	for ii = 1:N_CLIENT
		tag = device(ii).tag;
		buffer_event_listener.(tag) = addlistener(buffer.(tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer.(tag), (channels.(tag).UNI(1:4))', true));
	end
end
%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    samples = cell(N_CLIENT,1);
    state = "idle";
    fname = strrep(fullfile(param.f,config.Default.Subject,sprintf("%s_%%s_%%d.mat", config.Default.Subject)), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    recording = false;
    running = false;
    fprintf(1, "\n\t\t->\t[%s] SAGA LOOP BEGIN\t\t<-\n\n",string(datetime('now')));

    while ~strcmpi(state, "quit") 
        while udp_name_receiver.NumBytesAvailable > 0
            tmp = udp_name_receiver.readline();
            if startsWith(strrep(tmp, "\", "/"), param.f)
                fname = tmp;
            else
                fname = strrep(fullfile(param.f, tmp), "\", "/"); 
            end
            fprintf(1, "File name updated: %s\n", fname);
        end 
        pause(0.010);       
        if config.Default.Use_Param_Server && config.Default.Use_Visualizer
            while udp_extra_receiver.NumBytesAvailable > 0 %#ok<*UNRCH>
                tmp = udp_extra_receiver.readline();
                info = strsplit(tmp, '.');
                packet_tag = info{2};
                if strcmpi(packet_tag, 'A') || strcmpi(packet_tag, 'B')
                    fprintf(1, "[TMSi]\t->\tDetected (%s) switch in packet mode from '%s' to --> '%s' <--\n", packet_tag, packet_mode.(packet_tag), tmp);
                    reset_buffer(buffer.(packet_tag));
                    packet_mode.(packet_tag) = info{1};
                    delete(buffer_event_listener.(packet_tag)); 
                    switch packet_mode.(packet_tag)
                        case 'US'
                            apply_car = str2double(info{3});
                            i_subset = (double(info{4}) - 96)';
                            fprintf(1, '[TMSi]\tEnabled CH-%02d (UNI)\n', i_subset);
                            buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer.(packet_tag), i_subset, apply_car));
                            fprintf(1, "[TMSi]\t->\tConfigured %s for unipolar stream data.\n", packet_tag);
                        case 'BS'
                            i_subset = (double(info{3}) - 96)';
                            fprintf(1, '[TMSi]\tEnabled CH-%02d (BIP)\n', i_subset);
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer.(packet_tag), i_subset));
                            end
                            fprintf(1, "[TMSi]\t->\tConfigured %s for bipolar stream data.\n", packet_tag);
                        case 'UA'
                            apply_car = str2double(info{3});
%                             i_subset = str2double(info{4});
                            i_subset = (double(info{4}) - 96)';
                            i_trig = config.SAGA.(packet_tag).Trigger.Channel;
                            fprintf(1, '[TMSi]\tSending triggered-averages for %s:CH-%02d (UNI)\n', packet_tag, i_subset);
%                             buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                            buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                            fprintf(1, "[TMSi]\t->\tConfigured %s for unipolar averaging data.\n", packet_tag);
                        case 'BA'
%                             i_subset = str2double(info{3});
                            apply_car = str2double(info{3});
                            i_subset = (double(info{4}) - 96)';
                            i_trig = config.SAGA.(packet_tag).Trigger.Channel;
                            fprintf(1, '[TMSi]\tSending triggered-averages for %s:CH-%02d (BIP)\n', packet_tag, i_subset);
%                             buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer.(packet_tag), i_subset, i_trig));
                            buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                            fprintf(1, "[TMSi]\tConfigured %s for bipolar averaging data.\n", packet_tag);
                        case 'UR'
                            buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "ThresholdEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer.(packet_tag)));
                            fprintf(1, "\t->\tConfigured %s for unipolar raster data.\n", packet_tag);
                        case 'IR'
                            %TODO: load ICA filter configuration here.
                            buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "ThresholdEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer.(packet_tag)));
                            fprintf(1, "\t->\tConfigured %s for ICA raster data.\n", packet_tag);
                        case 'IS'
                            %TODO: load ICA filter configuration here.
                            i_subset = (double(info{3}) - 96)';
                            fprintf(1, '[TMSi]\tSending triggered-averages for %s:ICA-%02d\n', packet_tag, i_subset(1));
                            buffer_event_listener.(packet_tag)  = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IS(src, evt, visualizer.(packet_tag), i_subset));
                            fprintf(1, "[TMSi]\t->\tConfigured %s for bipolar averaging data.\n", packet_tag);
                        case 'RC'
                            buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer.(packet_tag)));
                            fprintf(1, "[TMSi]\t->\tConfigured %s for RMS contour data.\n", packet_tag);
                        otherwise
                            fprintf(1, "[TMSi]\t->\tUnrecognized requested packet mode: %s", packet_mode);
                    end 
                end
            end
        end
        while udp_param_receiver.NumBytesAvailable > 0
            tmp = udp_param_receiver.readline();
            fprintf(1,'[TMSi]\t->\tParameter: %s\n',tmp);
            tmp_split = strsplit(tmp, '.');
            switch tmp_split{1}
                case 'n'
                    param.n = str2double(tmp_split{2});
                case 'f'
                    param.f = strrep(tmp_split{2}, '\', '/');
                otherwise
                    param.(lower(tmp_split{1})) = tmp_split{2};
            end
        end


        
        while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit")) && (~strcmpi(state, "imp"))
            while udp_name_receiver.NumBytesAvailable > 0
                tmp = udp_name_receiver.readline();
                if startsWith(strrep(tmp, "\", "/"), param.f)
                    fname = tmp;
                else
                    fname = strrep(fullfile(param.f, tmp), "\", "/"); 
                end
                fprintf(1, "File name updated: %s\n", fname);
            end 
            while udp_param_receiver.NumBytesAvailable > 0
                tmp = udp_param_receiver.readline();
                fprintf(1,'[TMSi]\t->\tParameter: %s\n',tmp);
                tmp_split = strsplit(tmp, '.');
                switch tmp_split{1}
                    case 'n'
                        param.n = str2double(tmp_split{2});
                    case 'f'
                        param.f = strrep(tmp_split{2}, '\', '/');
                    otherwise
                        param.(lower(tmp_split{1})) = tmp_split{2};
                end
            end
            pause(0.010);
            for ii = 1:N_CLIENT
                [samples{ii}, num_sets] = device(ii).sample();
                buffer.(device(ii).tag).append(samples{ii});
                if udp_name_receiver.NumBytesAvailable > 0
                    tmp = udp_name_receiver.readline();
                    if startsWith(strrep(tmp, "\", "/"), param.f)
                        fname = tmp;
                    else
                        fname = strrep(fullfile(param.f, tmp), "\", "/"); 
                    end
                    fprintf(1, "[TMSi]\t->\tFile name updated: %s\n", fname);
                end
            end
            if udp_state_receiver.NumBytesAvailable > 0
                state = readline(udp_state_receiver);
                if strcmpi(state, "rec")
                    if ~recording
                        fprintf(1, "[TMSi]::[RUN > REC]: Buffer created, recording in process...\n");
                        rec_buffer = struct;
                        for ii = 1:N_CLIENT
                            rec_buffer.(device(ii).tag) = StreamBuffer(ch{ii}, param.n, device(ii).tag, device(ii).sample_rate);
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
                            rec_buffer.(device(ii).tag).save(fname);
                            delete(rec_buffer.(device(ii).tag));
                        end
                        if config.Default.Use_Worker_Server
                            [~, finfo, ~] = fileparts(fname);
                            args = strsplit(finfo, "_");
                            for ii = 1:N_CLIENT
                                worker.(device(ii).tag).writeline(...
                                    string(sprintf('%s.%d.%d.%d.%s', ...
                                        args{1}, ...
                                        str2double(args{2}), ...
                                        str2double(args{3}), ...
                                        str2double(args{4}), ...
                                        args{5}, ...
                                        args{6}))); 
                            end
                        end
                    end
                    recording = false; 
                end
            end          
            if recording
                for ii = 1:N_CLIENT
                    rec_buffer.(device(ii).tag).append(samples{ii});
                end
            end            
        end
        while udp_state_receiver.NumBytesAvailable > 0
            state = readline(udp_state_receiver);
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "[TMSi]::[IDLE > REC]: Buffer created, recording in process...\n");
                    rec_buffer = struct;
                    for ii = 1:N_CLIENT
                        rec_buffer.(device(ii).tag) = StreamBuffer(ch{ii}, param.n, device(ii).tag, device(ii).sample_rate);
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
                        end
                    end
                end
                
                for ii = 1:numel(device)
                    device(ii).stop();
                    enableChannels(device(ii), device(ii).channels);
                    configStandardMode(device(ii), config_channels, config_device);
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
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    
catch me
    % Stop both devices.
    stop(device);
    disconnect(device);
    warning(me.message);
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver udp_param_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
