function [beta0, beta, Y_hat] = fit_poly_model(Y, X, channels, maxChannelsPerRow)
%FIT_POLY_MODEL  Fit polynomial model with iterative channel selection
%
% Syntax:
%   [beta0, beta] = fit_poly_model(Y, X, channels, maxChannelsPerRow);
%
% Inputs:
%   Y - [nRows x nSamples] Cartesian positions to fit
%   X - [256 x nSamples] Envelope of highpass filtered power from sEMG
%   channels - [1 x nChannels] List of viable channels for regression.
%   maxChannelsPerRow - [1 x 1] Maximum number of non-zero coefficients per row of Y.
%
% Output:
%   beta0 - [nRows x 1] Intercept coefficient
%   beta  - [nRows x 256] Least-squares optimal regression coefficients
%   Y_hat - [nRows x nSamples] Fitted values
%
% See also: Contents

arguments
    Y double
    X (256,:) double 
    channels {mustBeInteger, mustBeInRange(channels, 1, 256)} = 1:256;
    maxChannelsPerRow (1,1) double {mustBePositive, mustBeInteger} = 4;
end

nRows = size(Y, 1);
% nChannels = length(channels);

% Initialize beta with zeros
beta = zeros(nRows, 256);

% Perform initial regression using all channels
initial_beta = zeros(nRows, 256);
initial_beta(:, channels) = (Y / X(channels,:));

% Select top channels based on initial regression coefficients
for i = 1:nRows
    [~, sortedIndices] = sort(abs(initial_beta(i, channels)), 'descend');
    topChannels = channels(sortedIndices(1:maxChannelsPerRow));
    
    % Perform regression using the selected top channels
    beta(i, topChannels) = Y(i,:) / X(topChannels,:);
    
    % Remove selected channels from the pool for subsequent iterations
    channels = setdiff(channels, topChannels);
end

% Compute fitted values
Y_hat = beta * X;

% Calculate intercept
i_comparison = sum(abs(Y), 1) == 0; % Want to "zero out" the part where we're at rest
beta0 = median(Y(:, i_comparison) - Y_hat(:, i_comparison), 2);
end
