function deploy__tmsi_playback_service(SUBJ,YYYY,MM,DD,BLOCK)
%DEPLOY__TMSI_PLAYBACK_SERVICE - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) to playback a specified block on a loop.
% See details in README.MD


%% SET PARAMETERS
IMPEDANCE_FIGURE_POSITION = [1100 1100 650 400; ... % A (DELL TMSI CART)
                             1100 575  650 400];    % B (DELL TMSI CART)

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
% lib = TMSiSAGA.Library();
% try
%     % Code within the try-catch to ensure that all devices are stopped and 
%     % closed properly in case of a failure.
%     device = lib.getDevices('usb', config.Default.Interface, 2, 2);  
%     connect(device); 
% catch e
%     % In case of an error close all still active devices and clean up
%     lib.cleanUp();  
%         
%     % Rethrow error to ensure you get a message in console
%     rethrow(e)
% end
% 
% %% Retrieve data about the devices.
% try % Separate try loop because now we must be sure to disconnect device.
%     setDeviceTag(device, SN, TAG);
%     info = getDeviceInfo(device);
%     enableChannels(device, horzcat({device.channels}));
%     updateDeviceConfig(device);   
%     device.setChannelConfig(config_channels);
%     device.setDeviceConfig(config_device); 
% catch e
%     disconnect(device);
%     lib.cleanUp();
%     rethrow(e);
% end

f = utils.get_block_name(SUBJ, YYYY, MM, DD, "A", BLOCK, config.Default.Folder);
aname = string(strcat(f.Raw.Block, ".mat"));
f = utils.get_block_name(SUBJ, YYYY, MM, DD, "B", BLOCK, config.Default.Folder);
bname = string(strcat(f.Raw.Block, ".mat"));
device = TMSiSAGA.Playback([aname; bname]);
connect(device);


%% Create TMSi stream client + udpport
udp_state_receiver = udpport("byte", "LocalPort", config.Server.UDP.state, "EnablePortSharing", true);
udp_name_receiver = udpport("byte", "LocalPort", config.Server.UDP.name, "EnablePortSharing", true);
if config.Default.Use_Param_Server
    udp_mode_receiver = udpport("byte", "LocalPort", config.Server.UDP.extra, "EnablePortSharing", true);
end
% "mode" codes (see tab 'Tag' properties in SAGA_Data_Visualizer app):
%   "US" - Unipolar Stream
%   "BS" - Bipolar Stream
%   "UA" - Unipolar Average
%   "BA" - Bipolar Average
%   "UR" - Unipolar Raster
%   "IR" - ICA Raster
%   "RC" - RMS Contour
packet_mode = 'US';


visualizer = cell(1, N_CLIENT);
for ii = 1:N_CLIENT
    visualizer{ii} = tcpclient(config.Server.Address.TCP, config.Server.TCP.(device(ii).tag).Viewer);
end
visualizer = vertcat(visualizer{:});
if config.Default.Use_Worker_Server
    worker = cell(1, N_CLIENT);
    for ii = 1:N_CLIENT
        worker{ii} = tcpclient(config.Server.Address.Worker, config.Server.TCP.(device(ii).tag).Worker);
    end
    worker = vertcat(worker{:});
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

buffer_event_listener = cell(1, N_CLIENT);
for ii = 1:N_CLIENT
    buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer(ii), (1:64)'));
end
buffer_event_listener = vertcat(buffer_event_listener{:});  

%%
 
state = "idle";
fname = strrep(fullfile(config.Default.Folder,config.Default.Subject,sprintf("%s_%%s_%%d.mat", config.Default.Subject)), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
recording = false;
running = false;
fprintf(1, "\n%s::SAGA LOOP BEGIN\n\n",string(datetime('now')));

while ~strcmpi(state, "quit")
    if udp_name_receiver.NumBytesAvailable > 0
        tmp = udp_name_receiver.readline();
        if startsWith(strrep(tmp, "\", "/"), config.Default.Folder)
            fname = tmp;
        else
            fname = strrep(fullfile(config.Default.Folder, tmp), "\", "/"); 
        end
        fprintf(1, "File name updated: <strong>%s</strong>\n", fname);
    end        
    if config.Default.Use_Param_Server
        if udp_mode_receiver.NumBytesAvailable > 0 %#ok<*UNRCH>
            tmp = udp_mode_receiver.readline();
            info = strsplit(tmp, '.');
            if ~strcmpi(info{1}, packet_mode)
                fprintf(1, "Detected switch in packet mode from '%s' to --> '%s' <--\n", packet_mode, tmp);
                packet_mode = info{1};
                for ii = 1:N_CLIENT
                    delete(buffer_event_listener(ii)); 
                end
                buffer_event_listener = cell(1, N_CLIENT);
                switch packet_mode
                    case 'US'
                        i_subset = double(info{2}) - 96;
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer(ii), i_subset));
                        end
                        fprintf(1, "Configured for unipolar stream data.\n");
                    case 'BS'
                        i_subset = double(info{2}) - 96;
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer(ii), i_subset));
                        end
                        fprintf(1, "Configured for bipolar stream data.\n");
                    case 'UA'
                        i_subset = double(info{2}) - 96;
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer(ii), i_subset));
                        end
                        fprintf(1, "Configured for unipolar averaging data.\n");
                    case 'BA'
                        i_subset = double(info{2}) - 96;
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer(ii), i_subset));
                        end
                        fprintf(1, "Configured for bipolar averaging data.\n");
                    case 'UR'
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer(ii)));
                        end
                        fprintf(1, "Configured for unipolar raster data.\n");
                    case 'IR'
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer(ii)));
                        end
                        fprintf(1, "Configured for ICA raster data.\n");
                    case 'IS'
                        i_subset = double(info{2}) - 96;
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IS(src, evt, visualizer(ii), i_subset));
                        end
                        fprintf(1, "Configured for bipolar averaging data.\n");
                    case 'RC'
                        for ii = 1:N_CLIENT
                            buffer_event_listener{ii} = addlistener(buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer(ii)));
                        end
                        fprintf(1, "Configured for RMS contour data.\n");
                    otherwise
                        fprintf(1,"Unrecognized requested packet mode: %s", packet_mode);
                end
                buffer_event_listener = vertcat(buffer_event_listener{:});        
                
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
                    fprintf(1, "[RUN > REC]: Buffer created, fake recording in process...");
%                     rec_buffer = cell(1, N_CLIENT); 
%                     for ii = 1:N_CLIENT
%                         rec_buffer{ii} = StreamBuffer(ch{ii}, config.Default.Rec_Samples, device(ii).tag, device(ii).sample_rate);
%                     end
%                     rec_buffer = vertcat(rec_buffer{:});
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
%                     rec_buffer.save(fname);
%                     delete(rec_buffer);
%                     clear rec_buffer;
                    if config.Default.Use_Worker_Server
                        [~, finfo, ~] = fileparts(fname);
                        args = strsplit(finfo, "_");
                        for iWorker = 1:numel(worker)
                            worker(iWorker).writeline(...
                                string(sprintf('%s.%d.%d.%d.%s', ...
                                    args{1}, ...
                                    str2double(args{2}), ...
                                    str2double(args{3}), ...
                                    str2double(args{4}), ...
                                    args{6}))); 
                        end
                    end
                end
                recording = false; 
            end
        end          
%         if recording
%             rec_buffer.append(samples);
%         end            
    end
    if udp_state_receiver.NumBytesAvailable > 0
        state = readline(udp_state_receiver);
        if strcmpi(state, "rec")
            if ~recording
                fprintf(1, "[IDLE > REC]: Buffer created, fake recording in process...");
%                 rec_buffer = cell(1, N_CLIENT); 
%                 for ii = 1:N_CLIENT
%                     rec_buffer{ii} = StreamBuffer(ch{ii}, config.Default.Rec_Samples, device(ii).tag, device(ii).sample_rate);
%                 end
%                 rec_buffer = vertcat(rec_buffer{:});
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
%         % If we are in impedance mode, change device config and show
%         % impedances for each device, sequentially.
%         if strcmpi(state, "imp")
%             iPlot = cell(size(device));
%             s = cell(size(device));
%             fig = gobjects(1, numel(device));
%             for ii = 1:numel(device)
%                 device(ii).setDeviceConfig( config_device_impedance );
%                 device(ii).setChannelConfig( config_channel_impedance );
%                 start(device(ii));
%                 channel_names = getName(getActiveChannels(device(ii)));
%                 fig(ii) = uifigure(...
%                     'Name', sprintf('Impedance Plot: SAGA-%s', device(ii).tag), ...
%                     'Color', 'w', ...
%                     'Icon', 'Impedance-Symbol.png', ...
%                     'HandleVisibility', 'on', ...
%                     'Position', IMPEDANCE_FIGURE_POSITION(ii,:));
%                 iPlot{ii} = TMSiSAGA.ImpedancePlot(fig(ii), config_channel_impedance.uni, channel_names);
%             end
%             
%             while any(isvalid(fig)) || ~strcmpi(state, "imp")
%                 if udp_state_receiver.NumBytesAvailable > 0
%                     state = readline(udp_state_receiver);
%                 end
%                 for ii = 1:numel(device)
%                     if isvalid(fig(ii))
%                         [samples, num_sets] = device(ii).sample();
%                         % Append samples to the plot and redraw
%                         if num_sets > 0
%                             s{ii} = samples ./ 10^6; % need to divide by 10^6
%                             iPlot{ii}.grid_layout(s{ii});
%                             drawnow;
%                         end  
%                     end
%                 end
%             end
%             
%             for ii = 1:numel(device)
%                 device(ii).stop();
%                 enableChannels(device(ii), device(ii).channels);
%                 updateDeviceConfig(device(ii)); 
%                 device(ii).setDeviceConfig(config_device);
%                 device(ii).setChannelConfig(config_channels);
%                 impedance_saver_helper(fname, device(ii).tag, s{ii});
%             end
%             if strcmpi(state, "imp")
%                 state = "idle";
%             end
%         end
    end
end
stop(device);
disconnect(device);
clear device client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver udp_mode_receiver
end
