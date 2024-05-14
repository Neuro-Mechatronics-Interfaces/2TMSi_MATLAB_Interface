function [snips, idx] = uni_2_concatenated_snips(uni, idx, options)
%UNI_2_CONCATENATED_SNIPS Convert unipolar array to concatenated snippets array
%
% Output:
%   snips - (nRelativeTimeSamples * nPulses) x nChannels
arguments
    uni (:,:) double
    idx {mustBePositive, mustBeInteger}
    options.ExcludedChannels {mustBePositive, mustBeInteger} = [];
    options.Vector (1,:) {mustBeInteger} = -15:15; % Times for extended samples matrix
end
nch = size(uni,1);

n = numel(idx);
idx = reshape(idx,1,n);
mask = idx + options.Vector';
i_remove = any(mask<1,1) | any(mask>size(uni,2),1);
idx(i_remove) = [];
mask(:,i_remove) = [];
mask = mask(:);
n = numel(idx);
ch = setdiff(1:nch,options.ExcludedChannels);
nCh = numel(ch);
nT = numel(options.Vector);
snips = nan(n*nT, nCh);
for iCh = 1:nCh
    data = uni(iCh,:);
    snips(:,iCh) = data(mask);
end

end