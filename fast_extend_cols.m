function eS = fast_extend_cols(S, extFact)
%FAST_EXTEND_COLS "Extend" input signal array S where (extended) channels are columns and individual samples are rows.
%
% Syntax:
%   eS = fast_extend_cols(S, extFact);
%
% Inputs:
%   S - Signal array of dimensions r (samples) x c (channels)
%   extFact - The number of time-samples to extend each channel by.

% Get number of rows and columns of S.
[r, c] = size(S);

% Preallocate the extended matrix
eS = zeros(r + extFact - 1, c * extFact);

% Fill in the extended matrix by shifting the rows
for i = 1:extFact
    eS(i:(i + r - 1), i:extFact:end) = S;
end

end
