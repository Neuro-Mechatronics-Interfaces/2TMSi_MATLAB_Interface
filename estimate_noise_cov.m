function [Sigma, ok] = estimate_noise_cov(X, baselineMask, tRel, cAbs)
%ESTIMATE_NOISE_COV Estimates noise covariance but only for the channels specified in cAbs.
%
% Syntax:
%   [Sigma, ok] = estimate_noise_cov(X, baselineMask, tRel, cAbs);
%
% Build covariance of vectorized (Tloc x Cloc) windows sampled from baseline.
% X: (T x C), baselineMask: (T x 1) logical (true = baseline)
ok = true;
[T, ~] = size(X);
tRel = tRel(:); cAbs = cAbs(:);
Tloc = numel(tRel); Cloc = numel(cAbs);
D = Tloc*Cloc;

idxT = find(baselineMask);
if numel(idxT) < 3*Tloc
    ok = false; Sigma = eye(D); return;
end

% pick centers well inside bounds
centers = idxT(idxT > (1+Tloc) & idxT < (T-Tloc));
if isempty(centers)
    ok = false; Sigma = eye(D); return;
end

% stride to reduce overlap, cap count
stride  = max(1, floor(Tloc/2));
centers = centers(1:stride:end);
if numel(centers) < 20
    ok = false; Sigma = eye(D); return;
end
M = min(200, numel(centers));
centers = centers(randperm(numel(centers), M));

W = zeros(M, D, 'like', X);
for i = 1:M
    tt = centers(i) + tRel;
    patch = X(tt, cAbs);          % (Tloc x Cloc)
    W(i,:) = patch(:).';
end

% zero-mean covariance
Wc = W - mean(W,1);
Sigma = (Wc.' * Wc) / max(M-1,1);
end
