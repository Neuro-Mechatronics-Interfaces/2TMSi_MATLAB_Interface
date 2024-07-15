function [beta0, beta, Y_hat] = fit_poly_model(Y,X,channels)
%FIT_POLY_MODEL  Fit polynomial  model
%
% Syntax:
%   [beta0, beta] = fit_poly_model(Y, X);
%
% Inputs:
%   Y - 3 x nSamples cartesian positions to fit
%   X - 128 x nSamples envelope of highpass filtered power from sEMG
%   channels - (Optional: default is 1:128) -- channels to use in
%                   regression. Note that any channels excluded will still
%                   be included in returned `beta` columns, just as
%                   zero-valued coefficients.
%
% Output:
%   beta0 - [3 x 1] Intercept coefficient
%   beta  - [3 x 128] Least-squares optimal regression coefficients
%
% See also: Contents

arguments
    Y (3,:) double
    X (256,:) double 
    channels % (1,:) {mustBeInteger, mustBeInRange(channels, 1, 256)} = 1:256;
end

beta = zeros(3,256);
beta(:,channels) = Y/X(channels,:);
Y_hat = beta * X;
i_comparison = sum(abs(Y),1) == 0; % Want to "zero out" the part where we're at rest.
beta0 = median(Y(:,i_comparison) - Y_hat(:,i_comparison),2);
end