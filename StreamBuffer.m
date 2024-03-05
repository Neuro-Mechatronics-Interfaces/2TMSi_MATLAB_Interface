classdef StreamBuffer < matlab.net.http.io.ContentProvider
    %STREAMBUFFER  Implements a buffer for streamed data.
    
    properties (Access = public)
        samples   double             % Data samples, each row is a channel arranged from UNI_01 to UNI_64
    end
    
    properties (GetAccess = public, SetAccess = protected)
        tag         string ="A"        % "A" or "B"
        saga_2_tag  string = "B"
        channels                       % Cell array of channels
        counter     double = 0         % Total number of samples (rolling)
        index       double             % The integer index that increments by 1 for each sample, denoting ordering of samples (columns)
        n           struct             % Struct describing size of data samples array.
        start       double = 1         % Starting index (rolling).
        sample_rate double = 4000      % Data in buffer was sampled at this rate (Hz)
        wrapping    double
    end
    
    properties (Access = protected)
        init        (1,1) logical = false    % This sets to true once successfully initialized.
        stop        (1,1) logical = false    % This is returned by `getData` second argument.
        mode  (1,1) StreamBufferMode = StreamBufferMode.FRAME; % This determines what 'Event' is issued when appending samples to the buffer.
        settings (1,1) struct          % Contains settings that depend on the event mode.
        udp
        has_ports   (1,1) logical = false;
        ports (1,1) struct
        hosts (1,1) struct
        has_callback (1,1) struct = struct('frame',false,'threshold',false)
        frame_callback_port = [];
        frame_callback_host = [];
        frame_handler_mode = [];
        frame_warning_flag = false;
        bipolar_channels = 66:69;
        threshold_callback_port = [];
    end
    
    events
        FrameFilledEvent    % Issued any time that a data frame is filled.
        ThresholdEvent      % Issued when a threshold is crossed.
    end
    
    methods
        function self = StreamBuffer(channels, nSamples, array, sample_rate)
            %STREAMBUFFER  Implements a buffer for streamed data.
            %
            % Syntax:
            %   self = StreamBuffer(channels, nSamples, port, array);
            %
            % Inputs:
            %   nChannels - Number of channels (optional; default = 64)
            %   nSamples  - Number of samples (optional; default = 32768)
            %   array     - Port number (optional; default = "A")
            %   sample_rate - Sampling rate, Hz (optional; default = 4000)
            %
            % Output:
            %   self - StreamBuffer selfect
            %
            % See also: Contents, StreamBuffer
            switch nargin
                case 0
                    error("Must pass `channels` argument at least.");
                case 1
                    self.n = struct('channels', numel(channels), 'samples', 16384, 'limit', 16384);
                case 2
                    self.n = struct('channels', numel(channels), 'samples', nSamples, 'limit', nSamples);
                case 3
                    self.n = struct('channels', numel(channels), 'samples', nSamples, 'limit', nSamples);
                    self.tag = string(array);
                case 4
                    self.n = struct('channels', numel(channels), 'samples', nSamples, 'limit', nSamples);
                    self.tag = string(array);
                    self.sample_rate = sample_rate;
                otherwise
                    error("[StreamBuffer::Constructor]\tInvalid number of input arguments (%d).", nargin);
            end
            self.channels = channels;
            self.samples = zeros(self.n.channels, self.n.samples);
            self.index = 1:self.n.samples;
            self.wrapping = 1:self.n.samples;
            self.init = true;
            self.udp = udpport();
        end

        function delete(self)
            delete(self.udp);
        end
        
        function append(self, value)
            %APPEND  Append new samples to the data
            %
            % Syntax:
            %   self.append(value);
            %
            % Inputs:
            %   value - If self is an array, then value should be a cell
            %           array with dimensions the size of `self`. Each cell
            %           array element should be a sample data array with
            %           dimensions self.n.channels x k, for k sampledata
            %           sets (samples from all channels for k samples).
            %
            % See also: Contents
            if iscell(value)
                for ii = 1:numel(value)
                    self(ii).append(value{ii});
                end
                return;
            end
            ns = min(size(value, 2), self.n.samples);
            self.index(self.wrapping(1:ns)) = self.start : (self.start + ns - 1);
            self.samples(:, self.wrapping(1:ns)) = value(:, 1:ns);
            self.wrapping = circshift(self.wrapping, -ns);
            self.start = self.start + ns;
            self.counter = self.counter + ns;
            
            % If we filled up, then send data samples.
            if self.counter >= self.n.limit
                self.counter = 0;
                notify(self, "FrameFilledEvent");  
                if self.has_callback.frame
                    self.handle_frame_filled_event();
                end
            end
            
            % If we "overflowed" then do this again until we have nothing
            % left to append.
            if ns < size(value, 2)
                self.append(value(:, (ns+1):end));
            end
        end
        
        function data = consume(self, nSamples)
            %CONSUME  Move the sample index by nSamples and return data.
            %
            % Syntax:
            %   data = self.consume(nSamples);
            %
            % Inputs:
            %   nSamples - The number of samples to consume (scalar).
            %
            % Output:
            %   data - self.n.channels x nSamples data array from
            %           self.samples.
            %
            % See also: Contents, StreamBuffer, StreamBuffer.getData

            lb = self.start - nSamples + 1;
            
            % If we requested to consume before we have even sampled enough
            % to build the indexing vector, just return zeros.
            if lb < 1
                data = zeros(self.n.channels, nSamples);
                return;
            end
            
            iMask = self.index >= lb;
            iData = self.index(iMask);
            [~, idx] = sort(iData, 'ascend');
            data = self.samples(:, iMask);
            data = data(:, idx);
            self.reset_buffer();
        end
        
        function [data, stop] = getData(self, ~)
            %GETDATA  Return n samples of data
            %
            % Syntax:
            %   [data, stop] = self.getData(nSamples);
            %
            % Inputs:
            %   nSamples - Return this many columns of data.
            %
            % Output:
            %   data - Data array with self.n.channels x nSamples.
            %
            %       Note: nSamples is ignored currently, so this will
            %       always be an array of self.n.channels x self.n.samples.
            %   
            %   stop - Always returns false unless, self.stop_sampling() has
            %           been called.
            %
            % See also: Contents, StreamBuffer, 
            %           StreamBuffer.stop_sampling, StreamBuffer.consume           
%             data = self.consume(nSamples);
            data = self.samples;
            stop = self.stop;
        end
        
        function merge(self, self2)
            %MERGE  Copy relevant values from a different data buffer
            %
            % Syntax:
            %   self.merge(self2);
            %
            % Inputs:
            %   self2 - Second StreamBuffer selfect to merge values with.
            %
            % See also: Contents, StreamBuffer
            
            self.index = self2.index;
            self.samples = self2.samples;
            self.wrapping = self2.wrapping;
            self.start = self2.start;
            self.counter = self2.counter;
        end
        
        function reset_buffer(self)
            %RESET_BUFFER  Resets the buffer and related properties
            %
            % Syntax:
            %   self.reset_buffer();
            %
            % See also: 
            %   Contents, StreamBuffer, StreamBuffer.set_sample_count,
            %       StreamBuffer.set_channel_count
            if numel(self) > 1
                for ii = 1:numel(self)
                    self(ii).reset_buffer();
                end
                return;
            end
            self.counter = 0;
            self.start = 1;
            self.wrapping = 1:self.n.samples;
            self.index = 1:self.n.samples;
            self.samples = zeros(self.n.channels, self.n.samples);
        end
        
        function [fname, block] = save(self, fname)
            %SAVE  Save data buffered in .samples to variable 'samples' in fname (file)
            %
            % Syntax:
            %   [fname, block] = self.save(fname);
            %
            % Inputs:
            %   fname - Name of file to save to. Note that if this is
            %           located in a directory that doesn't exist, the
            %           folder will be created for it.
            %
            % Output:
            %   fname - Version of input fname that was used.
            %   block - Numeric block index used in actual filename.
            %
            % See also: Contents
            
            if numel(self) > 1
                fname = string(fname);
                if numel(fname) == 1
                    fname = repmat(fname, size(self));
                end
                for ii = 1:numel(self)
                    fname(ii) = self(ii).save(fname(ii));
                end
                return;
            end
            
            [p, f, e] = fileparts(fname);
            if isempty(e)
                f = char(strcat(f, ".mat"));
            else
                f = char(strcat(f, e));
            end
            if contains(f, "%s")
                f = char(sprintf(f, self.tag));
            end
            if exist(p, 'dir') == 0
                try %#ok<TRYNC>
                    warning('off', 'MATLAB:MKDIR:EmptyDirectoryName');
                    mkdir(p);
                    warning('on', 'MATLAB:MKDIR:EmptyDirectoryName');
                    fprintf(1,'[StreamBuffer::%s]\tCreated save folder:\n\t<strong>%s</strong>\n\n', self.tag, p);
                end
            end
            fname = fullfile(p, f);
            update_fname = false;
            block_orig = regexp(f, sprintf('((?<=%s\\_)\\d+)',self.tag), 'match');
            while exist(fname, 'file')~=0
                update_fname = true;
                [block_start, block_end] = regexp(f, sprintf('((?<=%s\\_)\\d+)',self.tag));
                block = str2double(f(block_start:block_end)) + 1;
                f = [f(1:(block_start-1)), char(num2str(block)), f((block_end+1):end)];
                fname = fullfile(p,f);
            end
            if update_fname
                fprintf(1,"[StreamBuffer::%s]\tUpdated BLOCK-%s filename to %s\n", self.tag, block_orig, f);
            else
                block = str2double(block_orig);
            end
            ns = min(self.counter, self.n.samples); % Truncate unassigned samples (only save what was actually appended).
            samples = self.samples(:, 1:ns); %#ok<PROPLC>
            channels = num2cell(self.channels); %#ok<PROPLC>
            sample_rate = self.sample_rate; %#ok<PROPLC>
            time = datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS', 'TimeZone', 'America/New_York') - seconds(ns/sample_rate);
            save(fname, 'samples', 'channels', 'sample_rate', 'time', '-v7.3');
        end
        
        function set_channel_count(self, n)
            %SET_CHANNEL_COUNT Sets the total number of channels in sample buffer.
            %
            % Syntax:
            %   self.set_channel_count(n);
            %
            % Inputs:
            %   n  -  The new number of channels.
            %
            % Note: this wipes the sample buffer and resets the index and
            %       counter.
            %
            % See also: Contents, StreamBuffer
            if numel(self) > 1
                for ii = 1:numel(self)
                    self(ii).set_channel_count(n);
                end
                return;
            end
            self.n.channels = n;
            self.reset_buffer();
        end
        
        function set_sample_count(self, n)
            %SET_SAMPLE_COUNT Sets the total number of samples in sample buffer.
            %
            % Syntax:
            %   self.set_sample_count(n);
            %
            % Inputs:
            %   n  -  The new number of samples per frame.
            %
            % Note: this wipes the sample buffer and resets the index and
            %       counter.
            %
            % See also: Contents, StreamBuffer
            if numel(self) > 1
                for ii = 1:numel(self)
                    self(ii).set_sample_count(n);
                end
                return;
            end
            self.n.samples = n;
            self.reset_buffer();
        end
        
        function set_ports(self, config_server_udp, config_server_udphost)
        %SET_PORTS  Set `ports` property
            arguments
                self
                config_server_udp (1,1) struct % See config struct returned by `parse_main_config`
                config_server_udphost (1,1) struct % See confi struct returned by `parse_main_config`
            end 
            self.ports = config_server_udp;
            self.hosts = config_server_udphost;
            self.has_ports = true;
        end

        function init_callback(self, event, handler_mode, options)
           arguments
                self
                event {mustBeTextScalar, mustBeMember(event,{'FrameFilledEvent','ThresholdEvent'})}
                handler_mode {mustBeTextScalar, mustBeMember(handler_mode, {'bip', 'muap', 'all'})}
                options.BipolarChannelIndices = 66:69;
                options.CallbackPort = [];
                options.CallbackHost {mustBeTextScalar} = "";
           end
           switch event
               case 'FrameFilledEvent'
                    if ~self.has_callback.frame
                        switch handler_mode
                            case 'bip'
                                if self.has_ports
                                    if ~isfield(self.ports, handler_mode)
                                        error("'%s' is not a field of `ports` struct, which is usually in config.Server.UDP returned from `parse_main_config.m`. Check that this port is configured in the configuration .yaml file specified in `parameters.m`.", handler_mode);
                                    else
                                        if isempty(options.CallbackPort)
                                            self.frame_callback_port = self.ports.(handler_mode).(self.tag);
                                        else
                                            self.frame_callback_port = options.CallbackPort;
                                        end
                                        if strlength(options.CallbackHost) == 0
                                            self.frame_callback_host = self.hosts.(handler_mode);
                                        else
                                            self.frame_callback_host = options.CallbackHost;
                                        end
                                        self.frame_handler_mode = handler_mode;
                                        self.frame_warning_flag = true;
                                        self.bipolar_channels = options.BipolarChannelIndices;
                                    end
                                else
                                    error("UDP ports not yet configured. Please first call `set_ports` method before initializing callbacks.");
                                end
                            case 'muap'
                                if self.has_ports
                                    if ~isfield(self.ports, handler_mode)
                                        error("'%s' is not a field of `ports` struct, which is usually in config.Server.UDP returned from `parse_main_config.m`. Check that this port is configured in the configuration .yaml file specified in `parameters.m`.", handler_mode);
                                    else
                                        if ~isfield(self.ports, handler_mode)
                                            error("'%s' is not a field of `ports` struct, which is usually in config.Server.UDP returned from `parse_main_config.m`. Check that this port is configured in the configuration .yaml file specified in `parameters.m`.", handler_mode);
                                        else
                                            if isempty(options.CallbackPort)
                                                self.frame_callback_port = self.ports.(handler_mode);
                                            else
                                                self.frame_callback_port = options.CallbackPort;
                                            end
                                            if strlength(options.CallbackHost) == 0
                                                self.frame_callback_host = self.hosts.(handler_mode);
                                            else
                                                self.frame_callback_host = options.CallbackHost;
                                            end
                                            self.frame_handler_mode = handler_mode;
                                            self.frame_warning_flag = true;
                                        end
                                    end
                                else
                                    error("UDP ports not yet configured. Please first call `set_ports` method before initializing callbacks.");
                                end
                            otherwise
                                error("FrameFilledEvent is incompatible with '%s' handling.", handler_mode);
                        end

                        self.has_callback.frame = true;
                    else
                        error("FrameFilledEvent callback already registered. Please deinitialize the callback first.");
                    end
               case 'ThresholdEvent'
                   warning('ThresholdEvent callback `init` is not yet implemented.');
           end
        end

        function deinit_callback(self, event)
           arguments
                self
                event {mustBeTextScalar, mustBeMember(event,{'FrameFilledEvent','ThresholdEvent'})}
           end
           switch event
               case 'FrameFilledEvent'
                   if self.has_callback.frame
                       self.frame_callback_port = [];
                       self.frame_callback_host = [];
                       self.frame_handler_mode = [];
                       self.has_callback.frame = false;
                       self.frame_warning_flag = false;
                   end
               case 'ThresholdEvent'
                   warning('ThresholdEvent callback `deinit` is not yet implemented.');
           end
        end

        function stop_sampling(self)
            %STOP_SAMPLING  Sets the `stop` property to false (for getData)
            %
            % Syntax:
            %   self.stop_sampling();
            %
            % See also: 
            %   Contents, StreamBuffer, StreamBuffer.getData
            if numel(self) > 1
                for ii = 1:numel(self)
                    self(ii).stop_sampling;
                end
                return;
            end
            self.stop = true;
        end
    end

    methods (Access = protected)
        function handle_frame_filled_event(self)
            switch self.frame_handler_mode
                case 'bip'
%                     [t,sample_order] = sort(self.index./self.sample_rate, 'ascend');
                    [~,sample_order] = sort(self.index, 'ascend');
                    channel_id = (1:numel(self.bipolar_channels)) + 4*double(strcmpi(self.tag, self.saga_2_tag));
%                     sample_data = self.samples(self.bipolar_channels, sample_order);
                    sample_data = randn(numel(self.bipolar_channels), numel(sample_order));
                    data = ([channel_id', sample_data])';                          
                    self.udp.write(data(:), "double", self.frame_callback_host, self.frame_callback_port);
                case 'muap'
                    if self.frame_warning_flag
                        warning('MUAP frame filled event handler not yet implemented!');
                        self.frame_warning_flag = false;
                    end
            end
            

        end

%         function handle_threshold_event(self)
% 
%         end
    end
end

