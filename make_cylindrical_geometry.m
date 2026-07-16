function G = make_cylindrical_geometry(theta_elec, z_elec, K, R, alpha)
%MAKE_CYLINDRICAL_GEOMETRY G = make_cylindrical_geometry(theta_elec, z_elec, K, R, alpha); Makes cylindrical geometry using input theta_elec, z_elec (matched to electrodes), specifying K nearest neighbors per electrode and assuming default radius of 1 with alpha specifying ratio between radius and "vertical" scale (i.e. ratio of arm length to radius). 
%
% Inputs:
% theta_elec : Cx1 angles in radians (0..2π or −π..π both ok)
% Z_EL       : Cx1 axial positions (any units; you can rescale)
% K          : neighbors per channel for snapshots (e.g., 3–5)
% R          : cylinder radius (use 1)
% alpha      : axial-vs-angular weighting (dz effective scale). Start ~1–2.

theta_elec = theta_elec(:);
z_elec     = z_elec(:);
C = numel(theta_elec);

% wrap-aware angular diffs
% Δθ ∈ [0, π] using shortest arc
dtheta = abs(theta_elec - theta_elec.');
dtheta = min(dtheta, 2*pi - dtheta);

% axial diffs
dz = abs(z_elec - z_elec.');

% cylinder (geodesic-like) distance
% lateral distance = R*Δθ; axial scaled by alpha
D = sqrt( (R*dtheta).^2 + (alpha*dz).^2 );   % C x C, symmetric

% K nearest neighbors for each channel (include self first)
neighIdx = zeros(C, K);
neighDist = zeros(C, K);
for c = 1:C
    [d, ord] = sort(D(c,:),'ascend');
    ktake = min(K, numel(ord));
    neighIdx(c,1:ktake)  = ord(1:ktake);
    neighDist(c,1:ktake) = d(1:ktake);
end

% Optional normalized Gaussian weights per channel over its K-NN
% (nice for spatial smoothing / virtual channels)
sigma = median(neighDist(neighDist>0),'all');   % crude scale
if isempty(sigma) || sigma==0, sigma = 1; end
W = zeros(C, C);
for c = 1:C
    idx = neighIdx(c, :); idx = idx(idx>0);
    d   = D(c, idx);
    w   = exp(-0.5*(d/sigma).^2);
    w   = w / sum(w);
    W(c, idx) = w;
end

G = struct('theta',theta_elec,'z',z_elec,'C',C,'R',R,'alpha',alpha, ...
    'D',D,'neighIdx',neighIdx,'neighDist',neighDist,'W',W);
end
