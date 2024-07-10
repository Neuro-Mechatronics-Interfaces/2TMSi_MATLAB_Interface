function mdl = train_ensemble_classifier(X, Y, options)
%TRAIN_ENSEMBLE_CLASSIFIER  Trains predictive classifier model that uses bagged trees on input envelope EMG samples (X) to get discrete gesture states (Y).
arguments
    X
    Y
    options.PlotConfusion (1,1) logical = true;
    options.ComputeAccuracy (1,1) logical = true;
    options.HoldOut (1,1) double {mustBeInRange(options.HoldOut,0,1)} = 0.5;
    options.NumLearningCycles (1,1) {mustBePositive, mustBeInteger} = 250;
    options.Title {mustBeTextScalar} = '';
end

cv = cvpartition(Y, 'HoldOut', options.HoldOut);
XTrain = X(training(cv), :);
YTrain = Y(training(cv));
XTest = X(test(cv), :);
YTest = Y(test(cv));

% Train a classifier using an ensemble method (e.g., Bagged Trees)
mdl = fitcensemble(XTrain, YTrain, 'Method', 'Bag', ...
    'NumLearningCycles', options.NumLearningCycles);

if ~options.ComputeAccuracy
    return;
end
% Predict on the test set
YPred = predict(mdl, XTest);

% Evaluate the classifier's performance
accuracy = sum(YPred == YTest) / length(YTest);
fprintf('Accuracy: %.2f%%\n', accuracy * 100);

if ~options.PlotConfusion
    return;
end
% Confusion matrix to visualize performance
confusionchart(YTest, YPred, 'Title', options.Title, ...
    'ColumnSummary', 'column-normalized', ...
    'RowSummary', 'row-normalized');
set(gcf,'Color','w','WindowState','maximized');

end