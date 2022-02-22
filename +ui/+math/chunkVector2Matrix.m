function [X,idx,nClipped] = chunkVector2Matrix(x,nSamplesPerChunk,nSamplesOverlap)
%CHUNKVECTOR2MATRIX  "Chunks" a vector into a matrix format
%
%  X = math__.chunkVector2Matrix(x,nSamplesPerChunk,nSamplesOverlap);
%  [X,idx,nClipped] = ...
%
%  -- inputs --
%  x  :  Vector to "chunk"
%  nSamplesPerChunk  : Number of samples in each "chunk"
%                       --> Output matrix X will have this many rows
%  nSamplesOverlap   : (Optional) number of samples of overlap for "chunks"
%                       --> Value must fulfill criterion:
%                             nSamplesOverlap <= (nSamplesPerChunk - 1)
%
%  -- output --
%  X  :  Matrix of "chunked" data points
%
%  idx : Indices such that y = horzcat(x,zeros(1,nClipped)); y(idx) == X
%
%  nClipped : Number of "clipped" samples (see `idx`)

if nargin < 3
   nSamplesOverlap = 0;
end

if ~isrow(x)
   x = x.';
end

nTotal = size(x,2);
idx = (1:(nSamplesPerChunk-nSamplesOverlap):nTotal).';
idx = ones(numel(idx),nSamplesPerChunk) .* idx;
idx = idx + (0:(nSamplesPerChunk-1));
idx = idx.';

% Account for non-integer multiples
nClipped = idx(end,end) - nTotal;

x = horzcat(x,zeros(1,nClipped));
X = x(idx);

end