function [snips, idx, n_pc, n_ts] = scores_2_extended(scores, explained, idx, options)
%SCORES_2_EXTENDED Convert unipolar array to extended features snippets array

arguments
    scores (:,:) double
    explained (1,:) double
    idx {mustBePositive, mustBeInteger}
    options.VarianceCapturedThreshold (1,1) {mustBeInRange(options.VarianceCapturedThreshold,0,100)} = 90; % Percent
    options.Vector {mustBeInteger} = -10:10; % Times for extended samples matrix
end

exp_tot = cumsum(explained);
n_pc = find(exp_tot > options.VarianceCapturedThreshold, 1, 'first');
n_ts = numel(options.Vector);

n = numel(idx);
idx = reshape(idx,n,1);
mask = idx + options.Vector;
i_remove = any(mask<1,2) | any(mask>size(scores,1),2);
idx(i_remove) = [];
mask(i_remove,:) = [];
% n = numel(idx);

% snips = nan(n, n_pc * n_ts);
% for ii = 1:n_pc
%     data = scores(:,ii);
%     snips(:,(1+(ii-1)*n_ts):(ii*n_ts)) = data(mask);
% end
snips = scores(mask);

end