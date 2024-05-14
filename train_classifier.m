function [net,meta] = train_classifier(samples, options)
%TRAIN_CLASSIFIER Train softmaxlayer classifier for MUAPs spike detection
arguments
    samples (64,:) double
    options.RMSThreshold (1,2) double = [1,100];
    options.PerChannelThreshold (1,64) double = ones(64,1).*15;
    options.ApplyDiscreteLaplacian (1,1) logical = true;
    options.MaxClustersInitial (1,1) {mustBePositive, mustBeInteger} = 20;
    options.MaxClustersFinal (1,1) {mustBePositive, mustBeInteger} = 12;
    options.MaxAllowedFR (1,1) {mustBePositive, mustBeInteger} = 50; % Spikes/sec
    options.NPCsFeatures (1,1) {mustBePositive, mustBeInteger} = 12;
    options.AssumeMeanFR (1,1) {mustBeNumeric, mustBePositive} = 20; % Spikes/sec
    options.SampleRate (1,1) {mustBeNumeric, mustBePositive} = 4000; % Samples/sec
    options.ShowProgressWindow (1,1) logical = false;
end

meta = struct;
meta.channels = struct;
r = rms(samples,2);
meta.channels.exclude_pre = find((r < options.RMSThreshold(1)) | (r >= options.RMSThreshold(2)));
meta.channels.keep_pre = setdiff(1:64,meta.channels.exclude_pre);
samples(meta.channels.exclude_pre,:) = nan;
if options.ApplyDiscreteLaplacian
    samples = reshape(del2(reshape(samples,8,8,[])),64,[]);
    meta.channels.exclude_post = find(isnan(samples(:,1)));
    meta.channels.keep_post = setdiff(1:64,meta.channels.exclude_post);
else
    meta.channels.exclude_post = meta.channels.exclude_pre;
    meta.channels.keep_post = meta.channels.keep_pre;
end
locs = cell(numel(meta.channels.keep_post), 1);
for iCh = 1:numel(meta.channels.keep_post)
    locs{iCh} = find(abs(samples(meta.channels.keep_post(iCh),:)) > options.PerChannelThreshold(iCh));
    if ~isempty(locs{iCh})
        locs{iCh} = locs{iCh}([true, diff(locs{iCh})>1]);
    end
end
meta.peak_indices = unique(horzcat(locs{:}));
t_collection = diff([min(meta.peak_indices), max(meta.peak_indices)]./options.SampleRate);
n_collected = numel(meta.peak_indices);
total_rate = n_collected/t_collection;
expected_n_clusters = ceil(total_rate / options.AssumeMeanFR);
n_clusters = min(options.MaxClustersInitial, expected_n_clusters);
meta.features = samples(meta.channels.keep_post,meta.peak_indices);
% data.tsne = tsne(data.features');
[meta.coeff, meta.score] = pca(meta.features');
clus_unsort = kmeans(meta.score(:,options.NPCsFeatures), n_clusters);
clus = nan(size(clus_unsort));
n = nan(expected_n_clusters,1);
for ii = 1:expected_n_clusters
    n(ii) = sum(clus_unsort == ii);
end
[n,idx] = sort(n,'descend');
iGood = 0;
for ii = 1:n_clusters
    rate_clus = n(ii) / t_collection;
    if rate_clus > options.MaxAllowedFR
        clus(clus_unsort == idx(ii)) = zeros(n(ii),1);
    else
        iGood = iGood + 1;
        clus(clus_unsort == idx(ii)) = ones(n(ii),1).*iGood;
    end
end
iBad = (clus == 0) | (clus > options.MaxClustersFinal);
clus(iBad) = ones(sum(iBad),1).*(min(iGood,options.MaxClustersFinal)+1); 
meta.targets = dummyvar(clus)';
net = trainSoftmaxLayer(meta.features,meta.targets,...
    "ShowProgressWindow",options.ShowProgressWindow);
end