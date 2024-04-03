function [Bc, fitinfo] = combined_LASSO(snips, clus, good_clus, pks, options)
%COMBINED_LASSO Runs LASSO procedure to estimate betas for ALL clusters.
%
% Syntax:
%   [Bc, fitinfo] = combined_LASSO(snips, clus, good_clus, pks, "Name", value, ...);
arguments
    snips
    clus
    good_clus
    pks
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.7; % 0 --> RIDGE (conditioning noise identity matrix) | 1 --> LASSO (regularizer penalty on L2 weights)
    options.NumLambda (1,1) double {mustBeInteger, mustBePositive} = 20;
    options.Lambda = []; % seems 30-40 is a good value
end
i_all = ismember(clus, good_clus);
if isempty(options.Lambda)
    [Bc, fitinfo] = lasso(snips(i_all,:), pks(i_all), ...
        'Alpha', options.Alpha, ...
        'Standardize', false, ...
        'Intercept', false, ...
        'NumLambda', options.NumLambda);
else
    [Bc, fitinfo] = lasso(snips(i_all,:), pks(i_all), ...
        'Alpha', options.Alpha, ...
        'Standardize', false, ...
        'Intercept', false, ...
        'Lambda', options.Lambda);
end

end