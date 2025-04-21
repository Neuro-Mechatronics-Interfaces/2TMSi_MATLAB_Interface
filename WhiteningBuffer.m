classdef WhiteningBuffer < handle
    properties
        buffer          % (M x N) matrix, circular buffer
        bufferLen       % N = total timepoints in buffer
        currIdx = 1     % current write index (1-based)
        isFull = false
        numChannels
    end

    methods
        function obj = WhiteningBuffer(numChannels, bufferLen)
            obj.buffer = zeros(numChannels, bufferLen);
            obj.bufferLen = bufferLen;
            obj.numChannels = numChannels;
        end

        function setBufferSize(obj, numChannels, numSamples)
            obj.buffer = zeros(numChannels, numSamples);
            obj.bufferLen = numSamples;
            obj.isFull = false;
            obj.currIdx = 1;
            obj.numChannels = numChannels;
        end

        function [refresh,K] = update(obj, newSamples)
            % newSamples: (M x K), where M == numChannels
            [M, K] = size(newSamples);
            assert(M == obj.numChannels, 'Channel count mismatch');

            endIdx = obj.currIdx + K - 1;
            wrap = endIdx > obj.bufferLen;

            if ~wrap
                obj.buffer(:, obj.currIdx:endIdx) = newSamples;
            else
                firstPart = obj.bufferLen - obj.currIdx + 1;
                secondPart = K - firstPart;
                obj.buffer(:, obj.currIdx:end) = newSamples(:, 1:firstPart);
                obj.buffer(:, 1:secondPart) = newSamples(:, firstPart+1:end);
            end

            obj.currIdx = mod(obj.currIdx - 1 + K, obj.bufferLen) + 1;
            obj.isFull = obj.isFull || (K >= obj.bufferLen) || (wrap && obj.currIdx <= K);
            refresh = obj.isFull && (wrap || obj.currIdx == 1);
        end

        function chunk = getWindow(obj, delay, length)
            % Return a time window from (currIdx - delay - length) to (currIdx - delay)
            idxs = mod(((obj.currIdx - delay - length) : (obj.currIdx - 1))-1, obj.bufferLen)+1;
            chunk = obj.buffer(:, idxs);
        end

        function raw = getRawBuffer(obj)
            if ~obj.isFull
                raw = obj.buffer(:, 1:obj.currIdx-1);
            else
                raw = [obj.buffer(:, obj.currIdx:end), obj.buffer(:, 1:obj.currIdx-1)];
            end
        end
    end
end
