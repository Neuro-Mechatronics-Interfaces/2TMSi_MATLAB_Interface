function [Pw, V, lambda, Z] = dual_whitening(X, nDrop, nComp, epsilon)
%DUAL_WHITENING Computes ZCA-style whitening using dual (sample) space
%
% Inputs:
%   X       - (D x N) matrix of extended vectors (D = M * extFact)
%   nDrop   - Number of principal components to drop
%   nComp   - number of principal components to retain (<= N)
%   epsilon - small scalar for regularization (default = 1e-6)
%
% Outputs:
%   Pw      - (D x D) whitening projection matrix (ZCA-style)
%   V       - (D x nComp) whitened basis vectors
%   lambda  - (nComp x 1) eigenvalues of selected components
%   Z       - (nComp x N) whitened coefficients in eigenspace (optional)
%
% Notes:
%   - Applies whitening in the high-dimensional space using
%     eigen-decomposition of the dual covariance (N x N)
%   - V * V' acts as the whitening transform in original space

arguments
    X (:,:) double
    nDrop (1,1) {mustBeInteger}
    nComp (1,1) {mustBePositive, mustBeInteger}
    epsilon (1,1) double = 1e-6
end

[D, N] = size(X);
assert((nDrop+nComp)<=N);

% Center the data
Xc = X - mean(X, 2);

% Step 1: Compute dual covariance (N x N)
C_dual = (Xc') * Xc / (N - 1);

% Step 2: Eigen-decomposition in sample space
[U, S] = eig(C_dual);
[lambda_all, idx] = sort(diag(S), 'descend');
lambda = lambda_all((nDrop+1):(nDrop+nComp));
U = U(:, idx((nDrop+1):(nDrop+nComp)));  % keep top nComp eigenvectors

% Step 3: Map to original feature space (D x nComp)
V = Xc * U * diag(1 ./ sqrt(lambda + epsilon));  % Whitening directions

% Step 4: Whitening projection matrix (D x D)
Pw = V * V';

% Optional: whitened coefficients in reduced space (nComp x N)
if nargout > 3
    Z = V' * Xc;
end
end
