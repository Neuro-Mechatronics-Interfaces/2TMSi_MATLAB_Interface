function trainedNet = train_metawb_gesture_net(X, Y)

% Define sequence length for splitting
seqLength = 100;  % Adjust this based on your data

% Determine the total number of sequences
N = size(X, 2);
numSeq = floor(N / seqLength);

% Split X and Y into sequences
XSeq = cell(1, numSeq);
YSeq = cell(1, numSeq);
for i = 1:numSeq
    XSeq{i} = X(:, (i-1)*seqLength + 1 : i*seqLength);
    YSeq{i} = Y((i-1)*seqLength + 1 : i*seqLength);
end

% Split data into training and validation sets
numTrain = round(0.8 * numSeq);
idx = randperm(numSeq);
trainIdx = idx(1:numTrain);
valIdx = idx(numTrain+1:end);

XTrain = XSeq(trainIdx);
YTrain = YSeq(trainIdx);
XValidation = XSeq(valIdx);
YValidation = YSeq(valIdx);

% Convert YTrain and YValidation to categorical arrays
for i = 1:numel(YTrain)
    YTrain{i} = categorical(YTrain{i});
end
for i = 1:numel(YValidation)
    YValidation{i} = categorical(YValidation{i});
end

% Define the input layer
inputLayer = sequenceInputLayer(128, 'Name', 'input');

% Define the first fully connected layer with Leaky ReLU
fc1 = fullyConnectedLayer(256, 'Name', 'fc1');
leakyReLU = leakyReluLayer(0.01, 'Name', 'leakyrelu');

% Define the cascaded TDS blocks
tdsLayers = [];
numScales = 6;

for s = 0:numScales-1
    dilation = 2^s;
    tdsBlock1 = [
        convolution1dLayer(3, 256, 'DilationFactor', dilation, 'Padding', 'same', 'Name', ['conv' num2str(s) '_1']);
        reluLayer('Name', ['relu' num2str(s) '_1']);
    ];
    if s > 0
        addLayer = additionLayer(2, 'Name', ['add' num2str(s)]);
        tdsLayers = [tdsLayers; addLayer];
    end
    tdsBlock2 = [
        convolution1dLayer(3, 256, 'DilationFactor', dilation, 'Padding', 'same', 'Name', ['conv' num2str(s) '_2']);
        reluLayer('Name', ['relu' num2str(s) '_2']);
    ];
    tdsLayers = [tdsLayers; tdsBlock1; tdsBlock2];
end

% Define the remaining fully connected layers
fc2 = fullyConnectedLayer(256, 'Name', 'fc2');
fc3 = fullyConnectedLayer(256, 'Name', 'fc3');
fc4 = fullyConnectedLayer(3, 'Name', 'fc4');

% Define the softmax and classification layers
smaxLayer = softmaxLayer('Name', 'softmax');
classifierLayer = classificationLayer('Name', 'classification');

% Assemble the layers into a layer graph
layers = [
    inputLayer
    fc1
    leakyReLU
    tdsLayers
    fc2
    fc3
    fc4
    smaxLayer
    classifierLayer
];

% Create a layer graph
lgraph = layerGraph(layers);

% Connect the TDS block outputs to the appropriate addition layers
for s = 1:numScales-1
    lgraph = connectLayers(lgraph, ['conv' num2str(s-1) '_2'], ['add' num2str(s) '/in2']);
end

% Display the layer graph
plot(lgraph);

% Define the training options
options = trainingOptions('adam', ...
    'InitialLearnRate', 1e-3, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 25, ...
    'LearnRateDropFactor', 0.5, ...
    'MaxEpochs', 300, ...
    'MiniBatchSize', 128, ...
    'Shuffle', 'every-epoch', ...
    'ValidationFrequency', 30, ...
    'Plots', 'training-progress', ...
    'Verbose', false);

% Train the network
trainedNet = trainNetwork(XTrain, YTrain, lgraph, options);

end
