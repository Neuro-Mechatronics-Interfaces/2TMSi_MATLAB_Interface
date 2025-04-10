clear;
clc;

% Parameters
numChannels = 128;
bufferSize = 4000;
dataLength = 512;
numIterations = 10000;

% Generate random data
data = double(single(rand(numChannels, dataLength)));

%% MATLAB circshift approach
buffer = single(rand(numChannels, bufferSize));

tic;
for i = 1:numIterations
    buffer = circshift(buffer, [0, -dataLength]);
    buffer(:, end-dataLength+1:end) = single(data);
end
elapsedTimeMatlab = toc;
fprintf('MATLAB circshift add time: %.5f seconds\n', elapsedTimeMatlab);

% Reading the most recent 200 samples from the buffer
numSamples = 200;
tic;
for i = 1:numIterations
    retrievedData = buffer(:, end-numSamples+1:end);
end
elapsedTimeMatlabRead = toc;
fprintf('MATLAB circshift read time: %.5f seconds\n', elapsedTimeMatlabRead);

%% MEX CircularBuffer approach
buf.CircleBufferMex('create', 'buffer1', numChannels, bufferSize);

tic;
for i = 1:numIterations
    buf.CircleBufferMex('add', 'buffer1', single(data(:)));
end
elapsedTimeMex = toc;
fprintf('MEX function add time: %.5f seconds\n', elapsedTimeMex);

% Reading the most recent 100 samples from the buffer
tic;
for i = 1:numIterations
    retrievedData = buf.CircleBufferMex('getMostRecent', 'buffer1', numSamples);
end
elapsedTimeMexRead = toc;
fprintf('MEX function read time: %.5f seconds\n', elapsedTimeMexRead);
