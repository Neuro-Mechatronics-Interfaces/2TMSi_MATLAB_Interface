function eS = fast_extend(S, extFact)
%FAST_EXTEND "Extend" input signal array S where (extended) channels are rows and individual samples are columns.
%
% Syntax:
%   eS = fast_extend(S, extFact);
%
% Inputs:
%   S - Signal array of dimensions r (channels) x c (samples)
%   extFact - The number of time-samples to extend each channel by.

% Get number of rows and columns of S.
[r, c] = size(S);

% Preallocate the extended matrix
eS = zeros(r * extFact, c + extFact - 1);

% Fill in the extended matrix by shifting the rows
for i = 1:extFact
    eS(i:extFact:end, i:(i + c - 1)) = S;
end

end
