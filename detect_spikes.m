function [n, neo] = detect_spikes(samples, transform, threshold)
%DETECT_SPIKES  Detect spikes on each row of samples and return number of detections.
arguments
    samples (:,:) double
    transform (:,:) double
    threshold (1,:) double;
end

neo = (samples(:, 3:end).^2 - samples(:, 1:(end-2)).^2)';
neo = neo * transform;
n = sum(neo > threshold, 1);

end