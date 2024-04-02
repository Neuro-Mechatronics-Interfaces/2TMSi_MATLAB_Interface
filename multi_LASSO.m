function [Bm, fitinfo] = multi_LASSO(snips, pks, options)
%MULTI_LASSO Runs LASSO procedure to estimate betas for ALL clusters.
%
% Syntax:
%   [Bm, fitinfo] = multi_LASSO(snips, pks, "Name", value, ...);
arguments
    snips
    pks
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.7; % 0 --> RIDGE (conditioning noise identity matrix) | 1 --> LASSO (regularizer penalty on L2 weights)
    options.NumLambda (1,1) double {mustBeInteger, mustBePositive} = 20;
    options.Lambda = []; % seems 30-40 is a good value
end
if isempty(options.Lambda)
    [Bm, fitinfo] = lasso(repmat(snips,size(pks,2)), pks(:), ...
        'Alpha', options.Alpha, ...
        'Standardize', false, ...
        'Intercept', false, ...
        'NumLambda', options.NumLambda);
else
    [Bm, fitinfo] = lasso(repmat(snips,size(pks,2)), pks(:), ...
        'Alpha', options.Alpha, ...
        'Standardize', false, ...
        'Intercept', false, ...
        'Lambda', options.Lambda);
end

end