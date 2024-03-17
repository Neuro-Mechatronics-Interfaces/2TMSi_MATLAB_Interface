function data = apply_car(data, car_mode, dim)
%APPLY_CAR  Handles application of common average reference (CAR)
%
% Syntax:
%   data = apply_car(data, car_mode, dim);
%
% Inputs:
%   data - nChannels x nSamples array (use dim = 1) or nSamples x nChannels array (use dim = 2).
%   car_mode - 0 - No CAR (just return input data). 1 - Remove CAR using whole array. 2 - Remove CAR but split array into two parts.
%   dim - 1 (def) - Remove CAR using mean of rows. 2 - Remove CAR using mean of columns.
%
% Output:
%   data - Input data, handled according to car_mode.
%   
% See also: Contents,
%   deploy__tmsi_stream_service_plus_spike_detection_plus_gui, 
%   detect_spikes

arguments
    data (:, :) double % If it is nChannels x nSamples, use dim = 1; if it is nSamples x nChannels, use dim = 2.
    car_mode (1,1) double {mustBeInteger, mustBeMember(car_mode, [0, 1, 2])} % 0 - No CAR (just return input data). 1 - Remove CAR using whole array. 2 - Remove CAR but split array into two parts.
    dim (1,1) double {mustBeInteger, mustBeMember(dim, [1, 2])} = 1 % 1 - Remove CAR using mean of rows. 2 - Remove CAR using mean of columns.
end

switch dim
    case 1
        switch car_mode
            case 1
                data = data - mean(data,1);
            case 2
                data = nan(size(data));
                data(1:32,:) = data(1:32,:) - mean(data(1:32,:),1);
                data(33:64,:) = data(33:64,:) - mean(data(33:64,:),1);
        end
    case 2
        switch car_mode
            case 1
                data = data - mean(data,2);
            case 2
                data = nan(size(data));
                data(:,1:32) = data(:,1:32) - mean(data(:,1:32),2);
                data(:,33:64) = data(:,33:64) - mean(data(:,33:64),2);
        end
end

end