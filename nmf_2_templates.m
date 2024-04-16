function [snips, i_peaks] = nmf_2_templates(H,Yf,options)
arguments
    H
    Yf
    options.MinPeakHeight (1,1) double = 3.5;   % Times RMS
    options.MinPeakDistance (1,1) double = 125; % Samples
end
snips = cell(size(H,1),1);
i_peaks = cell(size(H,1),1);
for ii = 1:size(H,1)
    r = rms(H(ii,:).*1e3);
    [~,idx] = findpeaks(H(ii,:).*1e3,"MinPeakHeight",options.MinPeakHeight*r,"MinPeakDistance",options.MinPeakDistance);
    [snips{ii},i_peaks{ii}] = uni_2_extended(Yf,idx');
end
end