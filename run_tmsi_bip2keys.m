function run_tmsi_bip2keys(options)
%RUN_TMSI_BIP2KEYS  Map SAGA bipolar RMS (65..68) to keyboard taps, with ZCA.
%
% Controls:
%   • Tap 'Z' (on key UP) to capture 5 s of raw → HPF → compute ZCA whitening.
%     After ZCA is ready, CalibEnabled = true.
%   • Hold SPACE (this window focused) to collect calibration RMS (ENABLED ONLY
%     after ZCA). Release SPACE → thresholds = MadScale * MAD(RMS) per channel.
%   • When RMS > threshold for a channel, we fire simulate_keypress(KEY,'tap',PulseMs).
%   • Debounce stops re-trigger until DebounceMs elapses.
%   • Press 'q' (or close) to quit cleanly.
%
% Requirements:
%   • TMSiSAGA MATLAB API (on path)
%   • simulate_keypress.mex* (Windows, non-blocking timer-queue version)
%
% Name-Value options (all optional):
%   'BipolarIdx'   : [65 66 67 68]
%   'KeyMap'       : {'1','2','3','4'}   % one per channel
%   'PulseMs'      : 200
%   'DebounceMs'   : 200
%   'RMSWindowMs'  : 50
%   'FsGuess'      : 2000
%   'MadScale'     : 4.5
%   'Interface'    : 'auto' | 'electrical' | 'optical'
%   'LoopPause'    : 0.005
%   --- New ---
%   'HPFCutoffHz'  : 40
%   'ZCABufferSec' : 5
%   'ZCAEps'       : 1e-6
%   'PlotUpdateSec': 0.10
%
% Example:
%   run_tmsi_bip2keys('KeyMap',{'A','S','K','L'},'PulseMs',150)

arguments
    options.BipolarIdx (1,:) double = [65 66 67 68]
    options.KeyMap (1,:) cell = {'1','2','3','4'}
    options.PulseMs (1,1) double = 200
    options.DebounceMs (1,1) double = 200
    options.RMSWindowMs (1,1) double = 50
    options.FsGuess (1,1) double = 2000
    options.MadScale (1,1) double = 4.5
    options.Interface (1,1) string {mustBeMember(options.Interface,["auto","electrical","optical"])} = "auto"
    options.LoopPause (1,1) double = 0.005
    % New
    options.HPFCutoffHz (1,1) double = 40
    options.ZCABufferSec (1,1) double = 5
    options.ZCAEps (1,1) double = 1e-6
    options.PlotUpdateSec (1,1) double = 0.10

    % One-Euro envelope smoothing
    options.OneEuroEnable (1,1) logical = true
    options.OneEuroMinCutoffHz (1,1) double = 2.0
    options.OneEuroBeta (1,1) double = 0.05
    options.OneEuroDerivCutoffHz (1,1) double = 6.0

end

%% --- Quick sanity checks ---
if exist('simulate_keypress','file') ~= 3
    error('simulate_keypress MEX not found on path.');
end
if ~exist('TMSiSAGA.Library','class')
    error('TMSiSAGA not found on path.');
end

bipIdx = options.BipolarIdx(:);
keys   = string(options.KeyMap(:));
nBtns  = numel(bipIdx);
if numel(keys) ~= nBtns
    error('KeyMap must have the same length as BipolarIdx.');
end

PulseSec    = options.PulseMs/1000;
DebounceSec = options.DebounceMs/1000;

% Moving RMS window (in samples). If we can’t infer Fs, we’ll use FsGuess.
Fs = options.FsGuess;
Nwin = max(1, round(options.RMSWindowMs * Fs / 1000));

%% --- Connect one SAGA device (minimal, USB; try auto -> fallback) ---
lib = TMSiSAGA.Library();
cleanupLib = onCleanup(@() tryClean(@()lib.cleanUp())); %#ok<NASGU>

devs = [];
try
    switch options.Interface
        case "electrical"
            devs = lib.getDevices('usb','electrical',2,2);
        case "optical"
            devs = lib.getDevices('usb','optical',2,2);
        otherwise
            try
                devs = lib.getDevices('usb','electrical',2,2);
                if isempty(devs), error('fallback'); end
            catch
                devs = lib.getDevices('usb',{'electrical','optical'},2,2);
            end
    end
    if isempty(devs)
        error('No SAGA found over USB.');
    end
    device = devs(1);
    connect(device);
catch ME
    rethrow(ME);
end

config_channels = struct( ...
    'uni', 1:64, ...
    'bip', 1:4, ...
    'dig', 0, ...
    'acc', 0, ...
    'aux', 0);
config_device = struct('Dividers', {{'uni', 1; 'bip', 1; 'dig', 1; 'triggers', 1; 'aux', 1}}, ...
    'Triggers', true, ...
    'BaseSampleRate', 4000, ...
    'RepairLogging', false, ...
    'ImpedanceMode', false, ...
    'AutoReferenceMethod', false, ...
    'ReferenceMethod', 'average', ... % must be 'common' or 'average'
    'SyncOutDivider', -1, ...
    'SyncOutDutyCycle', 500);

% Enable all channels (we’ll only read the bipIdx rows)
enableChannels(device, device.channels);
configStandardMode(device, config_channels, config_device);

% Estimate Fs if possible (fallback to FsGuess).
try
    info = getDeviceInfo(device); %#ok<NASGU>
    % If you know divider+base rate, compute Fs here and update Nwin.
catch
end
Nwin = max(1, round(options.RMSWindowMs * Fs / 1000));

%% --- Filters and whitening state ---
% HPF (Butterworth) for EMG
Wn = max(1e-3, options.HPFCutoffHz / (Fs/2));  % normalized cutoff
[bhp, ahp] = butter(4, Wn, 'high');
ziHP = zeros(max(numel(bhp),numel(ahp))-1, nBtns); % per-channel HPF state

% RMS envelope filter state (on whitened signal^2)
bEnv = ones(Nwin,1,'double')/Nwin; aEnv = 1;
ziEnv = zeros(max(length(bEnv),length(aEnv))-1, nBtns);

% ZCA state
ZCA = struct('ready',false, 'mu',zeros(1,nBtns), 'W',eye(nBtns), ...
    'collecting',false, 'buf',[], 'needSec',options.ZCABufferSec);

CalibEnabled = false;   % gate: SPACE calibration allowed only after ZCA ready
calibEnable      = true(1, nBtns);   % per-channel: calibrate this channel?
sendKeysEnabled  = true;             % global gate for simulate_keypress

% Trigger/threshold state
nextAllowedAt = zeros(1, nBtns);
threshold     = inf(1, nBtns);
haveThresh    = false(1, nBtns);

% Calibration buffer (RMS values) per channel while space is held
calibActive  = false;
calibRMS     = cell(1, nBtns);
calibEnvBuf  = cell(1, nBtns);
calibStartT  = NaN;

% --- One-Euro filter state for envelope (per channel) ---
te = 1 / Fs;  % sample period
oe_min = options.OneEuroMinCutoffHz;
oe_beta = options.OneEuroBeta;
oe_dcut = options.OneEuroDerivCutoffHz;
% Previous estimates (per channel); NaN means "uninitialized"
oe_xhat_prev  = NaN(1, nBtns);
oe_dxhat_prev = NaN(1, nBtns);

%% --- Live ring buffers for plots (last 5 s) ---
Nplot = max(1, round(options.ZCABufferSec * Fs));
ringSig = nan(Nplot, nBtns);    % whitened signal
ringEnv = nan(Nplot, nBtns);    % RMS envelope
ringPtr = 0;

%% --- UI: status + 1x4 plot row ---
t0 = tic;
persistent lastUI; if isempty(lastUI), lastUI = 0; end

hFig = figure('Name','Bipolar→Keys (HPF + ZCA)','NumberTitle','off', ...
    'Color','w','MenuBar','none','ToolBar','none', ...
    'KeyPressFcn',@onKeyDown,'KeyReleaseFcn',@onKeyUp, ...
    'CloseRequestFcn',@onClose,'Position',[250   100   560   750]);

% Status text (top 35% height)
statusTxt = uicontrol(hFig,'Style','text','Units','normalized', ...
    'Position',[0.05 0.65 0.90 0.30],'FontSize',11,'HorizontalAlignment','left', ...
    'BackgroundColor','w','String',statusString());
% Global: enable/disable keypress output
chkSend = uicontrol(hFig,'Style','checkbox','Units','normalized', ...
    'Position',[0.05 0.61 0.40 0.04], 'Value',1, ...
    'String','Send keypress output', ...
    'BackgroundColor','w', ...
    'Callback', @(h,~) setSendEnable(get(h,'Value')));
chkCal = gobjects(1,nBtns);
for i = 1:nBtns
    left = 0.05 + (i-1)*(0.90/nBtns);
    width = 0.90/nBtns - 0.01;
    chkCal(i) = uicontrol(hFig,'Style','checkbox','Units','normalized', ...
        'Position',[left, 0.58, width, 0.03], 'Value',1, ...
        'String',sprintf('Cal Ch %d', bipIdx(i)), ...
        'BackgroundColor','w', ...
        'Callback', @(h,~) setCalEnable(i, get(h,'Value')));
end
% Axes row (bottom 55% height), 1x4 columns
ax = gobjects(1,nBtns); hSig = gobjects(1,nBtns); hEnv = gobjects(1,nBtns); hThr = gobjects(1,nBtns);
for i = 1:nBtns
    % Manual grid: margins and spacing
    left = 0.05 + (i-1)*(0.90/nBtns);
    width = 0.90/nBtns - 0.01;
    ax(i) = axes('Parent',hFig,'Units','normalized', ...
        'Position',[left, 0.10, width, 0.50], ...
        'XLim',[0,Nplot],'YLim',[-10 10]);
    hold(ax(i),'on');
    title(ax(i), sprintf('Ch %d  → key "%s"', bipIdx(i), keys(i)));
    xlabel(ax(i),'Time (s)'); ylabel(ax(i),'a.u.');
    grid(ax(i),'on');
    % Placeholders
    hSig(i) = plot(ax(i), nan, nan, '-', 'LineWidth', 1.0, 'Color', 'k');
    hEnv(i) = plot(ax(i), nan, nan, '-', 'LineWidth', 2.0, 'Color', 'b');
    hThr(i) = plot(ax(i), [0 1], [NaN NaN], '-', 'LineWidth', 1.0, 'Color',[0.5 0 0]);
    xlim(ax(i), [-options.ZCABufferSec, 0]); % show last 5 s
end

% Start device
start(device);
tryStop = onCleanup(@() tryClean(@()stop(device)));

fprintf('Running. Tap Z to collect 5 s for ZCA; then hold SPACE to calibrate.\n');


%% --- Main loop ---
while isvalid(hFig)
    pause(options.LoopPause);

    % Pull a block of samples
    [blk, nsets] = device.sample();
    if nsets < 1, continue; end
    if size(blk,1) < max(bipIdx), continue; end

    % nsamp x nBtns (raw)
    x_raw = double(blk(bipIdx,:)).';

    % On-the-fly HPF (causal)
    [x_hpf, ziHP] = filter(bhp, ahp, x_raw, ziHP, 1);

    % If collecting for ZCA, stash RAW (per request we HPF just before ZCA calc)
    if ZCA.collecting
        ZCA.buf = [ZCA.buf; x_raw]; %#ok<AGROW>
        if size(ZCA.buf,1) >= (ZCA.needSec * Fs)
            % Stop collection, HPF the buffer, compute ZCA, enable calibration
            ZCA.collecting = false;
            % --- Sanitize and compute robust ZCA ---
            X = ZCA.buf;
            disp("ZCA Buffer filled.");

            % 1) Drop any rows with non-finite values
            mask = all(isfinite(X), 2);
            if ~any(mask)
                warning('ZCA: all rows were non-finite; keeping ZCA disabled.');
                ZCA.ready = false; CalibEnabled = false; ZCA.collecting = false;
            else
                X = X(mask, :);

                % 2) Zero-phase HPF on the cleaned buffer
                try
                    X_hp = filtfilt(bhp, ahp, X);   % requires enough samples; we should have plenty
                catch
                    % If filtfilt fails (too short), use causal filter as fallback
                    X_hp = filter(bhp, ahp, X);
                end

                % 3) Robust ZCA (safe against tiny/zero eigenvalues)
                [muW_ok, muW_mu, muW_W] = compute_zca_safe(X_hp, options.ZCAEps);
                if ~muW_ok
                    warning('ZCA: computation failed (non-finite). Whitening disabled.');
                    ZCA.ready = false; CalibEnabled = false;
                else
                    ZCA.mu = muW_mu;
                    ZCA.W  = muW_W;
                    ZCA.ready = true;
                    CalibEnabled = true;

                    % 4) Reset One-Euro states because scale/mean just changed
                    oe_xhat_prev(:)  = NaN;
                    oe_dxhat_prev(:) = NaN;

                    fprintf('ZCA ready. Calibration is now enabled (SPACE).\n');
                end
            end
        end
    end

    % Apply ZCA (if ready); otherwise just use HPF signal for plotting/logic
    if ZCA.ready
        x_wh = (x_hpf - ZCA.mu) * ZCA.W;    % nsamp x nBtns
    else
        x_wh = x_hpf;
    end
    % Guard: if W or mu somehow went bad mid-run, disable whitening
    if any(~isfinite(x_wh), 'all')
        warning('Live whitening produced non-finite values; disabling ZCA until re-init.');
        ZCA.ready = false; CalibEnabled = false;
        ZCA.W = eye(nBtns); ZCA.mu = zeros(1, nBtns);
        x_wh = x_hpf;
    end


    % Moving RMS envelope on whitened signal
    [mavg, ziEnv] = filter(bEnv, aEnv, x_wh.^2, ziEnv, 1);
    x_env = sqrt(mavg);
    % One-Euro smoothing on the envelope
    if options.OneEuroEnable
        [x_env_filt, oe_xhat_prev, oe_dxhat_prev] = oe_block( ...
            x_env, oe_xhat_prev, oe_dxhat_prev, oe_min, oe_beta, oe_dcut);
    else
        x_env_filt = x_env;
    end


    tNow = toc(t0);
    if calibActive
        for ii = 1:nBtns
            ei = x_env_filt(:, ii);
            if ~isempty(ei)
                calibEnvBuf{ii} = [calibEnvBuf{ii}; ei]; %#ok<AGROW>
            end
        end
    else
        % Threshold crossing → fire key tap (non-blocking) if calibrated
        if all(haveThresh)
            over = any(x_env_filt > threshold, 1); % 1 x nBtns
            for ii = 1:nBtns
                if over(ii) && (tNow >= nextAllowedAt(ii))
                    if sendKeysEnabled
                        try
                            simulate_keypress(char(keys(ii)),'tap', options.PulseMs);
                        catch ke
                            warning('simulate_keypress failed for "%s": %s', keys(ii), ke.message);
                        end
                    end
                    nextAllowedAt(ii) = tNow + PulseSec + DebounceSec;
                end
            end
        end

    end

    % Append to ring buffers for plotting
    ns = size(x_wh,1);
    idx = mod((ringPtr+(1:ns))-1, Nplot)+1;
    ringSig(idx,:) = x_wh;
    ringEnv(idx,:) = x_env_filt;
    ringPtr = mod(ringPtr+ns, Nplot);

    % Update UI occasionally
    if (tNow - lastUI) > options.PlotUpdateSec
        if isvalid(hFig)
            updatePlots();
            statusTxt.String = statusString();
        end
        lastUI = tNow;
    end
end

% ---------------- nested callbacks & helpers ----------------
    function onKeyDown(~, ev)
        switch lower(ev.Key)
            case 'space'
                % Gate: allow calibration only after ZCA
                if CalibEnabled && ~calibActive
                    calibActive = true;
                    calibRMS    = cell(1,nBtns);   % (ok to keep/reset)
                    calibEnvBuf = cell(1,nBtns);   % << NEW
                    calibStartT = toc(t0);         % << NEW
                    fprintf('Calibration started (holding SPACE)…\n');
                end
            case 'q'
                if isvalid(hFig), delete(hFig); end
        end
    end

    function onKeyUp(~, ev)
        switch lower(ev.Key)
            case 'space'
                if calibActive
                    calibActive = false;
                    for i = 1:nBtns
                        if ~calibEnable(i)
                            haveThresh(i) = false;
                            continue;
                        end
                        r = calibEnvBuf{i};   % strictly captured while SPACE held
                        if isempty(r)
                            haveThresh(i) = false;
                            continue;
                        end
                        calibEnvBuf{i} = []; % empty that buffer
                        m  = median(r);
                        md = median(abs(r - m));
                        thr = options.MadScale * md;
                        if ~isfinite(thr) || thr <= 0
                            thr = options.MadScale * max(1e-9, mad_fallback(r));
                        end
                        ax(i).YLim = [-2.5 * thr, 2.5*thr];
                        threshold(i) = thr;
                        haveThresh(i) = true;
                    end

                    fprintf('Calibration ended. Thresholds set: [%s]\n', ...
                        strjoin(string(threshold), ', '));
                end

            case 'z'
                % Start a fresh ZCA collection on key UP
                if ~ZCA.collecting
                    ZCA.collecting = true;
                    ZCA.buf = [];
                    fprintf('ZCA: collecting %g s of raw samples…\n', options.ZCABufferSec);
                end
        end
    end

    function onClose(~, ~)
        delete(hFig);
    end

    function s = statusString()
        base = [
            "Bipolar idx : " + join(string(bipIdx), ', ')
            "Key map     : " + join(keys, ', ')
            "Pulse (ms)  : " + string(options.PulseMs) + "   Debounce (ms): " + string(options.DebounceMs)
            "RMS win (ms): " + string(options.RMSWindowMs) + "  (N=" + string(Nwin) + ", Fs≈" + string(Fs) + ")"
            "HPF cutoff  : " + string(options.HPFCutoffHz) + " Hz"
            "ZCA state   : " + tern(ZCA.collecting,"collecting… ","") + tern(ZCA.ready,"ready","not ready")
            "CalibEnabled: " + string(CalibEnabled) + "   Calibrating: " + string(calibActive)
            "Thresh      : " + join(string(round(threshold,6)), ', ')
            "Next OK (s) : " + join(string(max(0, nextAllowedAt - toc(t0))), ', ')
            "Quick keys  : Z=ZCA  SPACE=calibrate (after ZCA)  Q=quit"
            "Output keys : " + string(sendKeysEnabled) + ...
            "   Calib chans: " + join(string(find(calibEnable)) , ', ')
            "OneEuro     : " + tern(options.OneEuroEnable,"on","off") + ...
            " (min=" + string(oe_min) + ", beta=" + string(oe_beta) + ", dcut=" + string(oe_dcut) + ")"
            ];
        s = strjoin(base, newline);
    end

    function c = tern(cond,a,b)
        if cond
            c = a;
        else
            c = b;
        end
    end

    function updatePlots()
        if ~ZCA.ready
            % Before ZCA, clear plots
            for i = 1:nBtns
                set(hSig(i),'XData',nan,'YData',nan);
                set(hEnv(i),'XData',nan,'YData',nan);
                set(hThr(i),'XData',[0 1],'YData',[NaN NaN]);
            end
            return;
        end
        % Build ordered time axis and data from ring buffer
        t = ((1:Nplot) - Nplot) ./ Fs;  % [-T .. -1/Fs]
        ord = [(ringPtr+1):Nplot, 1:ringPtr]; %#ok<*COLND>
        for i = 1:nBtns
            ys = ringSig(ord, i);
            ye = ringEnv(ord, i);
            set(hSig(i),'XData',t,'YData',ys);
            set(hEnv(i),'XData',t,'YData',ye);
            % Threshold line (if available)
            if haveThresh(i) && calibEnable(i)
                set(hThr(i),'XData',[t(1) t(end)],'YData',[threshold(i) threshold(i)]);
            else
                set(hThr(i),'XData',[t(1) t(end)],'YData',[NaN NaN]);
            end
            % Nice y-lims
            ypad = 0.05;
            ymax = max([1e-9; abs(ys); ye]);
            % ylim(ax(i), [-1 1]*max(1e-6, prctile(abs(ys), 99.5) + ypad*ymax));
            % xlim(ax(i), [t(1) 0]);
        end
    end

    function [ok, mu, W] = compute_zca_safe(Xhp, epsval)
        % Xhp: N x D (already HPF'd), may still contain outliers but no NaNs/Infs.
        % Returns:
        %   ok  : logical, true if W and mu are finite
        %   mu  : 1 x D mean
        %   W   : D x D whitening matrix

        mu = mean(Xhp, 1);
        Xc = Xhp - mu;

        % Symmetric covariance, normalized by N
        C = (Xc.' * Xc) / max(1, size(Xc,1));
        C = (C + C.') * 0.5;

        % Eigen-decomp (symmetric)
        [V, Dvec] = eig(C, 'vector');
        Dvec = real(Dvec);
        Dvec(Dvec < 0) = 0;                  % clip numerics

        % Data-scaled regularizer: prevents 1/sqrt(0)
        reg = max(epsval, median(Dvec) * 1e-6);

        inv_sqrt = 1 ./ sqrt(Dvec + reg);
        W = V * diag(inv_sqrt) * V.';        % ZCA: V Λ^{-1/2} V^T

        ok = all(isfinite(W), 'all') && all(isfinite(mu));
        if ~ok
            mu = zeros(1, size(Xhp,2));
            W  = eye(size(Xhp,2));
        end
    end


    function v = mad_fallback(x)
        xm = median(x);
        v = median(abs(x - xm));
    end

    function tryClean(fh)
        try, fh(); end %#ok<TRYNC>
    end

    function r = ringEnvWindowForCalib(iCh)
        % Return the contiguous env buffer during the most recent hold.
        % If you want strictly "during SPACE down", swap this to an active capture.
        % Here we just use last Nplot seconds as a reasonable proxy.
        if any(isnan(ringEnv(:,iCh)))
            r = ringEnv(~isnan(ringEnv(:,iCh)), iCh);
        else
            ord = [(ringPtr+1):Nplot, 1:ringPtr];
            r = ringEnv(ord, iCh);
        end
    end

    function setSendEnable(v)
        sendKeysEnabled = logical(v);
    end

    function setCalEnable(i, v)
        calibEnable(i) = logical(v);
        % If disabling, clear threshold line and flag
        if ~calibEnable(i)
            haveThresh(i) = false;
            if isgraphics(hThr(i)), set(hThr(i),'YData',[NaN NaN]); end
        end
    end

    function a = oe_alpha(cut)
        % cut in Hz
        tau = 1 ./ (2*pi*max(cut, ones(size(cut)).*1e-9));
        a = 1 ./ (1 + tau./te);
    end

    function [y_filt, oe_xhat_prev, oe_dxhat_prev] = oe_block(x, ...
            oe_xhat_prev, oe_dxhat_prev, min_cut, beta, d_cut)
        % x: nsamp x nch (current block, envelope)
        ns = size(x,1); nch = size(x,2);
        y_filt = zeros(ns, nch);
        % Precompute derivative alpha (fixed cutoff)
        a_d = oe_alpha(d_cut);
        for k = 1:ns
            xk = x(k,:);    % 1 x nch
            % Init per channel if needed
            new_init = isnan(oe_xhat_prev);
            if any(new_init)
                oe_xhat_prev(new_init)  = xk(new_init);
                oe_dxhat_prev(new_init) = 0;
            end
            % Derivative (finite diff), then LPF it
            dx = (xk - oe_xhat_prev) / te;
            dxhat = a_d .* dx + (1 - a_d) .* oe_dxhat_prev;

            % Adaptive cutoff
            cut = min_cut + beta .* abs(dxhat);
            a_x = oe_alpha(cut);

            % Main LPF of signal
            xhat = a_x .* xk + (1 - a_x) .* oe_xhat_prev;

            % Write out and carry state
            y_filt(k,:) = xhat;
            oe_xhat_prev = xhat;
            oe_dxhat_prev = dxhat;
        end
    end

end
