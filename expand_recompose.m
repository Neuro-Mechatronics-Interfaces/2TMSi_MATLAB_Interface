function [Wnew,Hnew] = expand_recompose(Y,W0,H0,options)
arguments
    Y
    W0
    H0
    options.MinEncodingPower = 1e-5;
    options.MaxComponentRatio = 0.5;
    options.RegularizerAlpha (1,1) double = 10;
    options.Verbose (1,1) logical = true;
end
if options.Verbose
    tic;
end
% Set up the regularizer constraints and solver options
constraints = @(W)deal(expand_recompose_nlcons(W, options.RegularizerAlpha, true));
if options.Verbose
    dispopt = 'iter';
else
    dispopt = 'off';
end
opts = optimoptions('fmincon','Algorithm', ...
    'interior-point', ...
    'Display',dispopt);

% Use a constrained minimization to get the best reconstruction of Y using
% the nonnegative encodings in H, so that we have a new basis for fitting
% Y. During this optimization, add a sparsity constraint to W (see
% `expand_recompose_nlcons`) and a nonnegativity constraint to W as well. 
%
% Note that here, we do not require 
Wnew = fmincon(@(W)norm(Y-W*H0,'fro')^2, W0, ...
    [],[],[],[],[],[],constraints,opts);

% Now that we have recovered Wnew, use it to recover Hnew using a
% nonnegativity constraint only (for H). 
Hnew = lsqnonneg_matrix(Y,Wnew);
if options.Verbose
    toc;
end
end