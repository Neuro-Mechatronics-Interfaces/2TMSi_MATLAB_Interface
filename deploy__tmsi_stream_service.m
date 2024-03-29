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
% SERVER_ADDRESS = "127.0.0.1";        % Host machine for TMSiSAGA ("Stream Server"; most-likely "localhost")
% WORKER_ADDRESS = "127.0.0.1";        % Can be Max desktop ("128.2.244.29") or Backyard Brains ("172.26.32.199")
% UDP_STATE_BROADCAST_PORT = 3030;    % UDP port: state
% UDP_NAME_BROADCAST_PORT = 3031;     % UDP port: name
% UDP_EXTRA_BROADCAST_PORT = 3032;    % UDP port: extra
% UDP_TASK_BROADCAST_PORT  = 3033;    % UDP port: task
% UDP_DATA_BROADCAST_PORT  = 3034;    % UDP port: data
% UDP_CONTROLLER_RECV_PORT = 3035;    % UDP port: receiver (controller)
% SERVER_PORT_CONTROLLER = 5000;          % Server port for CONTROLLER
% SERVER_PORT_DATA = struct;
% SERVER_PORT_DATA.A    = 5020;           % Server port for DATA from SAGA-A
% SERVER_PORT_DATA.B    = 5021;           % Server port for DATA from SAGA-B
% SERVER_PORT_WORKER = struct;
% SERVER_PORT_WORKER.A = 4000;
% SERVER_PORT_WORKER.B = 4001;
% USE_PARAM_SERVER = false;
% USE_WORKER = true; % Set to true if the worker will actually be deployed (MUST BE DEPLOYED BEFORE RUNNING THIS SCRIPT IF SET TO TRUE).
% N_SAMPLES_LOOP_BUFFER = 16384;
% IMPEDANCE_FIGURE_POSITION = [-2249 60 1393 766; ... % A
%                               186 430 1482 787]; % B
IMPEDANCE_FIGURE_POSITION = [1100 1100 650 400; ... % A (DELL TMSI CART)
                             1100 575  650 400];    % B (DELL TMSI CART)
% Set this to LONGER than you think your recording should be, otherwise it
% will loop back on itself! %
N_SAMPLES_RECORD_MAX = 4000 * 60 * 10; % (sample rate) * (seconds/min) * (max. desired minutes to record)
% 5/8/22 - On NHP-Dell-C01 takes memory from 55% to 70% to pre-allocate 2
% cell arrays of randn for 72 channels each with enough samples for
% 10-minutes (to get an idea of scaling). 
%   -> General rule of thumb: better to pre-allocate big array of random
%       noise, then "gain" memory by indexed assignment into it, than to
%       run out of memory while running the loop.
% TODO: Add something that will increment a sub-block index so that it
% auto-saves if the buffer overflows, maybe using a flag on the buffer
% object to do this or subclassing to a new buffer class that is
% specifically meant for saving stream records.

% SN = [1005210029; 1005210028]; % NHP-B; NHP-A | docking stations / bottom
% TAG = ["B"; "A"];

% SN = [1000210036; 1000210037]; % NHP-B; NHP-A | data recorders / bottom
% TAG = ["B"; "A"];

% SN = [1005210038]; % SAGA-3 (wean | docking station / bottom half)
% TAG = "S3"; 

% SN = [1000210046]; % SAGA-3 (wean | data recorder / top half)
% TAG = "S3";

% SN = [1005220030; 1005220009]; % SAGA-4; SAGA-5 (wean | docking stations / bottom half)
% TAG = ["S4"; "S5"];

% SN = [1000220037; 1000220035];
% TAG = ["A"; "B"]; % Arbitrary  - "A" is SAGA-4 and "B" is SAGA-5

fprintf(1, "Loading configuration file (config.yaml, in main repo folder)...\n");
[config, TAG, SN, N_CLIENT] = parse_main_config(parameters('config'));
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
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);
config_channels = struct('uni', 1:64, ...
                         'bip', 1:4, ...
                         'dig', 0, ...
                         'acc', 0);
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
catch e
    % In case of an error close all still active devices and clean up
    lib.cleanUp();  
        
    % Rethrow error to ensure you get a message in console
    rethrow(e)
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.
    setDeviceTag(device, SN, TAG);
    info = getDeviceInfo(device);
    enableChannels(device, horzcat({device.channels}));
    updateDeviceConfig(device);   
    device.setChannelConfig(config_channels);
    device.setDeviceConfig(config_device); 
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
% "mode" codes (see tab 'Tag' properties in SAGA_Data_Visualizer app):
%   "US" - Unipolar Stream
%   "BS" - Bipolar Stream
%   "UA" - Unipolar Average
%   "BA" - Bipolar Average
%   "UR" - Unipolar Raster
%   "IR" - ICA Raster
%   "RC" - RMS Contour
packet_mode = struct('A','US','B','US');


visualizer = cell(1, N_CLIENT);
for ii = 1:N_CLIENT
    visualizer{ii} = tcpclient(config.Server.Address.TCP, config.Server.TCP.(device(ii).tag).Viewer);
end
visualizer = vertcat(visualizer{:});
if config.Default.Use_Worker_Server
    worker = tcpclient(config.Server.Address.Worker, config.Server.TCP.Worker);
else
    worker = [];
end


ch = device.getActiveChannels();
% fsm = SAGA_State_Machine(config, ch, TAG);

buffer = cell(1, N_CLIENT); 
for ii = 1:N_CLIENT
    buffer{ii} = StreamBuffer(ch{ii}, ...
        channels.(device(ii).tag).n.samples, ...
        device(ii).tag, ...
        device(ii).sample_rate);
end
buffer = vertcat(buffer{:});

buffer_event_listener = struct;
for ii = 1:N_CLIENT
    itag = device(ii).tag;
    buffer_event_listener.(itag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer(ii), (channels.(itag).UNI(1:4))'));
end

%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    
    state = "idle";
    fname = strrep(fullfile(config.Default.Folder,config.Default.Subject,sprintf("%s_%%s_%%d.mat", config.Default.Subject)), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    recording = false;
    running = false;
    fprintf(1, "\n\t\t->\t[%s] SAGA LOOP BEGIN\t\t<-\n\n",string(datetime('now')));

    while ~strcmpi(state, "quit")
%         fname = fsm.check_for_name_update();
%         fsm.check_for_parameter_update();
        
        if udp_name_receiver.NumBytesAvailable > 0
            tmp = udp_name_receiver.readline();
            if startsWith(strrep(tmp, "\", "/"), config.Default.Folder)
                fname = tmp;
            else
                fname = strrep(fullfile(config.Default.Folder, tmp), "\", "/"); 
            end
            fprintf(1, "File name updated: %s\n", fname);
        end        
        if config.Default.Use_Param_Server
            if udp_extra_receiver.NumBytesAvailable > 0 %#ok<*UNRCH>
                tmp = udp_extra_receiver.readline();
                info = strsplit(tmp, '.');
                packet_tag = info{2};
                if strcmpi(packet_tag, 'A') || strcmpi(packet_tag, 'B')
                    fprintf(1, "Detected switch in packet mode from '%s' to --> '%s' <--\n", packet_mode, tmp);
                    packet_mode = info{1};
                    
                    delete(buffer_event_listener.(packet_tag)); 
                    switch packet_mode.(packet_tag)
                        case 'US'
                            i_subset = channels.(packet_tag).UNI(double(info{3}) - 96)';
                            fprintf(1, 'Enabled CH-%02d (UNI)\n', i_subset);
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer(ii), i_subset));
                            end
                            fprintf(1, "\t->\tConfigured %s for unipolar stream data.\n", packet_tag);
                        case 'BS'
                            i_subset = channels.(packet_tag).BIP(double(info{3}) - 96)';
                            fprintf(1, 'Enabled CH-%02d (BIP)\n', i_subset);
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(info{2}) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer(ii), i_subset));
                            end
                            fprintf(1, "\t->\tConfigured %s for bipolar stream data.\n", packet_tag);
                        case 'UA'
                            i_subset = channels.(packet_tag).UNI(double(info{3}) - 96)';
                            fprintf(1, 'Sending triggered-averages for %s:CH-%02d (UNI)\n', packet_tag, i_subset(1));
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(info{2}) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer(ii), i_subset));
                            end
                            fprintf(1, "\t->\tConfigured %s for unipolar averaging data.\n", packet_tag);
                        case 'BA'
                            i_subset = channels.(packet_tag).BIP(double(info{3}) - 96)';
                            fprintf(1, 'Sending triggered-averages for %s:CH-%02d (BIP)\n', packet_tag, i_subset(1));
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer(ii), i_subset));
                            end
                            fprintf(1, "Configured %s for bipolar averaging data.\n", packet_tag);
                        case 'UR'
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer(ii)));
                            end
                            fprintf(1, "\t->\tConfigured %s for unipolar raster data.\n", packet_tag);
                        case 'IR'
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer(ii)));
                            end
                            fprintf(1, "\t->\tConfigured %s for ICA raster data.\n", packet_tag);
                        case 'IS'
                            i_subset = (double(info{3}) - 96)';
                            fprintf(1, 'Sending triggered-averages for %s:ICA-%02d\n', packet_tag, i_subset(1));
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag)  = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IS(src, evt, visualizer(ii), i_subset));
                            end
                            fprintf(1, "\t->\tConfigured %s for bipolar averaging data.\n", packet_tag);
                        case 'RC'
                            for ii = 1:N_CLIENT
                                buffer_event_listener.(packet_tag) = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer(ii)));
                            end
                            fprintf(1, "\t->\tConfigured %s for RMS contour data.\n", packet_tag);
                        otherwise
                            fprintf(1,"\t->\tUnrecognized requested packet mode: %s", packet_mode);
                    end      
                end  
            end
        end
        
        while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit")) && (~strcmpi(state, "imp"))
            [samples, num_sets] = device.sample();
            buffer.append(samples);
            if udp_state_receiver.NumBytesAvailable > 0
                state = readline(udp_state_receiver);
                if strcmpi(state, "rec")
                    if ~recording
                        fprintf(1, "[RUN > REC]: Buffer created, recording in process...");
                        rec_buffer = cell(1, N_CLIENT); 
                        for ii = 1:N_CLIENT
                            rec_buffer{ii} = StreamBuffer(ch{ii}, config.Default.Rec_Samples, device(ii).tag, device(ii).sample_rate);
                        end
                        rec_buffer = vertcat(rec_buffer{:});
                    end
                    recording = true;
                    running = true;
                else
                    running = strcmpi(state, "run");
                    if ~running                        
                        stop(device);
                    end
                    if recording
                        fprintf(1, "complete\n\t->\t(%s)\n", fname);
                        rec_buffer.save(fname);
                        delete(rec_buffer);
                        clear rec_buffer;
                        if config.Default.Use_Worker_Server
                            [~, finfo, ~] = fileparts(fname);
                            args = strsplit(finfo, "_");
                            worker.writeline(...
                                string(sprintf('%s.%d.%d.%d.%s', ...
                                    args{1}, ...
                                    str2double(args{2}), ...
                                    str2double(args{3}), ...
                                    str2double(args{4}), ...
                                    args{5}, ...
                                    args{6}))); 
                        end
                    end
                    recording = false; 
                end
            end          
            if recording
                rec_buffer.append(samples);
            end            
        end
        if udp_state_receiver.NumBytesAvailable > 0
            state = readline(udp_state_receiver);
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "[IDLE > REC]: Buffer created, recording in process...");
                    rec_buffer = cell(1, N_CLIENT); 
                    for ii = 1:N_CLIENT
                        rec_buffer{ii} = StreamBuffer(ch{ii}, config.Default.Rec_Samples, device(ii).tag, device(ii).sample_rate);
                    end
                    rec_buffer = vertcat(rec_buffer{:});
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
                    device(ii).setDeviceConfig( config_device_impedance );
                    device(ii).setChannelConfig( config_channel_impedance );
                    start(device(ii));
                    channel_names = getName(getActiveChannels(device(ii)));
                    fig(ii) = uifigure(...
                        'Name', sprintf('Impedance Plot: SAGA-%s', device(ii).tag), ...
                        'Color', 'w', ...
                        'Icon', 'Impedance-Symbol.png', ...
                        'HandleVisibility', 'on', ...
                        'Position', IMPEDANCE_FIGURE_POSITION(ii,:));
                    iPlot{ii} = TMSiSAGA.ImpedancePlot(fig(ii), config_channel_impedance.uni, channel_names);
                end
                
                while any(isvalid(fig)) || ~strcmpi(state, "imp")
                    if udp_state_receiver.NumBytesAvailable > 0
                        state = readline(udp_state_receiver);
                    end
                    for ii = 1:numel(device)
                        if isvalid(fig(ii))
                            [samples, num_sets] = device(ii).sample();
                            % Append samples to the plot and redraw
                            if num_sets > 0
                                s{ii} = samples ./ 10^6; % need to divide by 10^6
                                iPlot{ii}.grid_layout(s{ii});
                                drawnow;
                            end  
                        end
                    end
                end
                
                for ii = 1:numel(device)
                    device(ii).stop();
                    enableChannels(device(ii), device(ii).channels);
                    updateDeviceConfig(device(ii)); 
                    device(ii).setDeviceConfig(config_device);
                    device(ii).setChannelConfig(config_channels);
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
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    
catch me
    % Stop both devices.
    stop(device);
    disconnect(device);
    warning(me.message);
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver udp_extra_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
