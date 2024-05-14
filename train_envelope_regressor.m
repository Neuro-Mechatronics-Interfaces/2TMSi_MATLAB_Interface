function [net, meta, input_data] = train_envelope_regressor(samples, Y, options)
%TRAIN_ENVELOPE_REGRESSOR Train/implement envelope regression using 2Dconv neural network architecture.
arguments
    samples (64,:) double
    Y (:,:) double 
    options.HPFCutoff (1,1) double = 100;
    options.HPFOrder (1,1) {mustBePositive, mustBeInteger} = 3;
    options.LPFCutoff (1,1) double = 1.5;
    options.LPFOrder (1,1) {mustBePositive, mustBeInteger} = 1;
    options.RMSThreshold (1,2) double = [1,100];
    options.ApplyDiscreteLaplacian (1,1) logical = true;
    options.FilterSize (1,1) {mustBePositive, mustBeInteger} = 4;
    options.FilterChannels (1,1) {mustBePositive, mustBeInteger} = 3;
    options.SampleRate (1,1) {mustBePositive} = 4000;
    options.Stride (1,1) {mustBePositive, mustBeInteger} = 2;
    options.TrainingOptions = trainingOptions("adam");
end
if size(Y,2) ~= size(samples,2)
    error("Must have same number of data samples (columns) as columns of regression targets in Y.");
end
meta = struct;
meta.channels = struct;
meta.filter = struct;
meta.sample_rate = options.SampleRate;

[meta.filter.b_hpf, meta.filter.a_hpf] = butter(options.HPFOrder, options.HPFCutoff / (meta.sample_rate/2), 'high');
[meta.filter.b_env, meta.filter.a_env] = butter(options.LPFOrder, options.LPFCutoff / (meta.sample_rate/2), 'low');
samples = filter(meta.filter.b_hpf, meta.filter.a_hpf, samples,[],2);
samples(:,1:100) = 0;


r = rms(samples,2);
meta.channels.exclude_pre = find((r < options.RMSThreshold(1)) | (r >= options.RMSThreshold(2)));
meta.channels.keep_pre = setdiff(1:64,meta.channels.exclude_pre);

samples = filter(meta.filter.b_env, meta.filter.a_env, abs(samples), [], 2);
samples(meta.channels.exclude_pre,:) = nan;
if options.ApplyDiscreteLaplacian
    samples = reshape(del2(reshape(samples,8,8,[])),64,[]);
    meta.channels.exclude_post = find(isnan(samples(:,1)));
    meta.channels.keep_post = setdiff(1:64,meta.channels.exclude_post);
else
    meta.channels.exclude_post = meta.channels.exclude_pre;
    meta.channels.keep_post = meta.channels.keep_pre;
end
samples(meta.channels.exclude_post,:) = 0;
input_data = reshape(samples,8,8,1,[]);

layers = [
    imageInputLayer([8 8 1])
    convolution2dLayer(options.FilterSize,options.FilterChannels,'Stride',options.Stride)
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2)
    fullyConnectedLayer(size(Y,1))
    regressionLayer];
opts = options.TrainingOptions;
net = trainNetwork(input_data, Y', layers, opts);
end