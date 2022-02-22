function Zs = SNEO(X, n, dim)
%SNEO  Returns the smoothed nonlinear energy operator (SNEO) for signal X
%
% Syntax:
%   Zs = math.SNEO(X);
%   Zs = math.SNEO(X, n, dim);
%
% Inputs:
%   X   - Input signal for computing SNEO. Can be vector or array.
%   n   - (Optional, default = 5). Number of samples in smoothing window.
%   dim - (Optional, default = 1). Dimension along which to compute SNEO. 
%           By default, it computes SNEO along the first dimension (1),
%           which means it will compute SNEO for columns of an input data
%           array, unless dim is specified as 2.
%
% Output:
%   Zs  - Smoothed nonlinear energy operator at each sample of X. The first
%           and last samples cannot be computed so they are automatically
%           set to zero. 

if nargin < 3
   dim = 1; % Compute SNEO along columns by default.
end

if nargin < 2
   n = 5;   % Default for smoothing spike peaks. 
end

Z = math.NEO(X, dim);

if dim == 1 % Apply smoothing along columns.
    kern = ones(n, 1)./n;
    Zs = flipud( conv( flipud( conv(Z, kern, 'same')) , kern, 'same'));
else % Otherwise apply it along the rows.
    kern = ones(1, n)./n; % Credit: Federico Barban faster method (~2020?)
    Zs = fliplr( conv( fliplr( conv(Z, kern, 'same')) , kern, 'same'));
end

end