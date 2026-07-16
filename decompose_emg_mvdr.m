function [units, residual, debug] = decompose_emg_mvdr(emg, fs, gestureMask, opts)
%DECOMPOSE_EMG_MVDR  Motor-unit spike decomposition from sEMG via SG denoise,
% candidate detection, PCA+kmeans clustering, selection, MVDR detection, and iterative peeling.
%
% Inputs
%   emg          (T x C) double, raw sEMG (time x channels)
%   fs           scalar, sampling rate (Hz)
%   gestureMask  (T x 1) logical, true when gestures are prompted (baseline = ~gestureMask)
%   opts         struct of options (all optional)
%
% Outputs
%   units(i).channel           - seed (real) channel index for group i
%   units(i).templateTC        - vectorized template (Twin x Cwin)
%   units(i).templateWindow    - struct with .tIdx (local time offsets), .cIdx (relative channel offsets)
%   units(i).score             - selection metric value
%   units(i).members           - indices of snapshots assigned to final cluster
%   units(i).mvdr_w            - MVDR filter vector
%   units(i).spikeTimes        - inferred spike times (sample indices, 1-based)
%   units(i).spikeAmps         - per-spike amplitude scales used for peeling
%   residual                   - emg after peeling all inferred spikes
%   debug                      - assorted intermediate data
%
% Dependencies: Statistics and Machine Learning Toolbox (kmeans, pca),
%               Signal Processing Toolbox (sgolayfilt), base MATLAB.

arguments
    emg (:,:) double
    fs (1,1) double {mustBePositive}
    gestureMask (:,1) logical
    opts.Geometry = []; 
    opts.SGOrder (1,1) double {mustBeInteger, mustBePositive} = 2
    opts.SGWindow (1,1) double {mustBeInteger, mustBePositive} = 21     % ~10 ms at 2 kHz
    opts.DetectWindowMs (1,1) double {mustBePositive} = 20
    opts.DetectQuantile (1,1) double {mustBeGreaterThanOrEqual(opts.DetectQuantile,0), mustBeLessThanOrEqual(opts.DetectQuantile,1)} = 0.50
    opts.DetectInterpSpatial (1,1) logical = true            % interpolate virtual channels between neighbors
    opts.SnapshotTwinMs (1,1) double {mustBePositive} = 20   % half-window
    opts.SnapshotCHalf (1,1) double {mustBeInteger, mustBeNonnegative} = 1
    opts.KmeansK (1,1) double {mustBeInteger, mustBePositive} = 20
    opts.KmeansMaxIter (1,1) double {mustBeInteger, mustBePositive} = 100
    opts.ClusterMinCount (1,1) double {mustBeInteger, mustBePositive} = 20
    opts.ClusterPeakTolSamples (1,1) double {mustBeInteger, mustBeNonnegative} = 2
    opts.ClusterMergeThresh (1,1) double {mustBePositive} = 0.05       % normalized distance
    opts.MaxUnitsPerIter (1,1) double {mustBeInteger, mustBePositive} = 20
    opts.MVDRThreshold (1,1) double {mustBePositive} = 0.7
    opts.MVDRShrinkage (1,1) double {mustBeGreaterThanOrEqual(opts.MVDRShrinkage,0)} = 1e-2
    opts.PeelingAmpRange (1,2) double = [0.9, 1.1]
    opts.RefineUpsample (1,1) double {mustBeInteger, mustBePositive} = 10
    opts.MaxTotalUnits (1,1) double {mustBeInteger, mustBePositive} = 20
    opts.StratifySeeds (1,1) logical = true
    opts.StrataZCenters (1,:) double = [0.2 0.4 0.6 0.8]
    opts.StrataPerBin (1,1) double {mustBeInteger,mustBePositive} = 5
    opts.StrataTol (1,1) double {mustBeNonnegative} = 0.07
    opts.SyncTauMs (1,1) double {mustBeNonnegative} = 3    % time tolerance for a “match”
    opts.SyncReject (1,1) double {mustBeGreaterThanOrEqual(opts.SyncReject,0), mustBeLessThanOrEqual(opts.SyncReject,1)} = 0.9

end

[T, C] = size(emg);
assert(numel(gestureMask)==T, 'gestureMask must have T elements.');
tauSamp = round(opts.SyncTauMs * 1e-3 * fs);

%% Part 0: SG smoothing (per-channel)
emg_sg = zeros(size(emg), 'like', emg);
for c = 1:C
    emg_sg(:,c) = sgolayfilt(emg(:,c), opts.SGOrder, opts.SGWindow);
end

% Baseline indices (for robust noise estimation and covariance)
baselineIdx = ~gestureMask;
if ~any(baselineIdx)
    % fallback to full record if baseline not provided
    baselineIdx = true(T,1);
end

%% Optional: spatial interpolation of channels (insert midpoints)
if opts.DetectInterpSpatial
    C2 = 2*C - 1;
    emg_ext = zeros(T, C2, 'like', emg);
    emg_ext(:,1:2:end) = emg_sg;
    emg_ext(:,2:2:end) = 0.5*(emg_sg(:,1:end-1) + emg_sg(:,2:end));
    chMapToReal = zeros(1, C2);      % <- double
    chMapToReal(1:2:end) = 1:C;
    chMapToReal(2:2:end) = 1:(C-1);
else
    emg_ext = emg_sg;
    chMapToReal = 1:C;               % <- double
end
chMapToReal = double(chMapToReal(:)); % ensure column double
Cext = size(emg_ext,2);

%% Part 1.1: Candidate detection (per extended channel)
wSamp = max(1, round(opts.DetectWindowMs*1e-3*fs));
th = quantile(abs(emg_ext), opts.DetectQuantile, 1);  % per-(extended)channel thresholds
isPk = false(T, Cext);

% Efficient local-maximum test via morphological max
for c = 1:Cext
    x = emg_ext(:,c);
    % local maxima in a window: compare to movmax and tie-break using sign/greater-than
    mm = movmax(x, [floor(wSamp/2) floor(wSamp/2)], 'Endpoints','discard');
    % align sizes
    padL = floor((length(x) - length(mm))/2);
    mm = [repmat(mm(1), padL,1); mm; repmat(mm(end), length(x)-length(mm)-padL, 1)];
    isPk(:,c) = (x == mm) & (abs(x) >= th(c));
end

% Force everything to be column vectors with matching height
[cand_t, cand_c_ext] = find(isPk);

cand_t      = cand_t(:);
cand_c_ext  = cand_c_ext(:);
cand_c_real = double(chMapToReal(cand_c_ext));
cand_c_real = cand_c_real(:);

if isempty(cand_t)
    units = struct([]); residual = emg_sg;
    debug = struct('candidates', table([], [], [], 'VariableNames', {'t','cExt','cReal'}));
    warning('No MUAP candidates found; returning early.');
    return
end

candidates = table(cand_t, cand_c_ext, cand_c_real, ...
                   'VariableNames', {'t','cExt','cReal'});


%% Part 1.2: Snapshot extraction and PCA (per group)
Twin = max(1, round(opts.SnapshotTwinMs*1e-3*fs));   % half window in samples
tRel = (-Twin: Twin).';                               % (Tloc x 1) double

snapshots = [];   % struct array
S = 0;

% Ensure candidates.cReal is double column
candidates.cReal = double(candidates.cReal(:));
% --- Stratified seeding by cylinder z ---
if opts.StratifySeeds
    % Pull per-channel z from geometry (robust to different field names)
    G = opts.Geometry;
    if     isfield(G,'chanZ'),     zPerCh = G.chanZ(:);
    elseif isfield(G,'zPerCh'),    zPerCh = G.zPerCh(:);
    elseif isfield(G,'Z'),         zPerCh = G.Z(:);
    elseif isfield(G,'z'),         zPerCh = G.z(:);
    else
        error('Geometry must include per-channel z (fields: chanZ/zPerCh/Z/z).');
    end
    zPerCh = double(zPerCh(:));
    C = size(emg,2);
    if numel(zPerCh) ~= C
        error('Geometry z-per-channel length (%d) must match #channels (%d).', numel(zPerCh), C);
    end

    % Only consider channels that actually produced candidates
    chWithCand = unique(candidates.cReal);     % real channels present
    % Rank channels by candidate count (you can swap in another ranking)
    counts = accumarray(candidates.cReal, 1, [C 1]);
    rankScore = counts;                         % higher is better

    % Build stratified list
    wantedTotal = numel(opts.StrataZCenters) * opts.StrataPerBin;
    picked = [];
    used   = false(C,1);

    for zc = opts.StrataZCenters(:).'
        inBinAll = find(abs(zPerCh - zc) <= opts.StrataTol);
        inBin    = intersect(inBinAll, chWithCand);   % channels with detections in this bin
        if isempty(inBin), continue; end

        % sort by rankScore (desc), then pick without replacement
        [~,ord] = sort(rankScore(inBin), 'descend');
        take = min(opts.StrataPerBin, numel(inBin));
        pick = inBin(ord(1:take));
        pick = pick(~used(pick));
        picked = [picked; pick(:)]; %#ok<AGROW>
        used(pick) = true;
    end

    % If we came up short (bins empty), fill from the remaining best channels globally
    if numel(picked) < wantedTotal
        remCh = setdiff(chWithCand, picked, 'stable');     % preserve stability a bit
        [~,ord] = sort(rankScore(remCh), 'descend');
        filler = remCh(ord(1:min(wantedTotal - numel(picked), numel(remCh))));
        picked = [picked; filler(:)];
    end

    % Final seeding list
    groups = picked(:).';
    if isempty(groups)
        groups = unique(candidates.cReal, 'stable');  % fallback
    end
else
    groups = unique(candidates.cReal, 'stable');
end

G = opts.Geometry;
K = opts.SnapshotCHalf*2 + 1;                  % keep your UI knob meaningful
K = min(K, size(G.neighIdx,2));                % clamp to precomputed K

for g = 1:numel(groups)
    c0 = double(groups(g));                           % seed channel (double scalar)

    % members in this group
    idxRows = find(candidates.cReal == c0);           % indices of candidates (column)
    if isempty(idxRows), continue; end

    % channel neighborhood, clamped to [1..C]
    cAbs = G.neighIdx(c0, 1:K);
    cAbs = cAbs(cAbs > 0);  
    if isempty(cAbs), continue; end

    Tloc = numel(tRel); 
    Cloc = numel(cAbs);

    Xg = zeros(numel(idxRows), Tloc*Cloc, 'like', emg);
    keep = true(numel(idxRows),1);

    for i = 1:numel(idxRows)
        t0 = candidates.t(idxRows(i));
        tt = t0 + tRel;
        if tt(1) < 1 || tt(end) > T
            keep(i) = false;  % discard border cases
            continue
        end
        % pull from ORIGINAL smoothed emg (not extended) for snapshot features
        patch = emg_sg(tt, cAbs);                      % (Tloc x Cloc)
        Xg(i,:) = patch(:).';
    end

    Xg = Xg(keep,:);
    idxRows = idxRows(keep);
    if size(Xg,1) < opts.ClusterMinCount
        continue
    end

    % PCA -> 3D per group
    [coeff, score, ~, ~, ~, mu] = pca(Xg, 'NumComponents', 3, 'Centered', true);

    % Store snapshots
    for i = 1:size(Xg,1)
        S = S + 1;
        snapshots(S).vec      = Xg(i,:);          
        snapshots(S).z        = score(i,:); %#ok<*AGROW>
        snapshots(S).groupCh  = c0;
        snapshots(S).t        = candidates.t(idxRows(i));
        snapshots(S).cAbs     = cAbs;
        snapshots(S).tRel     = tRel;
        snapshots(S).Cloc     = Cloc;
        snapshots(S).Tloc     = Tloc;
        snapshots(S).pca_mu   = mu;
        snapshots(S).pca_coef = coeff;
    end
end

if isempty(snapshots)
    units = struct([]); residual = emg_sg; debug = struct('candidates',candidates);
    warning('No snapshots collected; returning early.');
    return
end

%% Part 1.3: K-means (per group channel), templates, and post-processing
% Organize per group:
snapTbl = struct2table(snapshots);
ug = unique(snapTbl.groupCh);

clusters = struct( ...            % empty struct with expected fields
    'groupCh', {}, ...
    'members', {}, ...
    'templateVec', {}, ...
    'Tloc', {}, ...
    'Cloc', {}, ...
    'cAbs', {}, ...
    'tRel', {}, ...
    'snr', {}, ...
    'score', {} );

for ii = 1:numel(ug)
    c0 = ug(ii);
    idx = find(snapTbl.groupCh==c0);
    Z = vertcat(snapshots(idx).z);     % (N x 3)

    if size(Z,1) < opts.KmeansK
        K = max(1, min(opts.KmeansK, size(Z,1)));
    else
        K = opts.KmeansK;
    end
    if K==1
        Cidx = ones(size(Z,1),1);
    else
        Cidx = kmeans(Z, K, 'MaxIter',opts.KmeansMaxIter, 'Replicates',3, 'OnlinePhase','on');
    end

    % Build clusters and templates
    for k = 1:K
        mem = idx(Cidx==k);
        if numel(mem) < opts.ClusterMinCount, continue; end

        V = vertcat(snapshots(mem).vec);          % (n_k x (Tloc*Cloc))
        tmpl = mean(V,1);                         % template (vectorized)
        % SNR via robust baseline
        noiseScale = robust_noise_scale(emg_sg(baselineIdx,:), 'abs_mad');
        tmpl_snr = (max(tmpl)-min(tmpl)) / noiseScale;

        % Peak alignment filter
        % compare within-window peak time per member vs template peak
        Tloc = snapshots(mem(1)).Tloc; Cloc = snapshots(mem(1)).Cloc;
        [~, pkTmpl] = max(abs(reshape(tmpl, Tloc, Cloc)), [], 1);
        pkTmpl = median(pkTmpl); % a single representative position
        keep2 = true(numel(mem),1);
        for j = 1:numel(mem)
            v = snapshots(mem(j)).vec;
            [~, pk] = max(abs(reshape(v, Tloc, Cloc)), [], 1);
            pk = median(pk);
            if abs(pk - pkTmpl) > opts.ClusterPeakTolSamples
                keep2(j) = false;
            end
        end
        mem = mem(keep2);
        if numel(mem) < opts.ClusterMinCount, continue; end

        % Store preliminary cluster
        cl = struct;
        cl.groupCh     = c0;
        cl.members     = mem(:).';
        cl.templateVec = mean(vertcat(snapshots(mem).vec),1);
        cl.Tloc        = snapshots(mem(1)).Tloc;
        cl.Cloc        = snapshots(mem(1)).Cloc;
        cl.cAbs        = snapshots(mem(1)).cAbs;
        cl.tRel        = snapshots(mem(1)).tRel;
        cl.snr         = tmpl_snr;
        cl.score       = nan;
        clusters = [clusters; cl]; 
    end
end

% Merge clusters iteratively using normalized distance
clusters = merge_clusters(clusters, opts.ClusterMergeThresh);

% Remove tiny clusters post-merge
clusters = clusters(arrayfun(@(c) numel(c.members)>=opts.ClusterMinCount, clusters));

% If nothing survived, return gracefully
if isempty(clusters)
    units = struct([]); 
    residual = emg_sg; 
    debug = struct();
    debug.candidates = candidates;
    if exist('snapTbl','var') == 1 && ~isempty(snapshots)
        debug.snapshotsTable = snapTbl;
    else
        debug.snapshotsTable = table();   % or [] if you prefer
    end

    debug.clusters = clusters;
    debug.opts = opts;
    warning('No clusters after post-processing; returning early.');
    return
end

% Selection score per cluster:
for i = 1:numel(clusters)
    mem = clusters(i).members;
    Xk  = vertcat(snapshots(mem).vec);        % (n_k x D)
    med = median(Xk,1);
    s   = std(Xk,0,1);
    clusters(i).score = (sum(abs(med)) * size(Xk,1)) / sum(abs(sqrt(max(s,eps))));
end

% Rank clusters and keep up to MaxUnitsPerIter

if isempty(clusters)
    units = struct([]); residual = emg_sg;
    debug = struct('candidates',candidates,'snapshotsTable',snapTbl,'clusters',clusters,'opts',opts);
    warning('No clusters scored; returning early.');
    return
end

scores = [clusters.score];
% Precompute per-cluster anchor channel (the group's real channel)
anchor = [clusters.groupCh];

% Penalty knobs (tune these)
alpha_same_anchor = 0.50;   % penalty if same anchor channel as already picked
beta_overlap      = 0.25;   % penalty per fraction of channel-window overlap
gamma_count_decay = 0.15;   % extra penalty per additional unit on same anchor

picked = false(1, numel(clusters));
sel = [];                                % indices of clusters we keep
usedAnchors = containers.Map('KeyType','double','ValueType','double');

% Helper to compute channel-overlap fraction
overlapFrac = @(a,b) numel(intersect(a,b)) / max(1, numel(union(a,b)));

while numel(sel) < min(opts.MaxUnitsPerIter, numel(clusters))
    bestIdx = 0; bestScore = -inf;

    for i = 1:numel(clusters)
        if picked(i), continue; end

        sc = scores(i);

        % Penalize reusing the same anchor channel
        if isKey(usedAnchors, anchor(i))
            k = usedAnchors(anchor(i));
            sc = sc * (1 - alpha_same_anchor) * (1 - gamma_count_decay)^k;
        end

        % Penalize spatial overlap with already selected clusters
        for jj = sel
            o = overlapFrac(clusters(i).cAbs, clusters(jj).cAbs);
            if o > 0
                sc = sc * (1 - beta_overlap * o);
            end
        end

        if sc > bestScore
            bestScore = sc; bestIdx = i;
        end
    end

    if bestIdx == 0 || ~isfinite(bestScore)
        break
    end
    sel(end+1) = bestIdx; 
    picked(bestIdx) = true;
    if ~isKey(usedAnchors, anchor(bestIdx))
        usedAnchors(anchor(bestIdx)) = 1;
    else
        usedAnchors(anchor(bestIdx)) = usedAnchors(anchor(bestIdx)) + 1;
    end
end

clusters = clusters(sel);
maxPerAnchor = 2;   % e.g., at most 2 units per real seed channel
counts = containers.Map('KeyType','double','ValueType','double');

keep = true(1, numel(clusters));
for i = 1:numel(clusters)
    a = clusters(i).groupCh;
    if ~isKey(counts,a), counts(a)=0; end
    if counts(a) >= maxPerAnchor
        keep(i) = false;
    else
        counts(a) = counts(a) + 1;
    end
end
clusters = clusters(keep);

%% Part 2: MVDR detection per selected cluster, with sequential peeling
residual = emg_sg; % start from denoised signal
units = struct([]);
unitCount = 0;

% Order by L2 norm of template (descending)
tmplL2 = arrayfun(@(c) norm(c.templateVec,2), clusters);
[~, ord2] = sort(tmplL2, 'descend');
clusters = clusters(ord2);

for ci = 1:numel(clusters)
    if unitCount >= opts.MaxTotalUnits, break; end
    cl = clusters(ci);

    % Estimate noise covariance from baseline snapshots with same (tRel x cAbs) window
    [Sigma, ok] = estimate_noise_cov(residual, baselineIdx, cl.tRel, cl.cAbs);
    if ~ok
        % simple diagonal fallback
        Sigma = eye(numel(cl.templateVec)) * var(residual(baselineIdx,:), 0, 'all');
    end
    % shrinkage
    Sigma = Sigma + opts.MVDRShrinkage * trace(Sigma)/numel(cl.templateVec) * eye(size(Sigma));

    xk = cl.templateVec(:);
    denom = max(xk'*(Sigma\xk), eps);
    wk = (Sigma\xk) / denom;              % MVDR weights (vectorized window)

    % Slide MVDR over the full record on the same (local) window around each time
    y = apply_sliding_mvdr(residual, wk, cl.tRel, cl.cAbs);

    % Detect peaks > threshold
    cand = y;
    cand(isnan(cand)) = 0;
    thr = opts.MVDRThreshold;
    ispk = islocalmax(cand) & (cand >= thr);
    spikeTimes = find(ispk(:));
    if isempty(spikeTimes)
        continue
    end

    isDuplicate = false;
    for j = 1:numel(units)    % compare against already-accepted units
        best = 0;
        for lag = -2:2
            best = max(best, spike_synchrony(spikeTimes + lag, units(j).spikeTimes, tauSamp));
        end
        if best > opts.SyncReject, isDuplicate = true; break; end
    end
    if isDuplicate
        % Skip this cluster; it’s too synchronized with an existing unit
        continue
    end

    % Peeling with amplitude estimation + optional timing refinement
    [residual, spikeTimes, spikeAmps] = peel_unit(residual, spikeTimes, xk, cl.tRel, cl.cAbs, ...
        'AmpRange', opts.PeelingAmpRange, ...
        'Upsample', opts.RefineUpsample);

    % Store
    unitCount = unitCount + 1;
    units(unitCount).channel        = cl.groupCh;
    units(unitCount).templateTC     = xk;
    units(unitCount).templateWindow = struct('tIdx', cl.tRel, 'cIdx', cl.cAbs);
    units(unitCount).score          = cl.score;
    units(unitCount).members        = cl.members;
    units(unitCount).mvdr_w         = wk;
    units(unitCount).spikeTimes     = spikeTimes(:);
    units(unitCount).spikeAmps      = spikeAmps(:);
end

%% Debug info
debug = struct();
debug.candidates = candidates;
debug.snapshotsTable = snapTbl;
debug.clusters = clusters;
debug.opts = opts;

end % === main function ===

% === Helper functions ===============================================

function s = robust_noise_scale(X, mode)
% scalar robust noise scale from (T x C) data
    if nargin < 2, mode = 'abs_mad'; end
    switch mode
        case 'abs_mad'
            s = 1.4826 * median(median(abs(X),1),2);
        otherwise
            s = std(X,0,'all');
    end
end

function clusters = merge_clusters(clusters, thr)
% Iteratively merge cluster templates if normalized distance < thr
    if numel(clusters)<=1, return; end
    % Precompute vector templates
    T = cellfun(@(v) v(:), {clusters.templateVec}, 'uni', 0);
    T = cat(2, T{:});
    active = true(1, numel(clusters));

    while true
        idx = find(active);
        if numel(idx)<=1, break; end
        % pairwise normalized distances
        D = inf(numel(idx));
        norms = sqrt(sum(T(:,idx).^2,1));
        for a = 1:numel(idx)
            for b = a+1:numel(idx)
                da = T(:,idx(a)) - T(:,idx(b));
                D(a,b) = norm(da,2) / (0.5*(norms(a)+norms(b)) + eps);
            end
        end
        [minVal, pos] = min(D(:));
        if ~isfinite(minVal) || minVal >= thr, break; end
        [ia, ib] = ind2sub(size(D), pos);
        A = idx(ia); B = idx(ib);

        % merge B into A
        clusters(A).members = [clusters(A).members, clusters(B).members];
        % re-average template
        % NOTE: members may come from different local windows only if grouping differs; here they share same group
        V = vertcat(clusters(A).templateVec, clusters(B).templateVec); %#ok<NASGU>
        % Better: recompute from all snapshots if accessible — here we average templates:
        clusters(A).templateVec = (clusters(A).templateVec + clusters(B).templateVec)/2;
        active(B) = false;

        % update T
        T(:,A) = clusters(A).templateVec(:);
    end

    clusters = clusters(active);
end

function [Sigma, ok] = estimate_noise_cov(X, baselineIdx, tRel, cAbs)
% Build covariance of vectorized (Tloc x Cloc) windows sampled from baseline
    ok = true;
    Tloc = numel(tRel); Cloc = numel(cAbs);
    D = Tloc*Cloc;

    % pick a modest number of baseline windows spread out
    idxT = find(baselineIdx);
    if numel(idxT) < 3*Tloc
        ok = false;
        Sigma = eye(D);
        return
    end
    % stride sampling to avoid strong overlap
    stride = max(1, floor(Tloc/2));
    centers = idxT(idxT > (1+Tloc) & idxT < (size(X,1)-Tloc));
    centers = centers(1:stride:end);
    if numel(centers) < 20
        ok = false; Sigma = eye(D); return;
    end

    M = min(200, numel(centers));
    centers = centers(randperm(numel(centers), M));

    W = zeros(M, D, 'like', X);
    for i = 1:M
        tt = centers(i) + tRel;
        patch = X(tt, cAbs);
        W(i,:) = patch(:).';
    end
    % covariance (centered)
    Wc = W - mean(W,1);
    Sigma = (Wc.' * Wc) / max(M-1,1);
end

function y = apply_sliding_mvdr(X, w, tRel, cAbs)
% Slide MVDR weights over time; returns a length T vector of detection scores
    [T, ~] = size(X);
    y = nan(T,1);
    for t = 1:T
        tt = t + tRel;
        if tt(1) < 1 || tt(end) > T
            continue
        end
        patch = X(tt, cAbs); % (Tloc x Cloc)
        y(t) = w' * patch(:);
    end
end

function [Xres, spikeTimesOut, ampsOut] = peel_unit(X, spikeTimes, xk, tRel, cAbs, varargin)
% Subtract scaled template copies at detected spikes with timing refinement
    p = inputParser;
    addParameter(p, 'AmpRange', [0.9, 1.1]);
    addParameter(p, 'Upsample', 10);
    parse(p, varargin{:});
    ampRange = p.Results.AmpRange;
    up = p.Results.Upsample;

    Xres = X;
    ampsOut = zeros(numel(spikeTimes),1);
    spikeTimesOut = zeros(numel(spikeTimes),1);
    T = size(X,1);
    Tloc = numel(tRel);
    xkTC = reshape(xk, Tloc, []); % (Tloc x Cloc)

    for i = 1:numel(spikeTimes)
        t0 = spikeTimes(i);
        tt = t0 + tRel;
        if tt(1) < 1 || tt(end) > T, continue; end

        patch = Xres(tt, cAbs);  % (Tloc x Cloc)

        % timing refinement by temporal upsampling per channel
        % build a finer grid around t0 (±2 samples by default)
        tFineRel = linspace(tRel(1), tRel(end), up*Tloc); % fractional samples
        patchFine = zeros(numel(tFineRel), size(patch,2));
        for cc = 1:size(patch,2)
            patchFine(:,cc) = interp1(tRel, patch(:,cc), tFineRel, 'spline', 'extrap');
        end
        xkFine = zeros(size(patchFine));
        for cc = 1:size(patch,2)
            xkFine(:,cc) = interp1(tRel, xkTC(:,cc), tFineRel, 'spline', 'extrap');
        end
        % choose offset maximizing normalized inner product
        yFine = zeros(numel(tFineRel)-Tloc+1,1);
        for off = 1:numel(yFine)
            seg = patchFine(off:off+Tloc-1,:);
            yFine(off) = dot(seg(:), xk(:)) / (norm(seg(:))+eps) ;
        end
        [~, bestOff] = max(yFine);
        % map back to nearest integer time shift
        centerShift = round((bestOff-1) / up);
        t0r = t0 + centerShift;

        % recompute with refined time
        tt = t0r + tRel;
        if tt(1) < 1 || tt(end) > T, continue; end
        seg = Xres(tt, cAbs);
        a = dot(seg(:), xk) / (dot(xk, xk) + eps);
        if a < ampRange(1) || a > ampRange(2)
            a = 1.0; % use unscaled subtraction if outside range
        end
        % subtract
        Xres(tt, cAbs) = seg - a * reshape(xk, Tloc, []);
        ampsOut(i) = a;
        spikeTimesOut(i) = t0r;
    end

    % cleanup NaNs (if any were skipped)
    spikeTimesOut = spikeTimesOut(spikeTimesOut>0);
    ampsOut = ampsOut(1:numel(spikeTimesOut));
end
