function deploy__tmsi_playback(SUBJ,YYYY,MM,DD,BLOCK)
%DEPLOY__TMSI_PLAYBACK - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) to playback a specified block on a loop.
% See details in README.MD

config_file = parameters('config');
fprintf(1, "[PLAYBACK]\tLoading configuration file (%s, in main repo folder)...\n", config_file);
[config, TAG, ~, N_CLIENT] = parse_main_config(config_file);
pause(1.5);
%% Setup device configurations.
channels = struct('A', config.SAGA.A.Channels, ...
                  'B', config.SAGA.B.Channels);


%% Open "device connections"

f = utils.get_block_name(SUBJ, YYYY, MM, DD, "A", BLOCK, config.Default.Folder);
aname = string(strcat(f.Raw.Block, ".mat"));
f = utils.get_block_name(SUBJ, YYYY, MM, DD, "B", BLOCK, config.Default.Folder);
bname = string(strcat(f.Raw.Block, ".mat"));
playback_device = TMSiSAGA.Playback([aname; bname]);
connect(playback_device);


%% Create TMSi stream client + udpport
udp_state_receiver = udpport("byte", "LocalHost", config.Server.Address.UDP, "LocalPort", config.Server.UDP.state, "EnablePortSharing", true);
udp_name_receiver = udpport("byte", "LocalHost", config.Server.Address.UDP, "LocalPort", config.Server.UDP.name, "EnablePortSharing", true);
if config.Default.Use_Param_Server
    udp_extra_receiver = udpport("byte","LocalHost",config.Server.Address.UDP, "LocalPort", config.Server.UDP.extra, "EnablePortSharing", false);
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


visualizer = struct;
for ii = 1:N_CLIENT
    visualizer.(TAG{ii}) = tcpclient(config.Server.Address.TCP, config.Server.TCP.(playback_device(ii).tag).Viewer);
end

if config.Default.Use_Worker_Server
    worker = tcpclient(config.Server.Address.Worker, config.Server.TCP.Worker);
else
    worker = [];
end


ch = playback_device.getActiveChannels();
% fsm = SAGA_State_Machine(config, ch, TAG);

buffer = struct;
for ii = 1:N_CLIENT
    buffer.(TAG{ii}) = StreamBuffer(ch{ii}, ...
        channels.(playback_device(ii).tag).n.samples, ...
        playback_device(ii).tag, ...
        playback_device(ii).sample_rate);
end

buffer_event_listener = struct;
for ii = 1:N_CLIENT
    tag = playback_device(ii).tag;
    buffer_event_listener.(tag) = addlistener(buffer.(tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer.(tag), (channels.(tag).UNI(1:4))', true));
end

%%
 
state = "idle";
tank = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
fname = strrep(fullfile(config.Default.Folder,SUBJ,tank,sprintf("%s_%%s_%%d.mat", config.Default.Subject)), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
recording = false;
running = false;
udp_sender = udpport("byte", "LocalHost", config.Server.Address.UDP);
udp_sender.writeline(sprintf('set.block.%d', BLOCK), config.Server.Address.UDP, config.Server.UDP.recv);
udp_sender.writeline(sprintf('set.tank.%s', tank), config.Server.Address.UDP, config.Server.UDP.recv);

fprintf(1, "\n[PLAYBACK]\t\t->\t[%s] SAGA LOOP BEGIN\t\t<-\n\n",string(datetime('now')));

while ~strcmpi(state, "quit")
    while udp_name_receiver.NumBytesAvailable > 0
        tmp = udp_name_receiver.readline();
        if startsWith(strrep(tmp, "\", "/"), config.Default.Folder)
            fname = tmp;
        else
            fname = strrep(fullfile(config.Default.Folder, tmp), "\", "/"); 
        end
        playback_device.load_new(fname);
        fprintf(1, "[PLAYBACK]\tSuccessfully loaded new playback file(s): %s\n", fname);
    end        
    if config.Default.Use_Param_Server
        while udp_extra_receiver.NumBytesAvailable > 0 %#ok<*UNRCH>
            tmp = udp_extra_receiver.readline();
            info = strsplit(tmp, '.');
            packet_tag = info{2};
            if strcmpi(packet_tag, 'A') || strcmpi(packet_tag, 'B')
                fprintf(1, "[PLAYBACK]\tDetected (%s) switch in packet mode from '%s' to --> '%s' <--\n", packet_tag, packet_mode.(packet_tag), tmp);
                reset_buffer(buffer.(packet_tag));
                packet_mode.(packet_tag) = info{1};
                delete(buffer_event_listener.(packet_tag)); 
                switch packet_mode.(packet_tag)
                    case 'US'
                        apply_car = str2double(info{3});
                        i_subset = (double(info{4}) - 96)';
                        fprintf(1, 'Enabled CH-%02d (UNI)\n', i_subset);
                        buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer.(packet_tag), i_subset, apply_car));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for unipolar stream data.\n", packet_tag);
                    case 'BS'
                        i_subset = (double(info{3}) - 96)';
                        fprintf(1, 'Enabled CH-%02d (BIP)\n', i_subset);
                        for ii = 1:N_CLIENT
                            buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer.(packet_tag), i_subset));
                        end
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for bipolar stream data.\n", packet_tag);
                    case 'UA'
                        apply_car = str2double(info{3});
%                             i_subset = str2double(info{4});
                        i_subset = (double(info{4}) - 96)';
                        i_trig = config.SAGA.(packet_tag).Trigger.Channel;
                        fprintf(1, 'Sending triggered-averages for %s:CH-%02d (UNI)\n', packet_tag, i_subset);
%                             buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                        buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for unipolar averaging data.\n", packet_tag);
                    case 'BA'
%                             i_subset = str2double(info{3});
                        apply_car = str2double(info{3});
                        i_subset = (double(info{4}) - 96)';
                        i_trig = config.SAGA.(packet_tag).Trigger.Channel;
                        fprintf(1, '[PLAYBACK]\tSending triggered-averages for %s:CH-%02d (BIP)\n', packet_tag, i_subset);
%                             buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer.(packet_tag), i_subset, i_trig));
                        buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
                        fprintf(1, "[PLAYBACK]\tConfigured %s for bipolar averaging data.\n", packet_tag);
                        
                    case 'UR'
                        buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer.(packet_tag)));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for unipolar raster data.\n", packet_tag);
                    case 'IR'
                        buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer.(packet_tag)));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for ICA raster data.\n", packet_tag);
                    case 'IS'
                        i_subset = (double(info{3}) - 96)';
                        fprintf(1, '[PLAYBACK]\tSending triggered-averages for %s:ICA-%02d\n', packet_tag, i_subset(1));
                        buffer_event_listener.(packet_tag)  = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IS(src, evt, visualizer.(packet_tag), i_subset));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for bipolar averaging data.\n", packet_tag);
                    case 'RC'
                        buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer.(packet_tag)));
                        fprintf(1, "[PLAYBACK]\t->\tConfigured %s for RMS contour data.\n", packet_tag);
                    otherwise
                        fprintf(1,"[PLAYBACK]\t->\tUnrecognized requested packet mode: %s", packet_mode);
                end 
            end
        end
    end
    
    while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit")) && (~strcmpi(state, "imp"))
        samples = playback_device.sample();
        for ii = 1:N_CLIENT
            buffer.(TAG{ii}).append(samples{ii});
        end
        while udp_state_receiver.NumBytesAvailable > 0
            prev_state = state;
            state = readline(udp_state_receiver);
            fprintf(1,'[PLAYBACK]\t[UDP STATE]::[INNER BLOCKING LOOP]::"%s" -> "%s"\n', prev_state, state);
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "[PLAYBACK]\t[RUN > REC]: Buffer created, recording in process...");
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
                    stop(playback_device);
                end
                if recording
                    fprintf(1, "complete\n\t->\t(%s)\n", fname);
                    rec_buffer.save(fname);
                    delete(rec_buffer);
                    clear rec_buffer;
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
        if recording
            rec_buffer.append(samples);
        end            
    end
    while udp_state_receiver.NumBytesAvailable > 0
        prev_state = state;
        state = readline(udp_state_receiver);
        fprintf(1,'[PLAYBACK]\t[UDP STATE]::[OUTER BLOCKING LOOP]::"%s" -> "%s"\n', prev_state, state);
        if strcmpi(state, "rec")
            if ~recording
                fprintf(1, "[PLAYBACK]\t[IDLE > REC]: Buffer created, recording in process...");
                rec_buffer = cell(1, N_CLIENT); 
                for ii = 1:N_CLIENT
                    rec_buffer{ii} = StreamBuffer(ch{ii}, config.Default.Rec_Samples, device(ii).tag, device(ii).sample_rate);
                end
                rec_buffer = vertcat(rec_buffer{:});
            end
            recording = true;
            if ~running
                start(playback_device);
                running = true;
            end
        elseif strcmpi(state, "run")
            if ~running
                start(playback_device);
                running = true;
            end
        end
    end
end
stop(playback_device);
disconnect(playback_device);
try
    delete(udp_state_receiver);
    fprintf(1,'[PLAYBACK]\tDeleted udp state receiver port.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting udp state receiver port.\n');
end
try
    delete(udp_name_receiver);
    fprintf(1,'[PLAYBACK]\tDeleted udp name receiver port.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting udp name receiver port.\n');
end
try
    delete(udp_extra_receiver);
    fprintf(1,'[PLAYBACK]\tDeleted udp extra (mode) receiver port.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting extra (mode) receiver port.\n');
end
try
    delete(udp_sender);
    fprintf(1,'[PLAYBACK]\tDeleted udp sender port.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting udp sender port.\n');
end
try
    delete(playback_device);
    fprintf(1,'[PLAYBACK]\tDeleted playback device object.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting playback device object.\n');
end
try
    delete(visualizer);
    fprintf(1,'[PLAYBACK]\tDeleted TCP data online visualizer client.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting TCP data online visualizer client.\n');
end
try
    delete(worker);
    fprintf(1,'[PLAYBACK]\tDeleted TCP remote worker client.\n');
catch
    fprintf(1,'[PLAYBACK]\tError deleting TCP remote worker client.\n');
end

end
