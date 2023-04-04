classdef TMSi_Node < handle
    %TMSI_NODE Class with simple UDP interface to TMSis

    properties (Access = public)
        % block - Recording block index
        %   Numeric value, typically 0-indexed.
        %   Set by sending UDP messages with syntax block.(value)
        block  (1,1) double;
        % channels - Struct with channels info
        channels (1,1) struct
        % folder - The location containing the saved output "subject" folder.
        %   Set by sending UDP messages using
        folder (1,1) string;
        % meta - Struct with miscellaneous metadata
        %   Set by sending UDP messages using 
        % mode - "Mode" for filtering associated with each SAGA
        %   Set by 
        mode (1,1) struct
        % trig - Trigger channel index
        trig (1,1) struct
        % sync - Sync bit
        sync (1,1) struct
        % subject - The subject being recorded
        %   E.g. "Spencer" or "Rupert"
        %   Set by sending UDP messages with syntax subject.(value)
        subject (1,1) string;
        % date - The date of the recording
        %   E.g. "2023_03_07"
        date (1,1) string;
        % ports - Ports where the output of UDP streams are directed 
        ports (1,1) struct
        % hosts - IP Address for hosts where UDP streams are directed
        hosts (1,1) string
        % needs_reload - Only for "virtual" device mode; indicates Playback should be reloaded with new data file.
        needs_reload (1,1) logical = false
    end

    properties (GetAccess = public, SetAccess = protected)
        % fname - The full filename expression to be used when saving files.
        %   
        %   This is auto-updated by `update_fname()`
        fname (1,1) string;
        % state - State of the recording
        %   See enumerated possibilities in TMSiState enumeration class.
        %   Set by sending UDP messages using
        state  (1,1) enum.TMSiState = enum.TMSiState.IDLE;
        % transition - Transition indicating state machine to-dos
        transition (1,1) enum.TMSiTransition = enum.TMSiTransition.NONE;
    end

    properties (Access = protected)
        controller_response_host_ (1,1) string  % UDP address to send response messages to for the controller interface
        controller_response_port_ (1,1) double  % UDP port to send response messages to for the controller interface
        tags_               (1,:) string    % Stores the tags for associated SAGA devices
        logger_             (1,1) mlog.Logger = mlog.Logger('TMSi'); % Handles logging
        controller_         (1,1)           % Handles incoming JSON messages about starting/stopping the streams or recordings/impedance mode.
        config_             (1,1)           % Handles inbound messages about channel configuration.
        streams_            (1,1) struct    % Handles high-data channel-data streams out to SAGA-A or SAGA-B ports
        buffer_             (1,1) struct    % Stores samples and implements circular buffer that emits an event when it fills
        rec_buffer_         (1,1) struct    % Larger-size sample buffer for data recordings
        buffer_listener_    (1,1) struct    % Listens to "FrameFilledEvent" from corresponding buffer_ and broadcasts data via UDP
        worker_                             % Single tcpserver
        verbosity_          (1,1) double = 0; % Debugger level
        device_             (1,1) string
        YYYY_ (1,1) double  % Year (from date)
        MM_ (1,1) double    % Month (from date)
        DD_ (1,1) double    % Day (from date)
    end

    methods
        function self = TMSi_Node(tags, ch, cfg, varargin)
            %TMSI_NODE Class with simple UDP interface to TMSis
            %
            % Syntax:
            %  obj = TMSi_Node(tags, ch, cfg);
            %  obj = TMSi_Node(tags, ch, cfg, 'Name', value, ...);
            %
            % Inputs:
            %   tags - String or char array of tags for SAGA devices
            %   ch   - Struct with fields that are elements of `tags`
            %               with information about channel indexing etc.
            %   cfg  - Yaml config struct (see parse_main_config).
            %   varargin - (Optional) 'Name',value pairs:
            %   See: pars struct at top of constructor.
            if nargin < 3
                cfg = parse_main_config();
            end
            p = inputParser();
            p.addRequired('tags', @(in)(isstring(in)||ischar(in)));
            p.addRequired('ch', @isstruct);
            p.addRequired('cfg', @isstruct);
            p.addParameter('block', 0, @(in)(isnumeric(in) && isscalar(in)));
            p.addParameter('folder', string(cfg.Default.Folder), @(in)(isstring(in)||ischar(in)));
            p.addParameter('device', "physical", @(in)ismember(string(in), ["physical", "virtual"]));
            p.addParameter('subject', cfg.Default.Subject, @(in)(isstring(in)||ischar(in)));
            p.addParameter('service_host', "0.0.0.0", @(in)(isstring(in)||ischar(in)));
            p.addParameter('service_port', cfg.UDP.tmsi.controller.service, ...
                @(in)(isnumeric(in) && isscalar(in)));
            p.addParameter('config_host', "0.0.0.0", @(in)(isstring(in)||ischar(in)));
            p.addParameter('config_port', cfg.UDP.tmsi.config, ...
                @(in)(isnumeric(in) && isscalar(in)));
            p.addParameter('streams_host', "0.0.0.0", @(in)(isstring(in)||ischar(in)));
            p.addParameter('streams_port', cfg.UDP.tmsi.streams, ...
                @(in)(isnumeric(in) && isscalar(in)));
            p.parse(tags, ch, cfg, varargin{:});
            
            % % Set metadata/file tracking parameters % %
            self.device_ = p.Results.device;
            self.verbosity_ = cfg.Verbosity.tmsi.service;
            self.block = p.Results.block;
            self.folder = p.Results.folder;
            self.subject = p.Results.subject;
            self.date = datetime('now','Format','uuuu_MM_dd');
            self.update_fname_(false); % Only time we set false is to explicitly indicate not to broadcast message (UDP isn't set up yet).

            % % Set up stream handling arguments % %
            self.tags_ = tags;
            self.hosts = cfg.Host.streams;
            for ii = 1:numel(tags)
                t = tags(ii);
                self.trig.(t) = cfg.SAGA.(t).Trigger.Channel;
                self.sync.(t) = cfg.SAGA.(t).Trigger.Bit;
                
                self.ports.(t) = cfg.TCP.tmsi.streams.(t);
                self.mode.(t) = enum.TMSiPacketMode.StreamMode; % Default to this packetmode
                self.channels.(t) = struct('index', [cfg.SAGA.(t).Channels.UNI, cfg.SAGA.(t).Channels.BIP], 'en', true(1,68), 'counter', cfg.SAGA.(t).Channels.COUNT, 'car', cfg.SAGA.(t).CAR, 'textiles', cfg.SAGA.(t).Textiles);
                self.buffer_.(t) = StreamBuffer(ch.(t), cfg.SAGA.(t).Channels.n.samples, t, cfg.Default.Sample_Rate);
                self.buffer_listener_.(t) = ...
                    addlistener(self.buffer_.(t), "FrameFilledEvent", ...
                    @self.handle_tcp_byte_streams);
                self.rec_buffer_.(t) = StreamBuffer(ch.(t), cfg.Default.Rec_Samples, t, cfg.Default.Sample_Rate);
                self.streams_.(t) = tcpserver("0.0.0.0", self.ports.(t), ...
                    "ConnectionChangedFcn", @self.send_name_data_to_client, ...
                    "Timeout", 0.5);
            end
            
            % % Create tcpserver for (optional) worker connection % %
            self.worker_ = tcpserver("0.0.0.0", cfg.TCP.tmsi.worker);
            self.worker_.configureCallback("terminator", @(src,~)disp(jsondecode(src.readline())));

            % % Create controller UDP port object % %
            self.controller_ = udpport(...
                "LocalHost", p.Results.service_host, ...
                "LocalPort", p.Results.service_port, ...
                "EnablePortSharing", true);
            self.controller_.configureMulticast(cfg.Host.multicast, true);
            self.controller_.configureCallback("terminator", ...
                @self.handle_serialized_tmsi_udp_controller_messages);
            if self.verbosity_ > 0
                fprintf(1,'[TMSiNode]::[Controller]\tOpened UDP TMSi service-controller-listener ( %s:%d )\n', ...
                    p.Results.service_host, p.Results.service_port);
            end
            self.controller_response_host_ = cfg.Host.interface;
            self.controller_response_port_ = cfg.UDP.tmsi.controller.interface;

            % % Create config UDP port object % %
            self.config_ = udpport( ...
                "LocalHost", p.Results.config_host, ...
                "LocalPort", p.Results.config_port, ...
                "EnablePortSharing", true );
            self.config_.configureMulticast(cfg.Host.multicast, true);
            self.config_.configureCallback("terminator", ...
                @self.handle_serialized_tmsi_udp_config_messages);
            if self.verbosity_ > 0
                fprintf(1,'[TMSiNode]::[Config]\t\tOpened UDP TMSi service-config-listener ( %s:%d )\n', ...
                    p.Results.config_host, p.Results.config_port);
            end
        end

        function append(self, tag, samples)
            %APPEND Append samples to the circular-buffer
            %
            % Syntax:
            %   node.append(tag, samples);
            %
            % Inputs:
            %   tag - "A" or "B"
            %   samples - Sample data matrix returned by `device.sample`
            self.buffer_.(tag).append(samples);

            % If we are recording, we should still put the data into the
            % recording buffer.
            if self.state == enum.TMSiState.RECORDING
                self.rec_buffer_.(tag).append(samples);
            end
        end

        function delete(self)
            %DELETE Overloads delete method to ensure proper destruction of udpport and tcpserver objects.
            try %#ok<TRYNC> 
                delete(self.controller_);
            end
            try %#ok<TRYNC>
                delete(self.config_);
            end
            try %#ok<TRYNC>
                delete(self.streams_);
            end
            try %#ok<TRYNC>
                for ii = 1:numel(self.tags_)
                    try %#ok<TRYNC>
                        delete(self.buffer_.(self.tags_(ii)));
                    end
                    try %#ok<TRYNC>
                        delete(self.buffer_listener_.(self.tags_(ii)));
                    end
                    try %#ok<TRYNC>
                        delete(self.worker_.(self.tags_(ii)));
                    end
                    try %#ok<TRYNC>
                        delete(self.rec_buffer_.(self.tags_(ii)));
                    end
                end
            end
        end

        function clear_transition(self)
            %CLEAR_TRANSITION  Clears the state transition.
            self.transition = enum.TMSiTransition.NONE;
        end

        function save_recording(self, tags)
            %SAVE_RECORDINGS  Save the contents of the recording buffer and reset it.
            %
            % Syntax:
            %   node.save_recording(tags);
            %
            % Inputs:
            %   tags - The tag of SAGA devices to save (e.g. ["A", "B"]).
            for ii = 1:numel(tags)
                [~, bk] = self.rec_buffer_.(tags(ii)).save(self.fname);
                if bk ~= self.block
                    self.block = bk;
                end
                self.rec_buffer_.(tags(ii)).reset_buffer();
            end
            if self.worker_.Connected
                data = msg.json_tmsi_udp_name_message(...
                    self.subject, self.YYYY_, self.MM_, self.DD_, self.block);
                self.worker_.writeline(jsonencode(data)); 
            end
            self.block = self.block + 1;
            self.update_fname_();
        end
    
        function set_name(self, SUBJ, YYYY, MM, DD, BLOCK)
            %SET_NAME  Set filename and update any listening UDP devices
            %
            % Syntax:
            %   node.set_name(SUBJ, YYYY, MM, DD, BLOCK);
            %
            % Inputs:
            %   SUBJ    - Subject name
            %   YYYY    - Numeric year
            %   MM      - Numeric month
            %   DD      - Numeric day
            %   BLOCK   - Numeric block index
            self.subject = SUBJ;
            self.block = BLOCK;
            self.date = datetime(YYYY, MM, DD, 'Format', 'uuuu_MM_dd');
            self.update_fname_();
        end

        function reset_buffers(self)
            %RESET_BUFFERS  Reset StreamBuffer buffers (standard and recording)
            tags = fieldnames(self.buffer_);
            for iTag = 1:numel(tags)
                self.buffer_.(tags{iTag}).reset_buffer();
                self.rec_buffer_.(tags{iTag}).reset_buffer();
            end
        end
    end

    methods (Access=public, Hidden)
        function handle_serialized_tmsi_udp_config_messages(self, src, evt)
            %HANDLE_SERIALIZED_TMSI_UDP_STREAMS_MESSAGES  Handles messages sent to the TCP stream server.
            message = readline(src);
            if self.verbosity_ > 0
                fprintf(1,'[TMSiNode]::[Config]::[%s]\tReceived UDP message [%s]\n', string(evt.AbsoluteTime), message);
            end
            data = jsondecode(message);
            val = data.value;
            switch data.parameter
                case "packet_mode"
                    self.mode.(data.tag) = enum.TMSiPacketMode(upper(val));
                    self.logger_.info(sprintf("%s :: mode=TMSiPacketMode('%s')", data.tag, upper(val)))
                case "sync"
                    self.sync.(data.tag) = val;
                    self.logger_.info(sprintf("%s :: sync=%s", data.tag, val.bit));
                case "trig"
                    self.trig.(tag) = val;
                    self.logger_.info(sprintf("%s :: trig=%s", data.tag, val.trig));
            end
        end

        function handle_serialized_tmsi_udp_controller_messages(self, src, evt)
            %HANDLE_SERIALIZED_TMSI_UDP_CONTROLLER_MESSAGES  Handles "set" messages sent to TMSi controller server.

            message = readline(src);
            if self.verbosity_ > 0
                fprintf(1,'[TMSiNode]::[Service]::[%s]\tReceived UDP message [%s]\n', string(evt.AbsoluteTime), message);
            end
            data = jsondecode(message);
            p = data.parameter;
            v = data.value;
            switch p
                case "get"
                    switch v
                        case "name"
                            self.update_fname_();
                        otherwise
                            self.logger_.error(sprintf("UDP :: unhandled=%s", message));
                            return;
                    end
                    if self.verbosity_ > 0
                        fprintf(1,'[TMSiNode]::[Service]::[%s] Sent UDP-GET response (get.%s)\n', string(evt.AbsoluteTime), v);
                    end
                case "name"
                    self.block = v.block;
                    self.subject = v.subject;
                    self.date = datetime(v.year,v.month,v.day,'Format','uuuu_MM_dd');
                    self.update_fname_(false);
                    if strcmpi(self.device_, "virtual")
                        self.needs_reload = true;
                    end
                    self.logger_.info(sprintf("UDP :: subject=%s", self.subject));
                    self.logger_.info(sprintf("UDP :: block=%d",   self.block));
                case "block"
                    self.block = v;
                    self.update_fname_(false);
                    if strcmpi(self.device_, "virtual")
                        self.needs_reload = true;
                    end
                    self.logger_.info(sprintf("UDP :: block=%d", v));
                case "folder"
                    self.folder = v;
                    self.update_fname_(false);
                    if strcmpi(self.device_, "virtual")
                        self.needs_reload = true;
                    end
                    self.logger_.info(sprintf("UDP :: folder=%s", v));
                case "date"
                    self.date = v;
                    self.update_fname_();
                    if strcmpi(self.device_, "virtual")
                        self.needs_reload = true;
                    end
                    self.logger_.info(sprintf("UDP :: date=%s", string(v)));
                case "state"
                    new_state = enum.TMSiState(upper(v));
                    prev_state = self.state;
                    self.state = new_state;
                    switch prev_state
                        case enum.TMSiState.IDLE
                            self.transition = enum.TMSiTransition.FROM_IDLE;
                        case enum.TMSiState.RUNNING
                            self.transition = enum.TMSiTransition.FROM_RUNNING;
                        case enum.TMSiState.RECORDING
                            self.transition = enum.TMSiTransition.FROM_RECORDING;
                        case enum.TMSiState.IMPEDANCE
                            self.transition = enum.TMSiTransition.FROM_IMPEDANCE;
                        otherwise
                            self.transition = enum.TMSiTransition.NONE;
                    end
                    self.logger_.info(sprintf("UDP :: state=TMSiState('%s')", upper(v)));
                case "subject"
                    self.subject = v;
                    self.update_fname_();
                    if strcmpi(self.device_, "virtual")
                        self.needs_reload = true;
                    end
                    self.logger_.info(sprintf("UDP :: subject=%s", v));
                otherwise
                    self.logger_.error(sprintf("UDP :: unhandled=%s", message));
                    return;
            end
        end
    
        function handle_udp_byte_streams(self, src, ~)
            %HANDLE_UDP_BYTE_STREAMS  Handle the byte streams that send actual data samples to the other applications.
            %
            % -- DEPRECATED -- (see: self.handle_tcp_byte_streams)
            %
            % Syntax:
            %   self.handle_udp_byte_streams(src)
            %
            % Inputs:
            %   src - This should be a Buffer of class `StreamBuffer`; the
            %           method is configured as a callback for
            %           "FrameFilledEvent" from this class.
            saga = src.tag;
            [~,sample_order] = sort(src.index ./ src.sample_rate, 'ascend');
            subset = self.channels.(saga).index(self.channels.(saga).en)';
            samples = src.samples(subset, sample_order);
            if self.channels.(saga).car
                if self.channels.(saga).textiles
                    vec = (subset >= 2) & (subset < 34); % 2:33 = textile 1
                    samples(vec,:) = samples(vec,:) - mean(samples(vec,:),1);
                    vec = (subset >= 34) & (subset < 66); % 34:65 = textile 2
                    samples(vec,:) = samples(vec,:) - mean(samples(vec,:),1);
                else
                    vec = (subset >= 2) & (subset < 66); % 2:65 = UNI-1
                    samples(vec,:) = samples(vec,:) - mean(samples(vec,:),1);
                end
            end
            trigs = src.samples(self.trig.(saga),sample_order);
            data = [detrend(samples')'; trigs];                             
%             self.streams_.write( [(data(:).*1000+1024)', newline], "uint16", self.hosts.(saga), self.ports.(saga)); 
            self.streams_.write( [(data(:))' + 1024.0, newline], "double", self.hosts, self.ports.(saga)); 
        end

        function handle_tcp_byte_streams(self, src, ~)
            %HANDLE_TCP_BYTE_STREAMS  Handles the TCP byte stream sending data samples to the other applications.
            %
            % Syntax:
            %   self.handle_tcp_byte_streams_(src)
            %
            % Inputs:
            %   src - This should be a Buffer of class `StreamBuffer`; the
            %           method is configured as a callback for
            %           "FrameFilledEvent" from this class.
            saga = src.tag;
            if ~self.streams_.(saga).Connected
                return;
            end
            [~,sample_order] = sort(src.index, 'ascend');
            subset = [self.channels.(saga).index(self.channels.(saga).en), self.trig.(saga), self.channels.(saga).counter];
            y = src.samples(subset, sample_order); 
            if self.channels.(saga).car
                if self.channels.(saga).textiles
                    vec = (subset >= 2) & (subset < 34); % 2:33 = textile 1
                    y(vec,:) = y(vec,:) - mean(y(vec,:),1);
                    vec = (subset >= 34) & (subset < 66); % 34:65 = textile 2
                    y(vec,:) = y(vec,:) - mean(y(vec,:),1);
                else
                    vec = (subset >= 2) & (subset < 66); % 2:65 = UNI-1
                    y(vec,:) = y(vec,:) - mean(y(vec,:),1);
                end
            end  
            y(1:(end-2),:) = detrend(y(1:(end-2),:)')';
            ch = uint8([(subset(1:(end-2))-1),100,101]); % Code for channels
            data = msg.json_tmsi_tcp_stream_message(ch, y(:), saga);
            message = jsonencode(data);
            self.streams_.(saga).writeline( message ); 
        end

        function send_name_data_to_client(self, src, ~)
            %SEND_NAME_DATA_TO_CLIENT  Callback for streams TCP server ConnectionChangedFcn
            if src.Connected
                data = msg.json_tmsi_udp_name_message(self.subject, self.YYYY_, self.MM_, self.DD_, '%s', self.block);
                message = jsonencode(data);
                src.writeline(message);
            end
        end
    end

    methods (Access=protected)
        function update_fname_(self, send_udp)
            %UPDATE_FNAME_  Update filename based on folder, subject, and block.
            if nargin < 2
                send_udp = true;
            end
            self.fname = string(strrep(fullfile(self.folder, self.subject, sprintf('%s_%s', self.subject, string(self.date)), sprintf('%s_%s_%%s_%d', self.subject, string(self.date), self.block)), "\", "/"));
            self.YYYY_ = year(self.date);
            self.MM_ = month(self.date);
            self.DD_ = day(self.date);
            if send_udp
                data = msg.json_tmsi_udp_name_message(self.subject, self.YYYY_, self.MM_, self.DD_, '%s', self.block);
                message = jsonencode(data);
                self.controller_.writeline(message, self.controller_response_host_, self.controller_response_port_);
            end
        end
    end
end