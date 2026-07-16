%EXAMPLE_PLAYBACK_SINGLE_POLY5_FILE_ZCA Example showing fast playback and broadcast of MUAPs from Poly5 file with ZCA whitening
clear;
close all force;
clc;

% SAGA_UNIT = 'SAGAB';
% MY_FILE = fullfile(pwd,'MCP04_2025_01_23_B_DIST_2.poly5');
SAGA_UNIT = 'SAGAA';
MY_FILE = fullfile(pwd,'MCP04_2025_01_23_A_PROX_1.poly5');
LAYOUT = textile_8x8_uni2grid_mapping();
LAYOUT = LAYOUT([1:32, 57:64, 49:56, 41:48, 33:40]);
THETA_EL = [repmat(linspace(pi/2-pi/8,-pi/2+pi/8,8)',1,4), ...
    repmat(linspace(pi/2+pi/8,3*pi/2-pi/8,8)',1,4)];
THETA_EL = THETA_EL(:);
Z_EL = ones(8,1)*[0.2, 0.4, 0.6, 0.8, 0.2, 0.4, 0.6, 0.8];
Z_EL = Z_EL(:);
Ksnapshot = 3;           % how many channels per snapshot
G = make_cylindrical_geometry(THETA_EL, Z_EL, Ksnapshot, 1.0, 1.0);
TRIGS_CH = 68;
TRIG_BIT = 1;
ALGORITHMIC_LATENCY_ESTIMATE = 0.010; % seconds
SAMPLE_DELAY_LIM = [0.0025, 0.010]; % Pause will be at least this many seconds
LINE_VERTICAL_OFFSET = 4; % microvolts
HORIZONTAL_SCALE = 0.25; % seconds
SAMPLE_RATE_RECORDING = 2000;
RASTER_Y_FRAC = 0.25;  % where to place tick within that channel band (0..1 from baseline to next band)

% --- ZCA whitening config ---
ZCA = struct;
ZCA.ENABLE              = true;
ZCA.CAL_SECS            = 15.0;     % collect ~5 s of baseline for calibration
ZCA.EPS                 = 1e-5;    % Tikhonov floor (relative floor also used inside)
ZCA.SHRINK              = 1e-2;    % small covariance shrinkage toward identity
ZCA.USE_TRIGGER_BASELINE= false;    % use trigger LOW as baseline; else use whole stream
ZCA.READY               = false;   % becomes true after calibration
ZCA.mu                  = [];      % (1 x C)
ZCA.W                   = [];      % (C x C) whitening matrix
ZCA.nNeeded             = round(ZCA.CAL_SECS*SAMPLE_RATE_RECORDING);
ZCA.buf                 = zeros(0, 64, 'like', 0.0); % will grow until nNeeded rows

% --- Online decomposition config ---
DECOMP.ENABLE           = true;
DECOMP.MAX_UNITS        = 20;     % cap total units to track
DECOMP.TWIN_MS          = 20;     % match your function’s default
DECOMP.CHALF            = 2;      % ±2 channels
DECOMP.THRESH           = 0.75;   % MVDR threshold
DECOMP.COLORSET         = hot(DECOMP.MAX_UNITS);
DECOMP.trainSamp        = round(30 * SAMPLE_RATE_RECORDING);

% state
DSTATE.buf              = zeros(0, 64, 'like', 0.0);
DSTATE.mask             = false(0, 1);
DSTATE.absStartIdx      = 0;                 % absolute sample index for DSTATE.buf(1,:)
DSTATE.lastRunAbsIdx    = 0;
DSTATE.units            = struct([]);        % filled with decompose results
DSTATE.unitColors       = DECOMP.COLORSET;
DSTATE.fs               = SAMPLE_RATE_RECORDING;
DSTATE.trained          = false;
DSTATE.emittedSpk   = cell(DECOMP.MAX_UNITS,1);  % absolute sample indices already emitted per unit
DSTATE.mvdrW        = {};                        % {u} column vectors w_k
DSTATE.tRelPerU     = {};                        % {u} tRel
DSTATE.cIdxPerU     = {};                        % {u} channel index vector (cAbs)

opts = struct;
opts.Geometry = G;
opts.SGOrder = 2;
opts.SGWindow = 15;
opts.DetectWindowMs = 20;
opts.DetectQuantile = 0.50;
opts.DetectInterpSpatial = false;
opts.SnapshotTwinMs = DECOMP.TWIN_MS;
opts.SnapshotCHalf = DECOMP.CHALF;
opts.KmeansK = 20;
opts.KmeansMaxIter = 100;
opts.ClusterMinCount = 20;
opts.ClusterPeakTolSamples = 2;
opts.ClusterMergeThresh = 0.05;
opts.MaxUnitsPerIter = min(20, DECOMP.MAX_UNITS);
opts.MVDRThreshold = DECOMP.THRESH;
opts.MVDRShrinkage = 1e-2;
opts.PeelingAmpRange = [0.9 1.1];
opts.RefineUpsample = 10;
opts.MaxTotalUnits = min(20, DECOMP.MAX_UNITS);
opts.SyncTauMs = 3;
opts.SyncReject = 0.9;
opts.RefracMs = 20;
opts.StratifySeeds = true;
opts.StrataZCenters = [0.2 0.4 0.6 0.8];
opts.StrataPerBin = 5;
opts.StrataTol = 0.07;

%% Open file and estimate scaling/offsets
% Open Poly5 file for reading:
poly5 = TMSiSAGA.Poly5(MY_FILE, SAMPLE_RATE_RECORDING, [], 'r');

% Estimate how long to pause between each read iteration:
sample_delay = round(min(max(poly5.header.num_samples_per_block*2/poly5.header.sample_rate-ALGORITHMIC_LATENCY_ESTIMATE, SAMPLE_DELAY_LIM(1)),SAMPLE_DELAY_LIM(2)),3);
h_scale = round(poly5.header.sample_rate*HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',[150   50   720   750]);
L = tiledlayout(fig,5,1);

% === Templates (top two rows), same layout scale as traces ===
tmpl_ax = nexttile(L,1,[2 1]);
set(tmpl_ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XLim',[-10, 8.1*(h_scale+h_spacing)], ...
    'Clipping','off');
title(tmpl_ax,'Templates (by channel)','FontName','Tahoma','Color','k');

squiggles_ax = nexttile(L,3,[2 1]);
set(squiggles_ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XLim',[-10, 8.1*(h_scale+h_spacing)], ...
    'Clipping', 'off');

line(squiggles_ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], [-0.4*LINE_VERTICAL_OFFSET, 0.6*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(squiggles_ax, -1.02*(h_scale+h_spacing), 0.65*LINE_VERTICAL_OFFSET, sprintf('%4.1f\\muV', LINE_VERTICAL_OFFSET), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left', 'VerticalAlignment','bottom');
line(squiggles_ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*LINE_VERTICAL_OFFSET,-0.4*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(squiggles_ax, -h_spacing, -0.45*LINE_VERTICAL_OFFSET, sprintf('%4.1fms', round(h_scale/(SAMPLE_RATE_RECORDING*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right','VerticalAlignment','top');

[~,f,~] = fileparts(MY_FILE);
title(squiggles_ax, sprintf("%s: UNI", strrep(f,'_','\_')),'FontName','Tahoma','Color','k');
time_txt = subtitle(squiggles_ax, 'T = 0.000s', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
h = gobjects(64,1);
cmapdata = winter(64);
for iH = 1:64
    h(iH) = line(squiggles_ax,(1:h_scale)+floor((iH-1)/8)*(h_scale+h_spacing), ...
        nan(1,h_scale), ...
        'Color',cmapdata(iH,:),...
        'LineWidth',0.5,...
        'LineStyle','-', ...
        'Marker', '*', ...
        'MarkerEdgeColor', 'r', ...
        'MarkerIndices', []);
end

trigs_ax = nexttile(L,5,[1 1]);
set(trigs_ax,'NextPlot','add','FontName','Tahoma','XColor','none', ...
    'YLim',[-0.1,1.1],...
    'YTick',[0,1],...
    'YTickLabel',["LOW", "HIGH"]);
h_trigs = line(trigs_ax,(1:h_scale), ...
    nan(1,h_scale), ...
    'Color','m',...
    'LineWidth',1.5,...
    'LineStyle','-', ...
    'Marker', '*', ...
    'MarkerEdgeColor', 'r', ...
    'MarkerIndices', []);
title(trigs_ax,'Triggers','FontName','Tahoma','Color','k');

% maintain a rolling raster buffer for display (units x h_scale)
raster_buf = false(DECOMP.MAX_UNITS, h_scale);
raster_plots = gobjects(DECOMP.MAX_UNITS,1);
for uu = 1:DECOMP.MAX_UNITS
    raster_plots(uu) = line(squiggles_ax, 1:h_scale, nan(1,h_scale), ...
        'LineStyle','-','LineWidth',1.25,'Marker','|', ...
        'Color', DECOMP.COLORSET(uu,:), 'UserData', uu);
end




%% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
[~,g] = sgolay(opts.SGOrder,opts.SGWindow);
b = g(:,2);
[b_hpf,a_hpf] = butter(1,100/(poly5.sample_rate/2),'high');
a = 1;
zi = zeros(numel(b)-1,64);
zi_hpf = zeros(numel(b_hpf)-1,64);
units_now = [];
warning('off','signal:findpeaks:largeMinPeakHeight');

%%
while isvalid(fig)
    samples = read_next_n_blocks(poly5, 2);
    n_samples = size(samples,2);
    if needs_initial_ts
        ts0 = samples(end,1)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', samples(end,end)/SAMPLE_RATE_RECORDING - ts0);
    % indices inside the plotting window
    iVec = rem(samples(end,:)-1,h_scale)+1;
    if any(iVec == 0)
        iVec(iVec == 0) = max(iVec);
    end

    % --- decode trigger line (handles inverted TMSi logic bits) ---
    trig_high = double(bitand(samples(TRIGS_CH,:), 2^TRIG_BIT)==0);

    [data_hpf,zi_hpf] = filter(b_hpf,a_hpf,samples(LAYOUT,:)',zi_hpf,1);
    % ===== ZCA whitening (calibrate once, then apply) =====
    if ZCA.ENABLE
        if ~ZCA.READY
            % Baseline rows for calibration
            if ZCA.USE_TRIGGER_BASELINE
                base_rows = find(trig_high==0);           % LOW = baseline
            else
                base_rows = 1:n_samples;                 % use all rows
            end
            if ~isempty(base_rows)
                ZCA.buf = [ZCA.buf; data_hpf(base_rows,:)];
                if size(ZCA.buf,1) > ZCA.nNeeded
                    ZCA.buf = ZCA.buf(end-ZCA.nNeeded+1:end,:); % cap growth
                end
            end
            if size(ZCA.buf,1) >= ZCA.nNeeded
                [ZCA.mu, ZCA.W] = zca_fit_once(ZCA.buf, ZCA.EPS, ZCA.SHRINK);
                ZCA.READY = true;
                fprintf('[ZCA] Calibrated on %d baseline samples (EPS=%.1e, shrink=%.1e)\n', ...
                    size(ZCA.buf,1), ZCA.EPS, ZCA.SHRINK);
            end
        end
        if ZCA.READY
            % Fast whitening of current block (center then multiply by W^T)
            data_hpf = (data_hpf - ZCA.mu) * ZCA.W.';    % keep (n_samples x 64)
        end
    end
    % ===== end ZCA block =====
    [data,zi] = filter(b,a,data_hpf,zi,1);
    % === ONLINE DECOMPOSITION BUFFERING ===
    % gestureMask: true when gesture prompted; here we use trig_high==1 for gesture epochs
    gestureMask_block = trig_high(:) == 1;  % (n_samples x 1) logical

    % Append to rolling buffer (cap length)
    DSTATE.buf  = [DSTATE.buf; data];                        
    DSTATE.mask = [DSTATE.mask; gestureMask_block];         
    if DSTATE.absStartIdx == 0
        DSTATE.absStartIdx = samples(end,1) - (n_samples-1); % absolute index for first row
    end
    % Trim to window length
    if size(DSTATE.buf,1) > DECOMP.trainSamp
        cut = size(DSTATE.buf,1) - DECOMP.trainSamp;
        DSTATE.buf(1:cut,:)  = [];
        DSTATE.mask(1:cut,:) = [];
        DSTATE.absStartIdx = DSTATE.absStartIdx + cut;
    end

    % === TRAIN ONCE, THEN ONLY DETECT ===
    curAbsEnd = samples(end,1);  % absolute sample index at block end

    if ~DSTATE.trained
        % keep buffering until both ZCA ready AND training buffer full
        if ZCA.READY && size(DSTATE.buf,1) >= max(DECOMP.trainSamp, ZCA.nNeeded)
            % ---- TRAIN (run decompose once) ----
            [units_once, ~, dbg] = decompose_emg_mvdr(DSTATE.buf, DSTATE.fs, DSTATE.mask, ...
                'Geometry', G, ...
                'SGOrder', opts.SGOrder, ...
                'SGWindow', opts.SGWindow, ...
                'DetectWindowMs', opts.DetectWindowMs, ...
                'DetectQuantile', opts.DetectQuantile, ...
                'DetectInterpSpatial', opts.DetectInterpSpatial, ...
                'SnapshotTwinMs', opts.SnapshotTwinMs, ...
                'SnapshotCHalf', opts.SnapshotCHalf, ...
                'KmeansK', opts.KmeansK, ...
                'KmeansMaxIter', opts.KmeansMaxIter, ...
                'ClusterMinCount', opts.ClusterMinCount, ...
                'ClusterPeakTolSamples', opts.ClusterPeakTolSamples, ...
                'ClusterMergeThresh', opts.ClusterMergeThresh, ...
                'MaxUnitsPerIter', opts.MaxUnitsPerIter, ...
                'MVDRThreshold', opts.MVDRThreshold, ...
                'MVDRShrinkage', opts.MVDRShrinkage, ...
                'PeelingAmpRange', opts.PeelingAmpRange, ...
                'RefineUpsample', opts.RefineUpsample, ...
                'MaxTotalUnits', opts.MaxTotalUnits, ...
                'SyncReject',opts.SyncReject,...
                'SyncTauMs', opts.SyncTauMs, ...
                'StrataPerBin',opts.StrataPerBin,  ...
                'StratifySeeds', opts.StratifySeeds, ...
                'StrataTol', opts.StrataTol, ...
                'StrataZCenters',opts.StrataZCenters);

            % keep top DECOMP.MAX_UNITS by template L2
            if ~isempty(units_once)
                [~,ordU] = sort(arrayfun(@(u) norm(u.templateTC,2), units_once), 'descend');
                units_once = units_once(ordU);
                units_once = units_once(1:min(numel(units_once), DECOMP.MAX_UNITS));
            end
            DSTATE.units = units_once;

            % Pre-compute and cache MVDR filters (w_k) ONCE from the training buffer
            DSTATE.mvdrW    = cell(1, numel(DSTATE.units));
            DSTATE.tRelPerU = cell(1, numel(DSTATE.units));
            DSTATE.cIdxPerU = cell(1, numel(DSTATE.units));
            % === Anchor for raster overlay per unit ===
            DSTATE.rasterXShift = zeros(1, numel(DSTATE.units));
            DSTATE.rasterYLevel = zeros(1, numel(DSTATE.units));
        
            for uu = 1:numel(DSTATE.units)
                u    = DSTATE.units(uu);
                tRel = u.templateWindow.tIdx;
                cAbs = u.templateWindow.cIdx;
                Tloc = numel(tRel);
                Cloc = numel(cAbs);
            
                % reshape template to [time x channel]
                tc = reshape(u.templateTC, Tloc, Cloc);
            
                % choose anchor channel: max energy
                [~, jBest] = max(sum(tc.^2,1));   
            
                cBest = cAbs(jBest);
            
                % compute x block shift and y level for that channel in 'ax'
                blockIdx = floor((cBest-1)/8);                         % which 8-channel block
                xShift   = blockIdx * (h_scale + h_spacing);           % x shift used when you plotted traces
                rowIdx   = rem(cBest-1, 8);                            % 0..7 row within the stack
                yLevel   = rowIdx*LINE_VERTICAL_OFFSET + RASTER_Y_FRAC*LINE_VERTICAL_OFFSET;
            
                DSTATE.rasterXShift(uu) = xShift;
                DSTATE.rasterYLevel(uu) = yLevel;
                u   = DSTATE.units(uu);
                xk  = u.templateTC(:);
                tRel = u.templateWindow.tIdx;
                cAbs = u.templateWindow.cIdx;

                % noise covariance from baseline in the training buffer
                [Sigma, ok] = estimate_noise_cov(DSTATE.buf, ~DSTATE.mask, tRel, cAbs);
                if ~ok
                    Sigma = eye(numel(xk)) * var(DSTATE.buf(~DSTATE.mask,:), 0, 'all');
                end
                Sigma = Sigma + opts.MVDRShrinkage * trace(Sigma)/numel(xk) * eye(size(Sigma));

                denom = max(xk'*(Sigma\xk), eps);
                wk = (Sigma\xk) / denom;

                DSTATE.mvdrW{uu}    = wk(:);
                DSTATE.tRelPerU{uu} = tRel(:);
                DSTATE.cIdxPerU{uu} = cAbs(:);
                DSTATE.emittedSpk{uu} = [];   % reset
            end

            % --- Draw templates in the same grid layout as the traces ---
            cla(tmpl_ax);
            if isempty(DSTATE.units)
                title(tmpl_ax,'Templates (n=0)','FontName','Tahoma','Color','k');
            else
                nU = numel(DSTATE.units);
            
                % per-channel stack counter so overlapping templates are vertically staggered
                chanStackCount = zeros(64,1);                         % assumes 64 channels
                stack_dy = 0.12 * LINE_VERTICAL_OFFSET;               % small vertical offset per overlap
            
                % time axis inside each block: scale template length to the block width
                % (so templates visually use the same horizontal scale as traces)
                % we’ll build this per-unit because Tloc can vary
                for uu = 1:nU
                    u = DSTATE.units(uu);
                    tRel = u.templateWindow.tIdx;
                    cAbs = u.templateWindow.cIdx(:).';
                    Tloc = numel(tRel);
                    Cloc = numel(cAbs);
            
                    tc = reshape(u.templateTC, Tloc, Cloc);
            
                    % amplitude scaling so the largest excursion fits comfortably in a channel band
                    amax  = max(abs(tc(:)));
                    scale = (0.8 * LINE_VERTICAL_OFFSET) / max(amax, eps);
            
                    % template time mapped to the width of one block (like traces use 1:h_scale)
                    xtLoc = linspace(1, h_scale, Tloc).';             % column
            
                    for jj = 1:Cloc
                        ch = cAbs(jj);
            
                        % X shift: which 8-ch block (0..7) * (block width + spacing)
                        blockIdx = floor((ch-1)/8);
                        xShift   = blockIdx * (h_scale + h_spacing);
            
                        % Y baseline: which row within the 8-high stack (0..7) * LINE_VERTICAL_OFFSET
                        rowIdx   = rem(ch-1, 8);
                        yBase    = rowIdx * LINE_VERTICAL_OFFSET;
            
                        % stack this template slightly above already-drawn ones on this channel
                        chanStackCount(ch) = chanStackCount(ch) + 1;
                        yOff = (chanStackCount(ch)-1) * stack_dy;
            
                        % waveform
                        x = xtLoc + xShift;
                        y = yBase + yOff + scale * tc(:, jj);
            
                        line(tmpl_ax, x, y, ...
                            'Color', DSTATE.unitColors(uu,:), ...
                            'LineWidth', 1.25);
                    end
                end
            
                title(tmpl_ax, sprintf('Templates (n=%d)', nU), 'FontName','Tahoma','Color','k');
            end

            % (Re)create raster overlays on the main EMG axes 'ax'
            % one line per unit, pre-shifted in X, flat Y at the unit’s yLevel
            raster_buf   = false(DECOMP.MAX_UNITS, h_scale);
            delete(raster_plots);
            raster_plots = gobjects(DECOMP.MAX_UNITS,1);
            for uu = 1:DECOMP.MAX_UNITS
                if uu <= numel(DSTATE.units)
                    xShift = DSTATE.rasterXShift(uu);
                    yLevel = DSTATE.rasterYLevel(uu);
                    raster_plots(uu) = line(squiggles_ax, (1:h_scale) + xShift, nan(1, h_scale), ...
                        'LineStyle','-','LineWidth',1.25,'Marker','|', ...
                        'Color', DECOMP.COLORSET(uu,:), 'UserData', uu);
                    % store the yLevel in the line for convenience (optional)
                    raster_plots(uu).UserData = struct('uu',uu,'yLevel',yLevel);
                else
                    % create a hidden placeholder (keeps indexing simple)
                    raster_plots(uu) = line(squiggles_ax, 1:h_scale, nan(1,h_scale), 'Visible','off');
                end
            end

            % Peak-in-window offset (relative to window start) per unit
            DSTATE.tPeakRelPerU = cell(1, numel(DSTATE.units));
            for uu = 1:numel(DSTATE.units)
                u    = DSTATE.units(uu);
                Tloc = numel(u.templateWindow.tIdx);
                Cloc = numel(u.templateWindow.cIdx);
                tc   = reshape(u.templateTC, Tloc, Cloc);
                [~, iPeak] = max(max(abs(tc), [], 2));           % time index of biggest excursion
                DSTATE.tPeakRelPerU{uu} = u.templateWindow.tIdx(iPeak);  % e.g., in [-Twin..+Twin]
            end
            
            % Keep last accepted peak time (absolute samples) per unit
            DSTATE.lastPeakAbs = -inf(1, numel(DSTATE.units));   % initialize


            DSTATE.trained = true;
            fprintf('[DECOMP] TRAINED: units=%d\n', numel(DSTATE.units));
        end

    else
        % ---- DETECT ONLY (no more decomposition) ----
        % We’ll detect spikes for each trained unit in the CURRENT rolling buffer.
        raster_buf(:, iVec) = false;   % clear only columns we’ll draw

        if ~isempty(DSTATE.units)
            % absolute indices for current block (same order as iVec)
            thisBlockAbs = samples(end,:);  
            nNew = n_samples;  % number of new rows appended to DSTATE.buf this frame
            for uu = 1:numel(DSTATE.units)
                wk   = DSTATE.mvdrW{uu};
                tRel = DSTATE.tRelPerU{uu};
                cAbs = DSTATE.cIdxPerU{uu};
            
                [ySel, tSel] = apply_sliding_mvdr(DSTATE.buf, wk, tRel, cAbs, nNew);
            
                if ~isempty(ySel)
                    ySel(isnan(ySel)) = 0;
                
                    % --- peak pick with refractory (in samples of the *buffer*) ---
                    refrSamp = max(1, round(opts.RefracMs * 1e-3 * DSTATE.fs));
                    % MinPeakDistance enforces within-frame refractory; MinPeakHeight = threshold
                    [pks, locs] = findpeaks(ySel, 'MinPeakHeight', opts.MVDRThreshold, ...
                                                  'MinPeakDistance', refrSamp);
                
                    if ~isempty(locs)
                        st_win   = tSel(locs);                       % window starts (buffer rows)
                        tPeakRel = DSTATE.tPeakRelPerU{uu};          % template peak relative offset
                        peak_buf = st_win + tPeakRel;                % buffer-row *peak* indices
                        peak_abs = DSTATE.absStartIdx + peak_buf - 1; % absolute *peak* indices
                
                        % Cross-frame debounce: drop peaks too close to the last accepted one
                        lastOK = DSTATE.lastPeakAbs(uu);
                        keep   = peak_abs >= (lastOK + refrSamp);
                        peak_buf = peak_buf(keep);  peak_abs = peak_abs(keep);  pks = pks(keep);  st_win = st_win(keep);
                
                        if ~isempty(peak_buf)
                            % Restrict to this block and convert to circular-plot columns
                            thisBlockBufIdx = (size(DSTATE.buf,1)-nNew+1 : size(DSTATE.buf,1)).';
                            [hit, posInBlock] = ismember(peak_buf, thisBlockBufIdx);
                            posInBlock = posInBlock(hit);
                            if ~isempty(posInBlock)
                                raster_cols = iVec(posInBlock);                  % 1..h_scale
                                raster_cols = raster_cols(raster_cols>=1 & raster_cols<=h_scale);
                                raster_buf(uu, raster_cols) = true;
                            end
                
                            % Store emitted spikes as *window starts* (consistent with snippets),
                            % but advance the refractory memory using *peak* absolute time.
                            st_abs = DSTATE.absStartIdx + st_win - 1;
                            DSTATE.emittedSpk{uu} = [DSTATE.emittedSpk{uu}; st_abs(:)];
                            if ~isfield(DSTATE.units(uu),'spikeTimesAbs') || isempty(DSTATE.units(uu).spikeTimesAbs)
                                DSTATE.units(uu).spikeTimesAbs = st_abs(:);
                            else
                                DSTATE.units(uu).spikeTimesAbs = [DSTATE.units(uu).spikeTimesAbs; st_abs(:)];
                            end
                            % update last accepted peak
                            DSTATE.lastPeakAbs(uu) = max(DSTATE.lastPeakAbs(uu), max(peak_abs));
                        end
                    end
                end

            end
        end

        % draw raster rows
        for uu = 1:numel(DSTATE.units)
            yrow = nan(1,h_scale);
            yrow(raster_buf(uu,:)) = DSTATE.rasterYLevel(uu);
            set(raster_plots(uu), 'YData', yrow);
        end
    end

    % Last: update graphics
    for iH = 1:64
        h(iH).YData(iVec) = data(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    h_trigs.YData(iVec) = trig_high;
    drawnow();
    pause(sample_delay);
end
poly5.close();

warning('on','signal:findpeaks:largeMinPeakHeight');
