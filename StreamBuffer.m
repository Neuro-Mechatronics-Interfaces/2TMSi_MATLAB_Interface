classdef StreamBuffer < matlab.net.http.io.ContentProvider
    %STREAMBUFFER  Implements a buffer for streamed data.
    
    properties (Access = public)
        samples   double             % Data samples, each row is a channel arranged from UNI_01 to UNI_64
    end
    
    properties (GetAccess = public, SetAccess = protected)
        array       string ="A"        % "A" or "B"
        channels                       % Cell array of channels
        counter     double = 0         % Total number of samples (rolling)
        index       double             % The integer index that increments by 1 for each sample, denoting ordering of samples (columns)
        n           struct             % Struct describing size of data samples array.
        start       double = 1         % Starting index (rolling).
        sample_rate double = 4000      % Data in buffer was sampled at this rate (Hz)
        wrapping    double
    end
    
    properties (Access = protected)
        init        logical = false    % This sets to true once successfully initialized.
        stop        logical = false    % This is returned by `getData` second argument.
        mode  (1,1) StreamBufferMode = StreamBufferMode.FRAME; % This determines what 'Event' is issued when appending samples to the buffer.
        settings (1,1) struct          % Contains settings that depend on the event mode.
    end
    
    events
        FrameFilledEvent    % Issued any time that a data frame is filled.
        ThresholdEvent      % Issued when a threshold is crossed.
    end
    
    methods
        function obj = StreamBuffer(channels, nSamples, array, sample_rate)
            %STREAMBUFFER  Implements a buffer for streamed data.
            %
            % Syntax:
            %   obj = StreamBuffer(channels, nSamples, port, array);
            %
            % Inputs:
            %   nChannels - Number of channels (optional; default = 64)
            %   nSamples  - Number of samples (optional; default = 32768)
            %   array     - Port number (optional; default = "A")
            %   sample_rate - Sampling rate, Hz (optional; default = 4000)
            %
            % Output:
            %   obj - StreamBuffer object
            %
            % See also: Contents, StreamBuffer
            switch nargin
                case 0
                    error("Must pass `channels` argument at least.");
                case 1
                    obj.n = struct('channels', numel(channels), 'samples', 16384, 'samples_per_frame', 16384);
                case 2
                    obj.n = struct('channels', numel(channels), 'samples', nSamples, 'samples_per_frame', nSamples);
                case 3
                    obj.n = struct('channels', numel(channels), 'samples', nSamples, 'samples_per_frame', nSamples);
                    obj.array = string(array);
                case 4
                    obj.n = struct('channels', numel(channels), 'samples', nSamples, 'samples_per_frame', nSamples);
                    obj.array = string(array);
                    obj.sample_rate = sample_rate;
                otherwise
                    error("Invalid number of input arguments (%d).", nargin);
            end
            obj.channels = channels;
            obj.samples = zeros(obj.n.channels, obj.n.samples);
            obj.index = 1:obj.n.samples;
            obj.wrapping = 1:obj.n.samples;
            obj.init = true;
        end
        
        function append(obj, value)
            %APPEND  Append new samples to the data
            %
            % Syntax:
            %   obj.append(value);
            %
            % Inputs:
            %   value - If obj is an array, then value should be a cell
            %           array with dimensions the size of `obj`. Each cell
            %           array element should be a sample data array with
            %           dimensions obj.n.channels x k, for k sampledata
            %           sets (samples from all channels for k samples).
            %
            % See also: Contents
            if iscell(value)
                for ii = 1:numel(value)
                    obj(ii).append(value{ii});
                end
                return;
            end
            ns = min(size(value, 2), obj.n.samples);
            obj.index(obj.wrapping(1:ns)) = obj.start : (obj.start + ns - 1);
            obj.samples(:, obj.wrapping(1:ns)) = value(:, 1:ns);
            obj.wrapping = circshift(obj.wrapping, -ns);
            obj.start = obj.start + ns;
            obj.counter = obj.counter + ns;
            
            % If we filled up, then send data samples.
            
            if obj.counter >= obj.n.samples_per_frame
                obj.counter = 0;
                notify(obj, "FrameFilledEvent");       
            end
            
            % If we "overflowed" then do this again until we have nothing
            % left to append.
            if ns < size(value, 2)
                obj.append(value(:, (ns+1):end));
            end
        end
        
        function data = consume(obj, nSamples)
            %CONSUME  Move the sample index by nSamples and return data.
            %
            % Syntax:
            %   data = obj.consume(nSamples);
            %
            % Inputs:
            %   nSamples - The number of samples to consume (scalar).
            %
            % Output:
            %   data - obj.n.channels x nSamples data array from
            %           obj.samples.
            %
            % See also: Contents, StreamBuffer, StreamBuffer.getData

            lb = obj.start - nSamples + 1;
            
            % If we requested to consume before we have even sampled enough
            % to build the indexing vector, just return zeros.
            if lb < 1
                data = zeros(obj.n.channels, nSamples);
                return;
            end
            
            iMask = obj.index >= lb;
            iData = obj.index(iMask);
            [~, idx] = sort(iData, 'ascend');
            data = obj.samples(:, iMask);
            data = data(:, idx);
            obj.reset_buffer();
        end
        
        function [data, stop] = getData(obj, ~)
            %GETDATA  Return n samples of data
            %
            % Syntax:
            %   [data, stop] = obj.getData(nSamples);
            %
            % Inputs:
            %   nSamples - Return this many columns of data.
            %
            % Output:
            %   data - Data array with obj.n.channels x nSamples.
            %
            %       Note: nSamples is ignored currently, so this will
            %       always be an array of obj.n.channels x obj.n.samples.
            %   
            %   stop - Always returns false unless, obj.stop_sampling() has
            %           been called.
            %
            % See also: Contents, StreamBuffer, 
            %           StreamBuffer.stop_sampling, StreamBuffer.consume           
%             data = obj.consume(nSamples);
            data = obj.samples;
            stop = obj.stop;
        end
        
        function merge(obj, obj2)
            %MERGE  Copy relevant values from a different data buffer
            %
            % Syntax:
            %   obj.merge(obj2);
            %
            % Inputs:
            %   obj2 - Second StreamBuffer object to merge values with.
            %
            % See also: Contents, StreamBuffer
            
            obj.index = obj2.index;
            obj.samples = obj2.samples;
            obj.wrapping = obj2.wrapping;
            obj.start = obj2.start;
            obj.counter = obj2.counter;
        end
        
        function reset_buffer(obj)
            %RESET_BUFFER  Resets the buffer and related properties
            %
            % Syntax:
            %   obj.reset_buffer();
            %
            % See also: 
            %   Contents, StreamBuffer, StreamBuffer.set_sample_count,
            %       StreamBuffer.set_channel_count
            if numel(obj) > 1
                for ii = 1:numel(obj)
                    obj(ii).reset_buffer();
                end
                return;
            end
            obj.counter = 0;
            obj.start = 1;
            obj.wrapping = 1:obj.n.samples;
            obj.index = 1:obj.n.samples;
            obj.samples = zeros(obj.n.channels, obj.n.samples);
        end
        
        function fname = save(obj, fname)
            %SAVE  Save data buffered in .samples to variable 'samples' in fname (file)
            %
            % Syntax:
            %   fname = obj.save(fname);
            %
            % Inputs:
            %   fname - Name of file to save to. Note that if this is
            %           located in a directory that doesn't exist, the
            %           folder will be created for it.
            %
            % Output:
            %   fname - Version of input fname that was used.
            %
            % See also: Contents
            
            if numel(obj) > 1
                fname = string(fname);
                if numel(fname) == 1
                    fname = repmat(fname, size(obj));
                end
                for ii = 1:numel(obj)
                    fname(ii) = obj(ii).save(fname(ii));
                end
                return;
            end
            
            [p, f, e] = fileparts(fname);
            if isempty(e)
                f = strcat(f, ".mat");
            else
                f = strcat(f, e);
            end
            if contains(f, "%s")
                f = sprintf(f, obj.array);
            end
            if isempty(p)
                fname = f;
            else
                if exist(p, 'dir') == 0
                    try %#ok<TRYNC>
                        mkdir(p);
                        fprintf(1,'Created save folder:\n\t<strong>%s</strong>\n\n', p);
                    end
                end
                fname = fullfile(p, f);
            end
            ns = min(obj.counter, obj.n.samples); % Truncate unassigned samples (only save what was actually appended).
            samples = obj.samples(:, 1:ns); %#ok<PROPLC>
            channels = num2cell(obj.channels); %#ok<PROPLC>
            sample_rate = obj.sample_rate; %#ok<PROPLC>
            time = datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS');
            save(fname, 'samples', 'channels', 'sample_rate', 'time', '-v7.3');
        end
        
        function set_channel_count(obj, n)
            %SET_CHANNEL_COUNT Sets the total number of channels in sample buffer.
            %
            % Syntax:
            %   obj.set_channel_count(n);
            %
            % Inputs:
            %   n  -  The new number of channels.
            %
            % Note: this wipes the sample buffer and resets the index and
            %       counter.
            %
            % See also: Contents, StreamBuffer
            if numel(obj) > 1
                for ii = 1:numel(obj)
                    obj(ii).set_channel_count(n);
                end
                return;
            end
            obj.n.channels = n;
            obj.reset_buffer();
        end
        
        function set_sample_count(obj, n)
            %SET_SAMPLE_COUNT Sets the total number of samples in sample buffer.
            %
            % Syntax:
            %   obj.set_sample_count(n);
            %
            % Inputs:
            %   n  -  The new number of samples per frame.
            %
            % Note: this wipes the sample buffer and resets the index and
            %       counter.
            %
            % See also: Contents, StreamBuffer
            if numel(obj) > 1
                for ii = 1:numel(obj)
                    obj(ii).set_sample_count(n);
                end
                return;
            end
            obj.n.samples = n;
            obj.reset_buffer();
        end
        
        function stop_sampling(obj)
            %STOP_SAMPLING  Sets the `stop` property to false (for getData)
            %
            % Syntax:
            %   obj.stop_sampling();
            %
            % See also: 
            %   Contents, StreamBuffer, StreamBuffer.getData
            if numel(obj) > 1
                for ii = 1:numel(obj)
                    obj(ii).stop_sampling;
                end
                return;
            end
            obj.stop = true;
        end
    end
end

