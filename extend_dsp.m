function eS = extend_dsp(S, delayObjs)
%EXTEND_DSP DSP implementation of CKC sample array extension
%
% Inputs:
%   S - input signal matrix of size (r, c)
%   delayObjs - preallocated dsp.Delay objects for each extension factor
%
% Outputs:
%   eS - extended signal matrix with delayed repetitions

[nSamples, nChannels] = size(S);
extFact = numel(delayObjs);
eS = zeros(nSamples + extFact - 1, nChannels * extFact);

% Apply delay to each row and place in extended matrix
vec = 1:nChannels;
for m = 1:extFact
    % Insert delayed signal into the extended signal matrix
    eS(m:(nSamples + m - 1), vec + (m-1)*nChannels) = delayObjs{m}(S);
end
end
