function [net,cv] = train_emg_envelope_net(X,Y,options)
arguments
    X
    Y
    options.RNGSeed = 1;
    options.HoldOutPortion = 0.2;
    options.NumHiddenUnits = 50;
    options.MaxTrainingEpochs = 5;
    options.MiniBatchSize = 32;
end
rng(options.RNGSeed); % Set random seed for reproducibility
cv = cvpartition(size(X, 1), 'HoldOut', options.HoldOutPortion); % 80% training, 20% testing
X_train = X(cv.training, :);
Y_train = Y(cv.training, :);
% X_test = X(cv.test, :);
% Y_test = Y(cv.test, :);

% Example: Train a feedforward neural network
hidden_units = options.NumHiddenUnits; % Number of hidden units in the neural network
layers = [
    featureInputLayer(size(X_train, 2))
    lstmLayer(hidden_units, 'OutputMode', 'last')
    fullyConnectedLayer(hidden_units)
    reluLayer
    fullyConnectedLayer(2) % Output layer (2 units for x and y coordinates)
    regressionLayer
];
options = trainingOptions('adam', ...
    'MaxEpochs', options.MaxTrainingEpochs, ...
    'MiniBatchSize', options.MiniBatchSize);
net = trainNetwork(X_train, Y_train, layers, options);
% Y_pred = predict(net, X_test);
% % Evaluate performance metrics (e.g., mean squared error)
% mse = mean((Y_test - Y_pred).^2);
% disp(['Mean Squared Error on Test Set: ', num2str(mse)]);
end