function [net, meta] = train_classifier_from_poly5(poly5_file, options)
%TRAIN_CLASSIFIER_FROM_POLY5  Trains spike softmaxlayer classifier directly from poly5 file.
arguments
    poly5_file {mustBeTextScalar, mustBeFile}
    options.AutoSave (1,1) logical = true;
    options.Channels (1,:) {mustBePositive, mustBeInteger} = 1:64; % Should be UNI channels
    options.HPFCutoff (1,1) double = 100;
    options.HPFOrder (1,1) {mustBePositive, mustBeInteger} = 3;
    options.RMSThreshold (1,2) double = [1,100];
    options.NPCsFeatures (1,1) {mustBePositive, mustBeInteger} = 12;
    options.MaxClustersInitial (1,1) {mustBePositive, mustBeInteger} = 20;
    options.MaxClustersFinal (1,1) {mustBePositive, mustBeInteger} = 12;
    options.MaxAllowedFR (1,1) {mustBePositive, mustBeInteger} = 50; % Spikes/sec
    options.PerChannelThreshold (1,64) double = ones(64,1).*11;
    options.ApplyDiscreteLaplacian (1,1) logical = false;
    options.AssumeMeanFR (1,1) {mustBeNumeric, mustBePositive} = 30; % Spikes/sec
    options.ShowProgressWindow (1,1) logical = false;
end
data = TMSiSAGA.Poly5.read(poly5_file);
[b,a] = butter(options.HPFOrder, options.HPFCutoff / (data.sample_rate/2), 'high');
filtered_samples = filter(b,a,data.samples(options.Channels,:),[],2);
filtered_samples(:,1:100) = 0;
[net,meta] = train_classifier(filtered_samples, ...
    'RMSThreshold', options.RMSThreshold, ...
    'PerChannelThreshold', options.PerChannelThreshold, ...
    'NPCsFeatures', options.NPCsFeatures, ...
    'MaxClustersInitial', options.MaxClustersInitial, ...
    'MaxClustersFinal', options.MaxClustersFinal, ...
    'MaxAllowedFR', options.MaxAllowedFR, ...
    'ApplyDiscreteLaplacian', options.ApplyDiscreteLaplacian, ...
    'AssumeMeanFR', options.AssumeMeanFR, ...
    'SampleRate', data.sample_rate, ...
    'ShowProgressWindow', options.ShowProgressWindow);
meta.sample_rate = data.sample_rate;
meta.filter = struct('b', b, 'a', a);

if options.AutoSave
    [p,f,~] = fileparts(poly5_file);
    net_file_out = fullfile(p, sprintf('%s_classifier-parameters.mat', f));
    save(net_file_out, 'meta', 'options', '-v7.3');
    net_file_out = fullfile(p, sprintf('%s_classifier.mat', f));
    Net = net;
    Channels = meta.channels.keep_post;
    MinPeakHeight = options.PerChannelThreshold;
    save(net_file_out,'Net','Channels','MinPeakHeight','-v7.3');
end


end