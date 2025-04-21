function zdata = fast_proj_eig_dr(edata, extFact, epsilon, nComp, nDrop)
%FAST_PROJ_EIG_DR Dimensionality-reduced whitening via eig-decomposition
%
% Inputs:
%   edata   - (M x N) matrix, where M is channels, N is timepoints
%   extFact - number of causal and anticausal samples for feature expansion
%   epsilon - regularization parameter (small scalar)
%   nComp   - number of eigenvectors to retain (dimensionality reduction)
%   nDrop   - number of first eigenvectors to drop (0 does not drop)
%
% Output:
%   zdata   - whitened and projected data

arguments
    edata
    extFact (1,1) {mustBePositive, mustBeInteger} = 18;
    epsilon (1,1) {mustBePositive} = 5;
    nComp (1,1) {mustBePositive, mustBeInteger} = 16;
    nDrop (1,1) {mustBeInteger} = 1;
end

Rw = (edata * edata') / (size(edata, 2) - 1);
[V, D] = eig(Rw);

% Sort eigenvalues (descending) and reduce dimension
[d, idx] = sort(diag(D), 'descend');
V = V(:, idx((1+nDrop):nComp));
D = sqrt(d((1+nDrop):nComp) + epsilon);
W = diag(1./sqrt(D));

Pw = V * W * V';
zdata = V * D .* Pw * edata(:, (extFact+1):(end-extFact+1));
end
