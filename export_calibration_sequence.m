function [target_data, target_times] = export_calibration_sequence(time_knots, calibration_knots, options)
%EXPORT_CALIBRATION_SEQUENCE Generate uniformly-sampled calibration sequences from knotted multi-variate time-series.
%
% Syntax:
%   export_calibration_sequence(time_knots, calibration_knots);
%   export_calibration_sequence(...,'Name',value, ...);
%   [target_data,target_times] = export_calibration_sequence(...);
%
% Inputs:
%   time_knots - Times (seconds) for each of the rows in calibration_knots
%   calibration_knots - nKnots x nVars data array indicating what target calibration sequences should do.
%
% Output:
%   target_data - The nSamples (N) x nVars (M)
%   target_times - Times at which target_data are sampled
%
%   Exports uniformly-sampled N x M data target array
%   `target_data` to the file specified by `OutputFile` option. The number
%   of samples depends on the `SampleRate` option. Note that this value
%   should be set to match the value expected of the TMSiSAGA service--it
%   also is not the case that every single sample is used to render update
%   frames on the calibration GUI but rather only the latest sample as
%   indicated by the current sample counter in the calibration portion of
%   the stream service (i.e. depending on number of samples read from the
%   USB interface in each loop iteration, that will be the amount that is
%   "jumped" in the pre-loaded target variable data sample array).
%
%   By default, the interpolation is a modified akima spline, but can be
%   set by 'Method' option to any of 'makima','linear','spline','pchip',  
%   'cubic', 'v5cubic', 'nearest', 'next', or 'previous'.
%
% See also: Contents, init_calibration_gui,
%           deploy__tmsi_stream_service_plus_spike_detection_plus_gui
arguments
    time_knots        (:,1) single % Times (seconds)
    calibration_knots (:,:) single % 
    options.ClipToUnity (1,1) logical = true;
    options.KnotControlMode {mustBeTextScalar, mustBeMember(options.KnotControlMode,{'position','velocity','acceleration'})} = 'position';
    options.LPFCutoff (1,1) double = 4;
    options.Method {mustBeTextScalar, mustBeMember(options.Method,{'makima','linear','pchip','cubic','v5cubic','spline','nearest','next','previous'})} = 'makima';
    options.NSecondsToShow (1,1) double = 0.5; % How much of the upcoming signal should be shown?
    options.OutputFile {mustBeTextScalar} = "configurations/calibration/2DOF_Basic.mat";
    options.PostBufferTime (1,1) double {mustBeGreaterThanOrEqual(options.PostBufferTime,0)} = 1; % Seconds to add at end
    options.SampleRate (1,1) double {mustBePositive} = 4000;
end

[time_knots, idx] = sort(time_knots, 'ascend');
calibration_knots = calibration_knots(idx,:);
sample_rate = options.SampleRate;
if options.PostBufferTime > 0
    time_knots(end+1) = time_knots(end) + options.PostBufferTime;
    calibration_knots(end+1,:) = calibration_knots(end,:);
end
sample_knots = time_knots .* sample_rate;
N = sample_knots(end);
M = size(calibration_knots,2);
sample_index = (1:N)';
target_times = sample_index ./ sample_rate;

switch options.KnotControlMode
    case 'position'
        sample_index = (1:N)';
        target_data = nan(N, M);
        for ii = 1:M
            target_data(:,ii) = interp1(sample_knots,calibration_knots(:,ii),sample_index,options.Method);
        end
    case 'velocity'
        target_data = nan(N, M*2);
        for ii = (M+1):(2*M) % Velocity state
            target_data(:,ii) = interp1(sample_knots,calibration_knots(:,ii-M),sample_index,options.Method);
        end
        for ii = 1:M % Position state
            target_data(:,ii) = trapz(target_data(:,ii+M));
        end
        M = M * 2;
    case 'acceleration'
        target_data = nan(N, 3*M);
        for ii = (2*M+1):(3*M) % Acceleration state
            target_data(:,ii) = interp1(sample_knots,calibration_knots(:,ii-2*M),sample_index,options.Method);
        end
        for ii = (M+1):(2*M) % Velocity state
            target_data(:,ii) = trapz(target_data(:,ii+M));
        end
        for ii = 1:M % Position state
            target_data(:,ii) = trapz(target_data(:,ii+M));
        end
        M = M * 3;
end

[b,a] = butter(3,options.LPFCutoff./(sample_rate/2),'low');
target_data = filtfilt(b,a,target_data);
if options.ClipToUnity
    target_data = max(target_data,-1);
    target_data = min(target_data,1);
end
current_samples = 1:floor(options.NSecondsToShow * sample_rate);
control_mode = options.KnotControlMode;
use_feedback = false;

[p,~,~] = fileparts(options.OutputFile);
if exist(p,'dir')==0
    mkdir(p);
end
save(options.OutputFile,'target_times','target_data','N','M','sample_rate', 'sample_index', 'current_samples', 'control_mode', 'use_feedback', '-v7.3');

end