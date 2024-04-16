function [net,data] = train_classifier(samples, options)
%TRAIN_CLASSIFIER Train softmaxlayer classifier for MUAPs spike detection
arguments
    samples (64,:) double
    options.MinRMSThreshold (1,1) double = 1;
    options.PerChannelThreshold (1,64) double = ones(64,1).*7.5;
    options.ApplyDiscreteLaplacian (1,1) logical = true;
    options.AssumeMeanFR (1,1) {mustBeNumeric, mustBePositive} = 30; % Spikes/sec
    options.SampleRate (1,1) {mustBeNumeric, mustBePositive} = 4000; % Samples/sec
    options.ShowProgressWindow (1,1) logical = false;
end

data = struct;
data.channels = struct;
data.channels.exclude_pre = find(rms(samples,2) < options.MinRMSThreshold);
data.channels.keep_pre = setdiff(1:64,data.channels.exclude_pre);
samples(data.channels.exclude_pre,:) = nan;
if options.ApplyDiscreteLaplacian
    samples = reshape(del2(reshape(samples,8,8,[])),64,[]);
    data.channels.exclude_post = find(isnan(samples(:,1)));
    data.channels.keep_post = setdiff(1:64,data.channels.exclude_post);
end
locs = cell(numel(data.channels.keep_post), 1);
for iCh = 1:numel(data.channels.keep_post)
    locs{iCh} = find(abs(samples(data.channels.keep_post(iCh),:)) > options.PerChannelThreshold(iCh));
    if ~isempty(locs{iCh})
        locs{iCh} = locs{iCh}([true, diff(locs{iCh})>1]);
    end
end
data.peak_indices = unique(horzcat(locs{:}));
t_collection = diff([min(data.peak_indices), max(data.peak_indices)]./options.SampleRate);
n_collected = numel(data.peak_indices);
total_rate = n_collected/t_collection;
expected_n_clusters = ceil(total_rate / options.AssumeMeanFR);
data.features = samples(data.channels.keep_post,data.peak_indices);
data.tsne = tsne(data.features');
clus_unsort = kmeans(data.tsne, expected_n_clusters);
clus = nan(size(clus_unsort));
n = nan(expected_n_clusters,1);
for ii = 1:expected_n_clusters
    n(ii) = sum(clus_unsort == ii);
end
[n,idx] = sort(n,'descend');
for ii = 1:expected_n_clusters
    clus(clus_unsort == idx(ii)) = ones(n(ii),1).*ii;
end
data.targets = dummyvar(clus)';
net = trainSoftmaxLayer(data.features,data.targets,...
    "ShowProgressWindow",options.ShowProgressWindow);
end