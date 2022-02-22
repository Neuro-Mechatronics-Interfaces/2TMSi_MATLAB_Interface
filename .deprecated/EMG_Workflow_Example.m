%EMG_WORKFLOW_EXAMPLE - This example shows a workflow of an EMG measurement. 
%
%   Modified: Max Murphy (11/15/21)
%   -- NOTE -- The +TMSiSAGA package in this folder has been modified from
%   its original format (provided by TMSi). Be aware that this TMSiSAGA
%   library is DIFFERENT from the standard library provided by TMSi.
%
%
%   The workflow starts with an impedance check. This impedance check is 
%   stopped when the figure window is closed. 
%
%   Next, a heat map of the muscle activation is shown.  
%
%   Channels that are out of range are marked red, as this 
%   could indicate that the connection between electrode and skin are not 
%   good.
%
%   Visualisation functions work 64 channels ONLY. 

clear;
clc;

SUBJ = 'Frank';
REC_LOC = './testing/';
run_date = datestr(datetime('now'), 'yyyy_mm_dd');
run_time = datestr(datetime('now'), 'HH-MM-SS');
% Middle "%s" reserved for `device_tags(k)`
IMPEDANCE_FILE_EXPR = sprintf('%s_%s_%s_%%d - %s_%s.%s', ....
    SUBJ, run_date, '%s', 'impedances', run_time, 'mat'); % added
DATA_FILE_EXPR = sprintf('%s_%s_%s_%%d - %s_%s.%s', ...
    SUBJ, run_date, '%s', 'data', run_time, 'poly5');
NORMALIZATION = [0, 0];
N_DEVICE = 2;    % Number of connected devices.
SAGA_TYPE = 64;  % Number of unipolar inputs on electrode grids
% Direction the connector points to seen from an anterior view of the
% frontal plane ('left', 'down', 'right' and 'up')
CONN_ORIENTATION = {'down', 'down'};

% Filter configuration
FILTER_ORDER = 2;
FILTER_CUTOFF_FREQUENCY_HZ = 10; % Hz

% Window duration to save (for buffer).
WINDOW_DURATION_SEC = 0.25;

N_TRIGGERS_AVG = 20;
N_PRE_SAMPLES = 100;
N_POST_SAMPLES = 400;

% Measurement configuration
CONFIG_MEASUREMENT = struct(...
    'Triggers', true, ...
    'ImpedanceMode', false, ... 
    'ReferenceMethod', 'common', ...
    'AutoReferenceMethod', true, ...
    'BaseSampleRate', 4000, ...
    'Dividers', {{'uni', 0;}}, ...
    'RepairLogging', false);

if ~license('test', 'Signal_Toolbox')
    error('[MATLAB] This example requires the Signal Processing Toolbox to be installed')    
end

% Initialize the library
device_tags = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K"];
device_tags = device_tags(1:N_DEVICE);

%% INITIALIZE LIBRARY AND DETECT DEVICES
% Code within the try-catch to ensure that all devices are stopped and
% closed properly in case of a failure.
lib = TMSiSAGA.Library();

% Get a single device from the connected devices
device = lib.getDevices({'usb'}, {'electrical'});   
trig_channel = nan(1, numel(device));
for k = 1:numel(device)
    device(k).tag = device_tags(k);
    device(k).impedance_file_expr = IMPEDANCE_FILE_EXPR;
    device(k).data_file_expr = DATA_FILE_EXPR;
end

%% CONNECT TO EACH DEVICE, VIEW IMPEDANCES, AND SAVE
[imp_file_name, data_file_name] = get_new_names(device);
test_and_save_impedances(device, fullfile(REC_LOC, imp_file_name));

%% UPDATE DEVICE CONFIGS AND START EACH DEVICE & SAMPLE RECORD
sample_buffer = cell(1, N_DEVICE);
window_samples = nan(1, N_DEVICE);
% Create a Poly5 file storage

setDeviceConfig(device, CONFIG_MEASUREMENT);
poly5_file = TMSiSAGA.Poly5(fullfile(REC_LOC, data_file_name), ...
    [device.sample_rate], getActiveChannels(device));
for k = 1:N_DEVICE
    % Initialise the sample buffer and the window_size
    window_samples(k) = round(WINDOW_DURATION_SEC * device(k).sample_rate);
    sample_buffer{k} = zeros(numel(device(k).getActiveChannels()), window_samples(k), N_TRIGGERS_AVG);
    trig_channel(k) = find(contains(getName(device(k).getActiveChannels()), "TRIGGERS"), 1, 'first');
end
% 
% %% CREATE THE DATA VISUALIZER
% % Initialise the plotting object handle to be used in the workflow
% vPlot = TMSiSAGA.Visualisation(fig, ...
%     [device.sample_rate], getActiveChannels(device), window_samples, ...
%     NORMALIZATION, CONN_ORIENTATION);
fig_name = string(strsplit(sprintf('HD-EMG Array %s: Heatmap\r', device_tags(1:N_DEVICE)), '\r'));
fig = make_sta_figure(fig_name(1:N_DEVICE));

%% WITH DATA SAMPLING FROM BOTH DEVICES, REFRESH THE VISUAL WHEN FRAME FILLS UP
samples = cell(1, N_DEVICE);
num_sets = nan(1, N_DEVICE);
last_set = ones(1, N_DEVICE);
currentEvent = ones(1, N_DEVICE);

vec = -N_PRE_SAMPLES : N_POST_SAMPLES;
ts = vec ./ 4;
n_vec = numel(vec);

data_avg = cell(1, N_DEVICE);
N_RESID = N_TRIGGERS_AVG - 1;
frac = N_RESID / N_TRIGGERS_AVG;
for k = 1:N_DEVICE
    data_avg{k} = zeros(N_TRIGGERS_AVG, numel(vec)); 
end

start(device);
while all([fig.Visible] == 'on')
    [samples, num_sets, type] = sample(device);
    append(poly5_file, samples, num_sets);
    
    % Append samples to the plot and redraw
    for k = 1:N_DEVICE
        if num_sets(k) >= window_samples(k)
            sample_buffer{k} = circshift(sample_buffer{k}, num_sets(k));
            n = min(num_sets(k), window_samples(k));
            sample_buffer{k}(:, 1 : n) = samples{k}(:, 1 : n);
            trigs = sample_buffer{k}(trig_channel(k), :);
            if any(bitand(trigs, 1) == 0)
                stim = find(bitand(trigs, 1)==0, 1, 'first'); 
                data = circshift(sample_buffer{k}, 1 - stim + N_PRE_SAMPLES);
                data_avg{k} = frac*data_avg{k} + data(1:(N_PRE_SAMPLES + N_POST_SAMPLES + 1)) ./ N_TRIGGERS_AVG;
                for ii = 1:64
                    set(fig(k).UserData.line(ii), 'XData', ts, 'YData', data_avg{k}); 
                end
            end
        end
    end
    
end

%% CLEANUP INTERNAL DATA STORAGE BUFFER AND SHUTDOWN DEVICES
close(poly5_file);
stop(device);
disconnect(device); 

% clean up and unload the library
lib.cleanUp();
close all force;

disp('Exited EMG workflow successfully.');