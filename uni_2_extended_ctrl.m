function [snips, idx] = uni_2_extended_ctrl(uni, idx, n_samples, options)
%UNI_2_EXTENDED_CTRL Convert unipolar array to extended features snippets array, specifically for "control" snippets

arguments
    uni (64,:) double
    idx {mustBePositive, mustBeInteger}
    n_samples {mustBePositive, mustBeInteger} = 2500;
    options.ExcludedChannels {mustBePositive, mustBeInteger} = [];
    options.AdditionalExcludedSamples {mustBePositive, mustBeInteger} = [];
    options.Vector {mustBeInteger} = -10:10; % Times for extended samples matrix
end

available_idx = (1-options.Vector(1)):(size(uni,2)-options.Vector(end));
available_idx = setdiff(available_idx, union(reshape(idx,1,numel(idx)),options.AdditionalExcludedSamples));
idx = randsample(available_idx,min(n_samples,numel(available_idx)),false);

uni_d = uni - [zeros(64,1), uni(:,(1:(end-1)))];
uni_d(:,1) = zeros(64,1);

n = numel(idx);
idx = reshape(idx,n,1);
mask = idx + options.Vector;
i_remove = any(mask<1,2) | any(mask>size(uni,2),2);
idx(i_remove) = [];
mask(i_remove,:) = [];
n = numel(idx);
ch = setdiff(1:64,options.ExcludedChannels);
nCh = numel(ch);
nT = numel(options.Vector);
snips = nan(n, nCh*nT);
for iCh = 1:nCh
    data = uni_d(iCh,:);
    snips(:,(1+(iCh-1)*nT):(iCh*nT)) = data(mask);
end

end