function frameCounter = clock_2_frame(clockSignal)
% CLOCK_2_FRAME Converts a clock signal to a frame counter vector.
% Each edge transition (0->1 or 1->0) increments the frame counter.
%
% INPUT:
%   clockSignal - A vector of binary values (0 or 1).
%                 The length of the vector determines the number of samples.
%
% OUTPUT:
%   frameCounter - A vector of the same size as clockSignal, where each
%                  edge transition increments the frame counter.

% Validate input
if ~isvector(clockSignal) || ~all(ismember(clockSignal, [0, 1]))
    error('Input must be a vector of binary values (0 or 1).');
end

% Preallocate the output frame counter
frameCounter = zeros(size(clockSignal));

% Identify edge transitions (XOR with shifted version to detect changes)
edgeTransitions = [0, diff(clockSignal)] ~= 0;

% Increment the frame counter at each edge transition
frameCounter(edgeTransitions) = 1;

% Compute the cumulative sum to propagate frame numbers
frameCounter = cumsum(frameCounter);
end
