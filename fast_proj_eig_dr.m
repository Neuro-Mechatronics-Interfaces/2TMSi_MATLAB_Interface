function [zdata, Pw] = fast_proj_eig_dr(edata, Pw, extFact, alpha, epsilon, nComp, nDrop)
%FAST_PROJ_EIG_DR - Dimensionality-reduced whitening with EMA-updated Pw
%
% Inputs:
%   edata   - (M x N) data matrix (channels x timepoints)
%   Pw      - previous projection matrix
%   extFact - causal extension for time-window alignment
%   alpha   - update blending factor (0 = no update, 1 = full update)
%   epsilon - regularization constant added to eigenvalues
%   nComp   - number of eigenvectors to retain
%   nDrop   - number of eigenvectors to skip (e.g., drop DC or noise)

arguments
    edata
    Pw (:,:) double
    extFact (1,1) {mustBePositive, mustBeInteger} = 18
    alpha (1,1) double = 0.2
    epsilon (1,1) {mustBePositive} = 5
    nComp (1,1) {mustBePositive, mustBeInteger} = 8
    nDrop (1,1) {mustBeInteger} = 1
end

% Step 1: Covariance and eigendecomposition
Rw = (edata * edata') / (size(edata, 2) - 1);
[V, D] = eig(Rw);
[d, idx] = sort(diag(D), 'descend');

% Step 2: Basis selection
d_sel = d((1 + nDrop):(nDrop + nComp));
V_sel = V(:, idx((1 + nDrop):(nDrop + nComp)));

% Step 3: Whitening projection matrix (ZCA style)
W_white = diag(1 ./ sqrt(d_sel + epsilon));
P_new = V_sel * W_white * V_sel';   % this whitens the signal

% Step 4: Channel-wise rescaling to match original amplitudes
edata_whitened = P_new * edata;
gain = std(edata, 0, 2) ./ (std(edata_whitened, 0, 2) + eps);  % (M x 1)
R = diag(gain);

P_new_scaled = R * P_new;  % whitened + amplitude-matched

% Step 5: Exponential moving average update of Pw
Pw = (1 - alpha) * Pw + alpha * P_new_scaled;

% Step 6: Apply whitening+rescaling to delayed window
zdata = Pw * edata(:, (extFact+1):(end-extFact+1));
end
