function [net, meta, input_data] = train_envelope_classifier_from_poly5(poly5_file, options)
%TRAIN_ENVELOPE_CLASSIFIER_FROM_POLY5  Trains envelope convolutional classifier network directly from poly5 file.
arguments
    poly5_file {mustBeTextScalar, mustBeFile}
    options.AutoSave (1,1) logical = true;
    options.Channels (1,:) {mustBePositive, mustBeInteger} = 1:64; % Should be UNI channels
    options.HPFCutoff (1,1) double = 100;
    options.HPFOrder (1,1) {mustBePositive, mustBeInteger} = 3;
    options.LPFCutoff (1,1) double = 1.5;
    options.LPFOrder (1,1) {mustBePositive, mustBeInteger} = 1;
    options.RMSThreshold (1,2) double = [1,100];
    options.ApplyDiscreteLaplacian (1,1) logical = true;
    options.FilterSize (1,1) {mustBePositive, mustBeInteger} = 4;
    options.FilterChannels (1,1) {mustBePositive, mustBeInteger} = 3;
    options.Stride (1,1) {mustBePositive, mustBeInteger} = 2;
    options.TrainingOptions = trainingOptions("adam");
    options.RestBit (1,1) {mustBeInteger} = 6;
end
data = TMSiSAGA.Poly5.read(poly5_file);
iTrig = contains({data.channels.name},'TRIG');
[p, f, ~] = fileparts(poly5_file);
finfo = strsplit(f, '_');
F = dir(fullfile(p, sprintf('%s_%s_%s_%s_instructionList_%s.mat', finfo{1}, finfo{2}, finfo{3}, finfo{4}, finfo{6})));
if isempty(F)
    labelsFile = [];
else
    labelsFile = fullfile(F.folder, F.name);
end
[S, labels, Y, instructionList] = parse_instruction_triggers(data.samples(iTrig,:), ...
    'LabelsFile', labelsFile, ...
    'RestBit', options.RestBit);
[net, meta, input_data] = train_envelope_classifier(data.samples(options.Channels,:), ...
    labels, ...
    'HPFCutoff', options.HPFCutoff, ...
    'HPFOrder', options.HPFOrder, ...
    'LPFCutoff', options.LPFCutoff, ...
    'LPFOrder', options.LPFOrder, ...
    'RMSThreshold', options.RMSThreshold, ...
    'ApplyDiscreteLaplacian', options.ApplyDiscreteLaplacian, ...
    'FilterSize', options.FilterSize, ...
    'FilterChannels', options.FilterChannels, ...
    'Stride', options.Stride, ...
    'TrainingOptions', options.TrainingOptions, ...
    'SampleRate', data.sample_rate);

if options.AutoSave
    [p,f,~] = fileparts(poly5_file);
    net_file_out = fullfile(p, sprintf('%s_envelope-classifier-parameters.mat', f));
    save(net_file_out, 'meta', 'options', 'S', 'labels', 'instructionList', 'Y', '-v7.3');
    net_file_out = fullfile(p, sprintf('%s_envelope-classifier.mat', f));
    Net = net;
    Channels = meta.channels.keep_post;
    ExcludeChannels = meta.channels.exclude_post;
    save(net_file_out,'Net','Channels','ExcludeChannels','-v7.3');
end


end