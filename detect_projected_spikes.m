function [rate, neo] = detect_projected_spikes(samples, transform, threshold, car_mode, sample_rate, art_thresh)
%DETECT_PROJECTED_SPIKES  Detect spikes on each row of samples and return number of detections.
arguments
    samples (:,:) double
    transform (:,:) double
    threshold (1,:) double;
    car_mode (1,1) double {mustBeMember(car_mode, [0, 1, 2])}
    sample_rate (1,1) double = 4000
    art_thresh (1,1) double {mustBeInRange(art_thresh, 0, 1)} = 0.4
end

if car_mode > 0
    samples = apply_car(samples, car_mode, 1);
end
neo = (samples(:, 3:end).^2 - samples(:, 1:(end-2)).^2)';
neo = neo * transform;
supra = neo > threshold;
nCol = size(supra,2);
nSamples = size(samples,2);
art_mask = sum(supra,2) > (art_thresh * nCol);
supra(art_mask,:) = zeros(sum(art_mask), nCol);
rate = sum(supra, 1)./(nSamples ./ sample_rate);

end