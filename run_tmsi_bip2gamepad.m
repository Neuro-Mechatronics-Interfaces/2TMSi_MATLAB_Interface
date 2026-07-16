function run_tmsi_bip2gamepad(options)
%RUN_TMSI_BIP2GAMEPAD  Map SAGA bipolar RMS (65..68) to ViGEm button pulses.
%
% Controls:
%   • Hold SPACE while the small status window is focused to collect a calibration buffer.
%   • Release SPACE to compute thresholds: thresh(ch) = 4.5 * MAD(RMS_buffer_ch).
%   • When RMS crosses thresh, we send a one-shot button press for PulseMs (default 200 ms).
%   • Debounce: no re-press for that channel until the pulse has been released.
%   • Press 'q' (or close window) to quit cleanly.
%
% Requirements:
%   • TMSiSAGA MATLAB API (on path)
%   • ViGEmBus installed + your MEX: vigem_gamepad.mex* (docs indicate CMD_INIT/CMD_SENDALL/CMD_CLEANUP)
%
% Name-Value options (all optional):
%   'BipolarIdx'        : [65 66 67 68] indices used from SAGA sample() output
%   'ButtonCodes'       : [0x1000 0x2000 0x4000 0x8000] (A,B,X,Y)
%   'PulseMs'           : 200       (press duration)
%   'DebounceMs'        : 200       (no re-press until released)
%   'RMSWindowMs'       : 50        (moving RMS window in ms)  (*used with FsGuess*)
%   'FsGuess'           : 2000      (only for RMS window sizing if true Fs unknown)
%   'MadScale'          : 4.5       (threshold = MadScale * MAD of RMS during calib)
%   'Interface'         : 'auto'    ('auto' | 'electrical' | 'optical')
%   'LoopPause'         : 0.005     (loop sleep to reduce CPU)
%
% Example:
%   run_tmsi_bip2gamepad('PulseMs',250,'RMSWindowMs',80);
%

arguments
    options.BipolarIdx (1,:) double = [65 66 67 68]
    options.ButtonCodes (1,:) double = hex2dec(['1000';'2000';'4000';'8000']).'
    options.PulseMs (1,1) double = 200
    options.DebounceMs (1,1) double = 200
    options.RMSWindowMs (1,1) double = 50
    options.FsGuess (1,1) double = 2000
    options.MadScale (1,1) double = 4.5
    options.Interface (1,1) string {mustBeMember(options.Interface,["auto","electrical","optical"])} = "auto"
    options.LoopPause (1,1) double = 0.005
end

%% --- Quick sanity checks ---
if exist('vigem_gamepad','file') ~= 3 
    error('vigem_gamepad MEX not found on path.');
end
if ~exist('TMSiSAGA.Library','class')
    error('TMSiSAGA not found on path.');
end

bipIdx   = options.BipolarIdx(:);
btnCodes = options.ButtonCodes(:);
nBtns    = numel(bipIdx);

if numel(btnCodes) ~= nBtns
    error('ButtonCodes must have the same length as BipolarIdx.');
end

PulseSec    = options.PulseMs/1000;
DebounceSec = options.DebounceMs/1000;

% Moving RMS window (in samples). If we can’t infer Fs, we’ll use FsGuess.
Nwin = max(1, round(options.RMSWindowMs * options.FsGuess / 1000));

%% --- Init ViGEm virtual pad ---
vigem_gamepad(1);  % CMD_INIT
lastSentMask = uint16(0);
cleanupVigem = onCleanup(@() safeVigemCleanup());

%% --- Connect one SAGA device (minimal, USB; try auto -> fallback both) ---
lib = TMSiSAGA.Library();
cleanupLib = onCleanup(@() tryClean(@()lib.cleanUp()));

devs = [];
try
    switch options.Interface
        case "electrical"
            devs = lib.getDevices('usb','electrical',2,2);
        case "optical"
            devs = lib.getDevices('usb','optical',2,2);
        otherwise
            % Try preferred order, then fallback to either:
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
    device = devs(1); %#ok<NASGU> % Keep original var name in case you want to extend
    connect(devs(1));
    device = devs(1); % use a single device
catch ME
    rethrow(ME);
end

% Enable all channels (we’ll only read the bipIdx rows)
enableChannels(device, device.channels);

% Try to estimate Fs if possible (best-effort; safe fallback to FsGuess).
Fs = options.FsGuess;
try
    info = getDeviceInfo(device); %#ok<NASGU>
    % If you have divider + base rate, set Fs accordingly here:
    %   Fs = info.base_sample_rate / (2^configured_divider);
catch
end

% Now (re)size RMS window if we got a better Fs:
Nwin = max(1, round(options.RMSWindowMs * Fs / 1000));

% Streaming RMS filter states (moving average of squares => sqrt)
b = ones(Nwin,1,'double')/Nwin; a = 1;
zi = zeros(max(length(b),length(a))-1, nBtns);  % per-channel zi for 'filter'

% Per-button press logic
isHeld       = false(1, nBtns);   % currently in the 200 ms pulse
releaseAt    = zeros(1, nBtns);   % absolute time (toc startClock) to release
threshold    = inf(1, nBtns);     % set after calibration
haveThresh   = false(1, nBtns);

% Calibration buffer (RMS values) per channel while space is held
calibActive  = false;
calibRMS     = cell(1, nBtns);

% Simple status figure (key capture)
hFig = figure('Name','Bipolar→Gamepad mapper','NumberTitle','off', ...
              'Color','w','MenuBar','none','ToolBar','none', ...
              'KeyPressFcn',@onKeyDown,'KeyReleaseFcn',@onKeyUp, ...
              'CloseRequestFcn',@onClose);
statusTxt = uicontrol(hFig,'Style','text','Units','normalized', ...
    'Position',[0.05 0.15 0.90 0.80],'FontSize',11,'HorizontalAlignment','left', ...
    'BackgroundColor','w','String',statusString());

% Start device
start(device);
tryStop = onCleanup(@() tryClean(@()stop(device)));
t0 = tic;

fprintf('Running. Focus the small window and hold SPACE to calibrate…\n');

%% --- Main loop ---
while isvalid(hFig)
    pause(options.LoopPause);

    % Pull a block of samples
    [blk, nsets] = device.sample();
    if nsets < 1, continue; end

    if size(blk,1) < max(bipIdx)
        % Channel list doesn’t include requested bipolar indices
        % You can choose to error out or just skip this block.
        continue;
    end

    % Pick only the 65..68 rows; shape to [samples x channels]
    x = double(blk(bipIdx,:)).';   % (nsamp x nBtns)

    % Moving RMS: sqrt(movavg(x.^2))
    [mavg, zi] = filter(b, a, x.^2, zi, 1);
    xrms = sqrt(mavg);             % (nsamp x nBtns)

    % If calibrating, stash RMS stream
    if calibActive
        for i = 1:nBtns
            % Only stash valid (non-NaN) points once the filter has warmed up
            r = xrms(:,i);
            calibRMS{i} = [calibRMS{i}; r(~isnan(r))]; %#ok<AGROW>
        end
    end

    % Threshold crossing → button press (one-shot) if calibrated
    tNow = toc(t0);
    if all(haveThresh)
        % Simple “any point over threshold” logic per channel in this block
        over = any(xrms > threshold, 1); % 1 x nBtns logical
        for i = 1:nBtns
            if ~isHeld(i) && over(i)
                % Begin pulse
                isHeld(i)    = true;
                releaseAt(i) = tNow + PulseSec;
            end
        end
    end

    % Maintain the currently pressed bitmask, auto-release as needed
    mask = uint16(0);
    for i = 1:nBtns
        if isHeld(i)
            if tNow >= releaseAt(i)
                % release this button
                isHeld(i) = false;
            else
                mask = bitor(mask, uint16(btnCodes(i)));
            end
        end
    end

    % Only send to MEX if something changed
    if mask ~= lastSentMask
        vigem_gamepad(2, mask, int8(0), int8(0), int8(0), int8(0)); % CMD_SENDALL
        lastSentMask = mask;
    end

    % Update status text occasionally
    persistent lastUI; if isempty(lastUI), lastUI = 0; end
    if (tNow - lastUI) > 0.10
        if isvalid(hFig)
            statusTxt.String = statusString();
        end
        lastUI = tNow;
    end
end

% --------------- nested callbacks & helpers ----------------
    function onKeyDown(~, ev)
        switch lower(ev.Key)
            case 'space'
                if ~calibActive
                    calibActive = true;
                    calibRMS = cell(1,nBtns); % reset buffers
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
                    % Compute thresholds per channel from collected RMS buffer
                    for i = 1:nBtns
                        r = calibRMS{i};
                        if isempty(r)
                            haveThresh(i) = false;
                            continue;
                        end
                        % Robust MAD of RMS (around median), no scaling
                        m  = median(r);
                        md = median(abs(r - m));
                        thr = options.MadScale * md;
                        % Guard: if md ~ 0 (dead channel), pick tiny epsilon
                        if ~isfinite(thr) || thr <= 0
                            thr = options.MadScale * max(1e-9, mad_fallback(r));
                        end
                        threshold(i) = thr;
                        haveThresh(i) = true;
                    end
                    fprintf('Calibration ended. Thresholds set: [%s]\n', ...
                        strjoin(string(threshold), ', '));
                end
        end
    end

    function onClose(~, ~)
        % Force clear outputs, release all
        try
            if lastSentMask ~= 0
                vigem_gamepad(2, uint16(0), int8(0), int8(0), int8(0), int8(0));
            end
        end
        delete(hFig);
    end

    function s = statusString()
        base = [
            "Bipolar idx : " + join(string(bipIdx), ', ')
            "Button codes: " + join("0x"+upper(dec2hex(btnCodes)), ', ')
            "Pulse (ms)  : " + string(options.PulseMs)
            "RMS win (ms): " + string(options.RMSWindowMs) + "  (N=" + string(Nwin) + ", Fs≈" + string(Fs) + ")"
            "Calibrating : " + string(calibActive)
            "Thresholds  : " + join(string(round(threshold,6)), ', ')
            "Pressed     : " + join(string(isHeld), ', ')
            "Quick keys  : SPACE=calibrate, Q=quit"
        ];
        s = strjoin(base, newline);
    end

    function safeVigemCleanup()
        % Release all buttons + cleanup
        try, vigem_gamepad(2, uint16(0), int8(0), int8(0), int8(0), int8(0)); end %#ok<TRYNC>
        try, vigem_gamepad(0); end %#ok<TRYNC>  % CMD_CLEANUP
    end

    function tryClean(fh)
        try, fh(); end %#ok<TRYNC>
    end

    function v = mad_fallback(x)
        % If you ever want a tiny nonzero in pathological cases
        xm = median(x);
        v = median(abs(x - xm));
    end
end
