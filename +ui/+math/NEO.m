function Z = NEO(X, dim)
%NEO  Returns the nonlinear energy operator (NEO) for signal X
%
% Syntax:
%   Z = math.NEO(X);
%   Z = math.NEO(X, dim);
%
% Inputs:
%   X   - Input signal for computing NEO. Can be vector or array.
%   dim - (Optional, default = 1). Dimension along which to compute NEO. 
%           By default, it computes NEO along the first dimension (1),
%           which means it will compute NEO for columns of an input data
%           array, unless dim is specified as 2.
%
% Output:
%   Z   - Discrete nonlinear energy operator at each sample of X. The first
%           and last samples cannot be computed so they are automatically
%           set to zero. 

if nargin < 2
   dim = 1; 
end

Y = X - mean(X, dim);

if dim == 1
    if isvector(X)
        X = reshape(X, numel(X), 1);
    end
    nC = size(X, 2);
    Yb = Y(1:(end-2), :);
    Yf = Y(3:end, :);
    % Discrete nonlinear energy operator
    Z = [zeros(1, nC); Y(2:(end-1), :).^2 - Yb .* Yf; zeros(1, nC)];
else
    if isvector(X)
        X = reshape(X, 1, numel(X));
    end
    nR = size(X, 1);
    Yb = Y(:, 1:(end-2));
    Yf = Y(:, 3:end);
    % Discrete nonlinear energy operator
    Z = [zeros(nR, 1), Y(:, 2:(end-1)).^2 - Yb .* Yf, zeros(nR, 1)]; 
end

end