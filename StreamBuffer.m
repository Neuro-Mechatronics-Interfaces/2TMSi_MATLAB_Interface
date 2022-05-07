classdef StreamBuffer < matlab.net.http.io.ContentProvider
    %STREAMBUFFER  Implements a buffer for streamed data.
    
    properties (Access = public)
        samples   double             % Data samples, each row is a channel arranged from UNI_01 to UNI_64
    end
    
    properties (GetAccess = public, SetAccess = protected)
        array       string             % "A" or "B"
        counter     double = 0         % Total number of samples (rolling)
        index       double             % The integer index that increments by 1 for each sample, denoting ordering of samples (columns)
        n           struct             % Struct describing size of data samples array.
        start       double = 1         % Starting index (rolling).
        udp                            % UDP port object
        wrapping    double
    end
    
    properties (Access = protected)
        init        logical = false    % This sets to true once successfully initialized.
        stop        logical = false    % This is returned by `getData` second argument.
    end
    
    events
        FrameFilledEvent    % Issued any time that a data frame is filled.
    end
    
    methods
        function obj = StreamBuffer(array, nChannels, nSamples, port)
            %STREAMBUFFER  Implements a buffer for streamed data.
            %
            % Syntax:
            %   obj = StreamBuffer(array, nChannels, nSamples, port);
            %
            % Inputs:
            %   array     - "A" or "B"
            %   nChannels - Number of channels (optional; default = 64)
            %   nSamples  - Number of samples (optional; default = 32768)
            %   port      - Port number (optional; default = 9090)
            %
            % Output:
            %   obj - StreamBuffer object
            %
            % See also: Contents, StreamBuffer
            
            switch nargin
                case 1
                    obj.n = struct('channels', 64, 'samples', 32768);
                case 2
                    obj.n = struct('channels', nChannels, 'samples', 32768);
                case 3
                    obj.n = struct('channels', nChannels, 'samples', nSamples);
                case 4
                    obj.n = struct('channels', nChannels, 'samples', nSamples);
                    obj.port = port;
                otherwise
                    error("Invalid number of input arguments (%d).", nargin);
            end
            obj.array = array;
            obj.samples = zeros(obj.n.channels, obj.n.samples);
            obj.index = 1:obj.n.samples;
            obj.wrapping = 1:obj.n.samples;
            obj.udp = udpport();
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
            obj.samples(:, obj.wrapping(1:ns)) = value;
            obj.wrapping = circshift(obj.wrapping, -ns);
            obj.start = obj.start + ns;
            obj.counter = obj.counter + ns;
            if obj.counter >= obj.n.samples
                obj.counter = 0;
                notify(obj, "FrameFilledEvent");       
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

