function [mdl,classes,XTest,YTest,targets,env_data] = train_LSL_envelope_classifier(x, options)
%TRAIN_LSL_ENVELOPE_CLASSIFIER Train softmaxlayer classifier for MUAPs spike detection
arguments
    x struct % As loaded by `x = io.load_tmsi(...);` using 'lsl' option
    options.CutoffHPF (1,1) {mustBePositive, mustBeNumeric} = 100; % Hz
    options.CutoffEnv (1,1) {mustBePositive, mustBeNumeric} = 5; % Hz
    options.SampleRate (1,1) {mustBeNumeric, mustBePositive} = 4000; % Samples/sec
    options.HighTime (1,1) {mustBePositive} = 1; % Seconds
    options.HighOffset (1,1) double = 0.25; % Seconds
    options.BinWidth (1,1) {mustBePositive} = 0.030; % Seconds
    options.HoldOut (1,1) double {mustBeInRange(options.HoldOut,0,1)} = 0.5;
    options.NumLearningCycles (1,1) {mustBePositive, mustBeInteger} = 250;
    options.ShowProgressWindow (1,1) logical = false;
end

[b_hpf,a_hpf] = butter(3,options.CutoffHPF/(options.SampleRate/2),'high');
[b_env,a_env] = butter(3,options.CutoffEnv/(options.SampleRate/2),'low');

i_channel = contains({x.channels.name},'UNI');
uni = x.samples(i_channel,:);


hpf_data = filtfilt(b_hpf,a_hpf,uni');
env_data = filter(b_env,a_env,abs(hpf_data),[],1)';
env_data(:,1:100) = 0;

[G,classes] = findgroups(x.markers.gesture.Gesture);
nBin = floor(options.HighTime / options.BinWidth);

targets = [];
features = [];
for iG = 1:numel(G)
    mask = (x.t(1,:) >= (x.markers.gesture.Time(iG)+options.HighOffset)) & (x.t(1,:) < (x.markers.gesture.Time(iG)+options.HighOffset+options.HighTime));
    tmp_data = env_data(:,mask);
    i_bin = discretize(x.t(1,mask),nBin);
    for ik = 1:nBin
        bin_mask = i_bin == ik;
        features = [features, mean(tmp_data(:,bin_mask),2)]; %#ok<AGROW>
    end
    tmp = ones(1,nBin).*G(iG);
    targets = [targets, tmp]; %#ok<AGROW>
end

% targets = dummyvar(targets)';
% net = trainSoftmaxLayer(features,targets,...
%     "ShowProgressWindow",options.ShowProgressWindow);
Y = targets';
X = features';

cv = cvpartition(Y, 'HoldOut', options.HoldOut);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

% Train a classifier using an ensemble method (e.g., Bagged Trees)
mdl = fitcensemble(XTrain, YTrain, ...
    'Method', 'Bag', ...
    'NumLearningCycles', options.NumLearningCycles);
% Predict on the test set
YPred = predict(mdl, XTest);

% Evaluate the classifier's performance
accuracy = sum(YPred == YTest) / length(YTest);
fprintf('Accuracy: %.2f%%\n', accuracy * 100);

% Confusion matrix to visualize performance
confusionchart(YTest, YPred);

end