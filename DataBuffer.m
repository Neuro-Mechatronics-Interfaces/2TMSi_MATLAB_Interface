classdef DataBuffer < matlab.mixin.SetGet
    %DATABUFFER  Implements a buffer to hold data frames while sampling.
    
    properties (Access = public)
        samples   double             % Data samples, each row is a channel arranged from UNI_01 to UNI_64
    end
    
    properties (GetAccess = public, SetAccess = private)
        index     double             % The integer index that increments by 1 for each sample, denoting ordering of samples (columns)
        start     double = 1         % Starting index (rolling).
        wrapping  double
        counter   double = 0         % Total number of samples (rolling)
    end
    
    properties (Constant, Hidden)
        N_SAMPLES_PER_FRAME double = 32768;  % Number of samples in a data frame.
    end
    
    events
        FrameFilledEvent    % Issued any time that a data frame is filled.
    end
    
    methods
        function obj = DataBuffer(dims)
            %DATABUFFER  Implements a buffer to hold data frames while sampling.
            %
            % Syntax:
            %   obj = DataBuffer();
            %   obj = DataBuffer(dims);
            %
            % Inputs:
            %   dims - (Optional) specify dimensions to produce array
            %                     output of multiple data buffer objects.
            if nargin > 0
                obj = repmat(obj, dims);
                for ii = 1:numel(dims)
                    obj(ii) = DataBuffer();
                end
                return;
            end
            obj.samples = nan(64, obj.N_SAMPLES_PER_FRAME);
            obj.index = nan(1, obj.N_SAMPLES_PER_FRAME);
            obj.wrapping = 1:obj.N_SAMPLES_PER_FRAME;
        end
        
        function append(obj, value)
            %APPEND  Append new samples to the data
            n = size(value, 2);
            obj.index(obj.wrapping(1:n)) = obj.start : (obj.start + n - 1);
            obj.samples(:, obj.wrapping(1:n)) = value;
            obj.wrapping = circshift(obj.wrapping, -n);
            obj.start = obj.start + n;
            obj.counter = obj.counter + n;
            if obj.counter >= obj.N_SAMPLES_PER_FRAME
                obj.counter = 0;
                notify(obj, "FrameFilledEvent");
            end
        end
        
        function merge(obj, dbuf2)
            %MERGE  Copy relevant values from a different data buffer
            obj.index = dbuf2.index;
            obj.samples = dbuf2.samples;
            obj.wrapping = dbuf2.wrapping;
            obj.start = dbuf2.start;
            obj.counter = dbuf2.counter;
        end
    end
end

