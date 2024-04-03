function [B,fitinfo] = iterative_LASSO(data, snips, idx, clus, good_clus, options)
%ITERATIVE_LASSO Runs iterative LASSO procedure to estimate betas for model kernel.
%
% Syntax:
%   [B,fitinfo] = iterative_LASSO(data, snips, idx, good_clus, "Name", value, ...);
arguments
    data
    snips
    idx
    clus
    good_clus
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.7; % 0 --> RIDGE (conditioning noise identity matrix) | 1 --> LASSO (regularizer penalty on L2 weights)
    options.CVFolds (1,1) double {mustBePositive, mustBeInteger} = 6;
    options.NFiltersMax (1,1) double = inf;
    options.ControlSampleScalar (1,1) double = 0.5;
    options.ControlTimeVector (1,:) {mustBeInteger} = -10:10;
    options.NumLambda (1,1) double {mustBeInteger, mustBePositive} = 100;
    options.Verbose (1,1) logical = true;
end
nToFit = min(numel(good_clus),options.NFiltersMax);
B = cell(nToFit,1);
fitinfo = cell(nToFit,1);
uni_ch = find(startsWith({data.channels.alternative_name},'UNI'));
if options.Verbose
    fprintf(1,'Please wait, fitting %d iterative LASSO kernels...000%%\n', nToFit);
end
for ii = 1:nToFit
    i_cur = clus == good_clus(ii);
    n_cur = sum(i_cur);
    nControlSamples = round(options.ControlSampleScalar*n_cur);
    conSnips = uni_2_extended_ctrl(data.samples(uni_ch,:),idx(i_cur), nControlSamples, ...
        'Vector',options.ControlTimeVector);
    nConSamplesActual = size(conSnips,1);
    [B{ii},fitinfo{ii}] = lasso([conSnips; snips(i_cur,:)], [zeros(nConSamplesActual,1); ones(n_cur,1)], ...
        'Alpha', options.Alpha, ...
        'CV', options.CVFolds, ...
        'NumLambda', options.NumLambda);
    if options.Verbose
        fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*ii/nToFit));
    end
end

end