function varargout = parameters(varargin)
%PARAMETERS Return parameters struct, which sets default values for things like epoch durations etc.
%
% Example 1
%   pars = parameters(); % Returns full "default parameters" struct.
%
% Example 2
%   pars = parameters('fc', [3, 30]); % Returns full "default parameters" struct, and changes default fc to [3, 30].
%
% Example 3
%   f = parameters('raw_data_folder'); % Returns raw data folder value
% %
% I tried to pull the key parameters, which are really path information
% from your local mapping to where the raw data is and where any
% auto-exported figures/data objects should go. Both
% `generated_data_folder` and `raw_data_folder` should be the folder that
% contains "animal name" folders (e.g. the folder with `Forrest` in it). 
%
% See also: Contents, io.load_tmsi_raw, plot.emg_averages

pars = struct;

% pars.config = strrep(fullfile(pwd, 'config.yaml'),'\','/');
% pars.config = strrep(fullfile(pwd, 'Forrest_2022_11_08_config.yaml'), '\', '/');
% pars.config = strrep(fullfile(pwd, 'Local_Testing_config.yaml'), '\', '/');

% % % Trying to pull the "relevant" ones to the top ... % % %
% pars.config = "configurations/acquisition/config_125k.yaml";
pars.config = "configurations/acquisition/config_cart.yaml";
pars.config_stream_service_plus = "configurations/acquisition/config_vr.yaml";
% pars.config_stream_service_plus = "configurations/acquisition/config_115L.yaml";
pars.saga_file = 'configurations/devices/SAGA.json';
pars.instructions_folder = 'configurations/instructions';
% pars.generated_data_folder =  strrep('C:\Users\NML\Box\N3_SharpFocus\Phase 3 experiments\generated_data', '\', '/'); % Setting this to human or primate, temporary hard code
% pars.raw_data_folder = strrep('C:\Users\NML\Box\N3_SharpFocus\Phase 3 experiments\raw_data', '\', '/');
% pars.generated_data_folder =  strrep('R:\NMLShare\generated_data\human\DARPA_N3', '\', '/'); % Setting this to human or primate, temporary hard code
pars.generated_data_folder =  strrep('R:\NMLShare\generated_data\primate\DARPA_N3\N3_Patch', '\', '/'); % Setting this to human or primate, temporary hard code
% pars.generated_data_folder =  strrep('C:\Temp_Save\generated_data', '\', '/'); % Local for Forrest_2023_03_06
% pars.raw_data_folder = strrep('R:\NMLShare\raw_data\human', '\', '/');
pars.raw_data_folder = strrep('R:\NMLShare\raw_data\primate', '\', '/');
% pars.raw_data_folder = strrep('C:\Temp_Save\raw_data', '\', '/'); % Local for Forrest_2023_03_06
pars.preliminary_output_folder = strrep(fullfile(pars.generated_data_folder, '.preliminary'), '\', '/'); % . prefix defaults to "Hidden" on Windows

pars.default_training_log_file = 'G:\Shared drives\NML_NHP\Monkey Training Records\Training.xlsx';
pars.default_metadata_file = fullfile(pars.raw_data_folder, "Forrest", 'metadata.xlsx');
pars.local_pat_log_folder = "D:\__Assets__\Data\20220503 actual";
pars.local_volumes_folder = "D:\__Assets__\Data\20220503_theoretical";
pars.local_simulated_3d_surfaces_folder = "D:\__Assets__\temp\generated_data\N3_Patch\.preliminary\Volumes\Pattern-IsoSurfaces\Jz\Data";
pars.max_brain_mesh_folder = "D:/__Assets__/MRI/_SLICER3D_/Spencer/06_Output";
pars.frame_dir = 'D:/__Assets__/temp/generated_data/N3_Patch/.preliminary/Brain-Pattern-Volume-Overlays/Individual';
pars.vid_dir = 'D:/__Assets__/temp/generated_data/N3_Patch/.preliminary/Brain-Pattern-Volume-Overlays';
pars.monkey_arms_dir = 'G:/Shared drives/NML_NHP/Generic Images/Monkey Cartoons';
pars.version = "3.0.0"; % "Version" of repo code

% % Depending on functions that are used, some of the below parameters may
% be deprecated as the organization of this repo has changed numerous
% times....sorry! (MM - 2022-02-2) % % % % % % % % % %
% pars.patch_clim = nan;
pars.patch_clim = [-15, 15];
% pars.simulated_field_clim = [0 30];
pars.simulated_field_clim = [0 2.5];

% Annotation parameters
pars.trigger_channel_name = 'TRIGGERS';
pars.sync_indicator_bit = 10;  % Which bit on TRIGGERS or STATUS indicates sync trigger?
pars.sync_missing_backup_strategy = 'mean'; % Cases: 'mean' (all unip) | 'unip' | 'bip'
pars.sync_missing_backup_channel = 1;
pars.pulse_width = nan;     % (sec)
pars.pulse_amplitude = nan; % (mV)
pars.burst_period = 1;      % (sec)
pars.muscle_name = '';
% Snips parameters
pars.snip_epoch_pre = -0.020; % (sec)
pars.snip_epoch_post = 0.100; % (sec)

% Folder parameters (possibly deprecated)
pars.data_folder = pars.raw_data_folder; % Because I don't remember if removing this breaks other functions
pars.figures_folder = 'figures';
pars.tmsi_tools_folder = 'R:\NMLShare\analysis\_shared\TMSi_SAGA\MATLAB';
pars.plexon_tools_folder = 'R:\NMLShare\analysis\_shared\Plexon_Tools';
pars.raw_matfiles_folder = ".raw_channels";
pars.raw_matfiles_expr = "%s_RAW_%%d.mat";
pars.events_file_expr = "%s_EVENTS.mat";
pars.meta_file_expr = "%s_META.mat";
pars.alignment_parent_folder = ".aligned";
pars.alignment_folder = struct( ...
    'MOVE_ONSET', ".move", ...
    'T1_HOLD_ONSET', ".t1", ...
    'T2_HOLD_ONSET', ".t2", ...
    'OVERSHOOT_ONSET', ".overshoot", ...
    'REWARD_ONSET', ".reward");
pars.mongo.server = "localhost";
pars.mongo.port = 27017;
pars.mongo.dbname = "wrist";
pars.version = 3.3; % "Version" of utils/parameter repo code

% Filtering and acquisition parameters
pars.f_order = 2;       % Use fourth-order butterworth filter
% pars.f_type = 'bandpass';
% pars.fc = [3, 100];    % Passband cutoff frequencies ([lower, upper], Hz)
pars.f_type = 'high';   % High-pass filter to remove any DC bias.
pars.fc = 30; % Hz
pars.fs = 5000;         % Sample rate (Hz) of AuxAI device
pars.stim_event_source = 9; % Source index
pars.burst_name = "EVT11";  % Event timestamp name for Burst events
pars.burst_channel = 11;    % Burst event channel index
pars.pulse_name = "EVT12";  % Event timestamp name for Pulse events
pars.pulse_channel = 12;    % Pulse event channel index
% Plotting parameters
pars.data_only = false; % Set true to only save data in make_sta
pars.min_pk_height = nan; % Peak height (mV) minimum
pars.min_delay = 0.007; % Seconds, minimum delay expected for stimulus travel
pars.max_delay = 0.050; % Seconds, maximum delay for stimulus response peak
pars.exemplar_emg_duration_long = 4;       % Duration (seconds)
pars.exemplar_emg_duration_short = 0.080;  % Duration (seconds)
pars.y_scale_emg = [-25 25];        % Amplitude (y-axis, mV)
pars.x_scale_emg = [-10 50];        % Timescale (x-axis, ms)

% Colors (Think this is mostly behavioral-data-related)
pars.c.primary = validatecolor('#347bed');
pars.c.secondary = validatecolor('#335791');
pars.c.stim = validatecolor('#c9741e');
pars.c.peak = validatecolor('#1fb53f');
pars.c.ED45 = validatecolor("#55ede6");
pars.c.ED23 = validatecolor("#ee4266");
pars.c.Biceps = validatecolor("#7A9e7e");
pars.c.EDC = validatecolor("#D36135");
pars.c.ECU = validatecolor("#E6AA68");

% RMS parameters
pars.RMS = struct;
pars.RMS.FigureFolder = fullfile(pwd, 'figures', 'RMS');
pars.RMS.FileTag = '';
% pars.RMS.CLim = [2.5 7];
pars.RMS.CLim = [nan nan];
pars.RMS.AxLim = [0.5 8.5];
pars.RMS.RMSThresh = 5;
pars.RMS.ImpedanceThresh = 150; % kOhms
pars.RMS.Colormap = cm.map('state');
pars.RMS.Colorscale = 'linear';
pars.RMS.Tag = '';

% SlidingRMS parameters
pars.SlidingRMS = struct;
pars.SlidingRMS.FigureFolder = fullfile(pwd, 'figures', 'RMS');
pars.SlidingRMS.FileTag = '';
% pars.SlidingRMS.CLim = [2.5 7];
pars.SlidingRMS.CLim = [nan nan];
pars.SlidingRMS.AxLim = [0.5 8.5];
pars.SlidingRMS.RMSThresh = 5;
pars.SlidingRMS.ImpedanceThresh = 150; % kOhms
pars.SlidingRMS.Colormap = cm.map('rosette');
pars.SlidingRMS.Colorscale = 'linear';
pars.SlidingRMS.Tag = '';


% NNMF parameters
pars.NNMF = struct;
pars.NNMF.FigureFolder = fullfile(pwd, 'figures', 'NNMF');
pars.NNMF.FileTag = '';
pars.NNMF.CLim = [nan nan];
pars.NNMF.AxLim = [0.5 8.5];
pars.NNMF.RMSThresh = 5;
pars.NNMF.ImpedanceThresh = 150; % kOhms
pars.NNMF.Colormap = cm.map('rosette');
pars.NNMF.Colorscale = 'linear';
pars.NNMF.Tag = '';

% Impedance parameters
pars.Impedance.DataFolder = pars.raw_data_folder;
pars.Impedance.FigureFolder = pars.generated_data_folder;
pars.Impedance.FileTag = '';
pars.Impedance.CLim = [0 150]; % kOhms
pars.Impedance.AxLim = [0.5 8.5];
pars.Impedance.Colormap = cm.map('greenred'); % Like TMSi one
pars.Impedance.Colorscale = 'log';

% HD_EMG_Plotter parameters
% pars.Plotter.FigureFolder = fullfile(pwd, 'figures', 'Responses');
pars.Plotter.FileTag = '';
pars.Plotter.T_Lim_PCA = [13 45]; % time limits (ms) for PCA block

% HD_EMG parameters
pars.HD_EMG.ROWS = 8;  % Number of rows in EMG array grid
pars.HD_EMG.COLS = 8;  % Number of columns in EMG array grid
pars.HD_EMG.FC   = [10, 100]; % Default filter cutoffs ([low, high])
pars.HD_EMG.ORD  = 1;       % Default filter order
pars.HD_EMG.T_PRE  = 0.250; % (s) Time prior to onset triggers in sweeps
pars.HD_EMG.T_POST = 0.500; % (s) Time after onset triggers in sweeps
pars.HD_EMG.FILE_EXT = "_EMG-UNI.mat";  % File extension
pars.HD_EMG.FTYPE = 'bandpass'; % 'bandpass' | 'high'

% BIP_EMG parameters
pars.BIP_EMG.FC   = [2, 40]; % Default filter cutoffs ([low, high])
pars.BIP_EMG.ORD  = 1;       % Default filter order
pars.BIP_EMG.T_PRE  = 0.250; % (s) Time prior to onset triggers in sweeps
pars.BIP_EMG.T_POST = 0.500; % (s) Time after onset triggers in sweeps
pars.BIP_EMG.FILE_EXT = "_EMG-BIP.mat";  % File extension
pars.BIP_EMG.FTYPE = 'high'; % 'bandpass' | 'high'

% Accelereometer parameters
pars.Accelerometer.FC   = [2, 100]; % Default filter cutoffs ([low, high])
pars.Accelerometer.ORD  = 1;       % Default filter order
pars.Accelerometer.T_PRE  = 0.250; % (s) Time prior to onset triggers in sweeps
pars.Accelerometer.T_POST = 0.500; % (s) Time after onset triggers in sweeps
pars.Accelerometer.FILE_EXT = "_AUX-ACC.mat";  % File extension
pars.Accelerometer.FTYPE = 'bandpass'; % 'bandpass' | 'high'

% Plotting parameters
pars.Plotting.X_FAST = [-5 30];     % X-limits for fast timescale
pars.Plotting.N_SD = 1;             % Number of standard deviations to show on error overlays
pars.Plotting.RAND_CH_SUBSET_COLORS = [... % Number of elements in this vector of hex color codes sets N_CH_MAX
    "#aa6600"; ... % Gold
    "#006677"; ... % Teal
    "#224477"; ... % Blue
    "#008855"; ... % Green
    "#224433" ...  % Dark Green  (these 5 are from Carnegie Mellon Tartan secondary color scheme)
    ];
pars.Plotting.RMS_BIP = 50;         % Trial RMS threshold (microvolts); above this value, exclude trials (deprecated)
pars.Plotting.RMS_BIP_MED_DEVS_THRESHOLD = 2.0; % How many times median RMS of each trial must a trial be to consider as an outlier
pars.Plotting.MAX_ACC = 0.1;        % Maximum for any value in a given trial, above which it is excluded
pars.Plotting.MAX_UNI = 200;        % Maximum value for any given trial
pars.Plotting.N_TRIAL_TICKS = 5;    % Number of trial tick markers to allow
pars.Plotting.N_TRIALS_MAX  = 20;   % Maximum number of trials to plot (for visibility purposes). 
pars.Plotting.RECTIFY_BIP = true;   % Set to true to rectify bipolar emg plots
pars.Plotting.RESPONSE_W = [0.015 0.075];
pars.Plotting.OUT_PATH = '';
pars.Plotting.OUT_TAG = '';
pars.Plotting.PLOT_PCS = false;     % In plot_average(), plot PCs?

% Title parameters
pars.BlockTitle.Tag = 'Evoked EMG';
pars.BlockTitle.ContentFormat = 'Block-%02d: %3.2fmA | PW = %gms (@ %gpps) | BW = %gms';

% Features parameters
pars.Features.Short_RMS = [.013 .020]; % [start end] (sec)
pars.Features.Long_RMS = [.013 .045];  % [start end] (sec)

N = numel(varargin);
if nargout == 1
    if rem(N, 2) == 1
        varargout = {pars.(varargin{end})};
        return;
    else
        f = fieldnames(pars);
        for iV = 1:2:N
            idx = strcmpi(f, varargin{iV});
            if sum(idx) == 1
               pars.(f{idx}) = varargin{iV+1}; 
            end
        end
        varargout = {pars};
        return;
    end
else
    f = fieldnames(pars);
    varargout = cell(1, nargout);
    for iV = 1:numel(varargout)
        idx = strcmpi(f, varargin{iV});
        if sum(idx) == 1
            varargout{iV} = pars.(f{idx}); 
        else
            error('Could not find parameter: %s', varargin{iV}); 
        end
    end
end

end
