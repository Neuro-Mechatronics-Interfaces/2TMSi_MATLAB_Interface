function [mu, W] = zca_fit_once(X, eps_abs, shrink)
%ZCA_FIT_ONCE  Compute ZCA (symmetric) whitening matrix from baseline X.
%   X: (N x C), rows = time, columns = channels
%   eps_abs: absolute Tikhonov floor (typ. 1e-5)
%   shrink:  small shrinkage toward identity (typ. 1e-2)

arguments
    X (:,:) double
    eps_abs (1,1) double {mustBeNonnegative} = 1e-5
    shrink (1,1) double {mustBeGreaterThanOrEqual(shrink,0)} = 1e-2
end
% center
mu = mean(X,1);                  % (1 x C)
Xc = X - mu;                     % (N x C)

% covariance (population) and shrinkage
C = (Xc.'*Xc) / max(size(Xc,1),1);   % (C x C)
avg_var = mean(diag(C));
C = (1 - shrink)*C + shrink*avg_var*eye(size(C));

% relative floor based on spectrum scale + absolute floor
eps_rel = 1e-6 * avg_var;
C = C + (eps_rel + eps_abs)*eye(size(C));

% eigendecomposition (C is SPD after floors)
[U,S] = eig(C,'vector');         % S: eigenvalues (C x 1)
% guard against tiny/negative numerical eigenvalues
S(S < 0) = 0;
inv_sqrt = 1./sqrt(S + eps_abs);
W = U * (inv_sqrt .* U.');       % ZCA whitening: symmetric W, so x_white = W*(x - mu).'

% For block rows: (X - mu) * W'
% (we return W so caller can do that efficiently)
end
