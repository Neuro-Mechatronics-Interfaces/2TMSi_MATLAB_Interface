function rate = detect_spikes(samples, threshold, sample_rate, art_thresh)
%DETECT_SPIKES  Detect spikes on each row of samples and return number of detections.
arguments
    samples (:,:) double
    threshold (1,:) double;
    sample_rate (1,1) double = 4000
    art_thresh (1,1) double {mustBeInRange(art_thresh, 0, 1)} = 0.4
end

supra = samples > threshold;
[nSamples,nCol] = size(samples);
art_mask = sum(supra,2) > (art_thresh * nCol);
supra(art_mask,:) = zeros(sum(art_mask), nCol);
rate = sum(supra, 1)./(nSamples ./ sample_rate);

end