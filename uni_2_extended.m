function [snips, idx] = uni_2_extended(uni, idx, options)
%UNI_2_EXTENDED Convert unipolar array to extended features snippets array

arguments
    uni (64,:) double
    idx {mustBePositive, mustBeInteger}
    options.ExcludedChannels {mustBePositive, mustBeInteger} = [];
    options.Vector {mustBeInteger} = -20:15; % Times for extended samples matrix
end

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