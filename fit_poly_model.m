function [beta0, beta, Y_hat] = fit_poly_model(Y,X)
%FIT_POLY_MODEL  Fit polynomial  model
%
% Syntax:
%   [beta0, beta] = fit_poly_model(Y, X);
%
% Inputs:
%   Y - 2 x nSamples cartesian positions to fit
%   X - 128 x nSamples envelope of highpass filtered power from sEMG
%
% Output:
%   beta0 - [2 x 1] Intercept coefficient
%   beta  - [2 x 128] Least-squares optimal regression coefficients
%
% See also: Contents

arguments
    Y (2,:) double
    X (128,:) double 
end

beta = Y/X;
Y_hat = beta * X;
beta0 = mean(Y - Y_hat,2);

end