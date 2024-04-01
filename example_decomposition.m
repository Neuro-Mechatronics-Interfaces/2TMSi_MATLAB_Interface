%EXAMPLE_DECOMPOSITION Shows how to do decomposition of MUAPs
clear;
close all force;
clc;

% Set constants here
K = 32;
NPC = 6;
CH = 28;
DATA_FILE = 'Max_2024_03_30_B_22.poly5';
LAMBDA = 0.1;
GAMMA = 1;

%% Load data and run spike detection
data = TMSiSAGA.Poly5.read(DATA_FILE);
uni = data.samples(2:65,:);
[S,uni_d] = uni_2_pks(uni);
idx = find(S(CH,:));
[snips,idx] = uni_2_extended(uni, idx);
Y = tsne(snips);
clus = kmeans(Y,K);

%% Run the objective minimization
% Define the objective function
fun = @(x) objective_function(x, S, K, LAMBDA, GAMMA);

% Define optimization options
options = optimoptions(@lsqnonlin, ...
    'Algorithm', 'trust-region-reflective', ...
    'PlotFcn', {'optimplotresnorm','optimplotfval'}, ...
    'Display', 'iter', ...
    'MaxFunctionEvaluations', 1e4, ...
    'MaxIterations', 50);

% Perform optimization
[x, residual] = lsqnonlin(fun, W0(:), zeros(numel(W0),1), [], options);

% Reshape the optimized parameters to obtain W and H
W = reshape(x, 64, K);
H = S\W;