function [n, neo] = detect_spikes(samples, transform, threshold, apply_car)
%DETECT_SPIKES  Detect spikes on each row of samples and return number of detections.
arguments
    samples (:,:) double
    transform (:,:) double
    threshold (1,:) double;
    apply_car (1,1) logical
end

if apply_car
    samples = samples - mean(samples,2);
end
neo = (samples(:, 3:end).^2 - samples(:, 1:(end-2)).^2)';
neo = neo * transform;
n = sum(neo > threshold, 1);

end