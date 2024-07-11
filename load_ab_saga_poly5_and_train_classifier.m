function [mdl, saga, S, labels] = load_ab_saga_poly5_and_train_classifier(SUBJ, YYYY, MM, DD, BLOCK, options)
%LOAD_AB_SAGA_POLY5_AND_TRAIN_CLASSIFIER  Loads poly5 files for SAGAA/B and then uses TRIGGERS data to parse classifier labels and train a bagged trees classification model for discrete gesture recognition.
%
% Syntax:
%   mdl = load_ab_saga_poly5_and_train_classifier(SUBJ, YYYY, MM, DD, BLOCK, 'Name', value, ...);
%   
% Inputs:
%   SUBJ - Name of subject
%   YYYY - Year (numeric)
%   MM - Month (numeric)
%   DD - Day (numeric)
%   BLOCK - Block indexing which recording this was (numeric)
%   
% Options:
%       'ApplyCAR' - Logical indicating whether to apply Common Average Referencing.
%       'ApplyFilter' - Logical indicating whether to apply high-pass filtering.
%       'HighpassFilterCutoff' - High-pass filter cutoff frequency.
%       'ApplyGridInterpolation' - Logical indicating whether to interpolate data on a grid.
%       'ApplySpatialLaplacian' - Logical indicating whether to apply spatial Laplacian filtering.
%       'TriggerChannelIndicator' - Name indicator for the trigger channel.
%       'RestBit' - Bit used to indicate REST in neutral position between each gesture. Also used in determining the bitmask to apply to trigger channel data for pulse detection.
%       'IsTextile64' - Logical indicating if data arrangement follows a 64-electrode textile configuration.
%       'TextileTo8x8GridMapping' - Mapping of electrodes from a textile configuration to a standard 8x8 grid.
%       'InputRoot' - Root directory for input files if not included in poly5_files paths.

arguments
    SUBJ
    YYYY
    MM
    DD
    BLOCK
    options.ApplyCAR (1,1) logical = true;
    options.ApplyFilter (1,1) logical = true;
    options.ApplyGridInterpolation (1,1) logical = true;
    options.ApplySpatialLaplacian (1,1) logical = true;
    options.HighpassFilterCutoff (1,1) double = 100;
    options.EnvelopeFilterCutoff (1,1) double = 0.75;
    options.InputRoot = "C:/Data/TMSi";
    options.RestBit = 1;
    options.ClassifierFileID string {mustBeTextScalar} = "NBModel";
    options.DecimationFactor = 200; % Number of samples to "skip" (binning)
    options.InstructionListFile {mustBeFile, mustBeTextScalar} = 'configurations/instructions/InstructionList_Wrist2D.mat';
    options.IsTextile64 (1,1) logical = true;
    options.TextileTo8x8GridMapping (1,64) {mustBeInteger, mustBeInRange(options.TextileTo8x8GridMapping,1,64)} = [17 16 15	14 13 9	5 1	22 21 20 19	18 10 6	2 27 26	25 24 23 11	7 3	32 31 30 29	28 12 8	4 33 34 35 36 37 53 57 61 38 39 40 41 42 54 58 62 43 44 45 46 47 55 59 63 48 49 50 51 52 56 60 64];
    options.SampleRate (1,1) double {mustBeMember(options.SampleRate, [2000, 4000])} = 4000;
    options.PlotConfusion (1,1) logical = true;
    options.ComputeAccuracy (1,1) logical = true;
    options.HoldOut (1,1) double {mustBeInRange(options.HoldOut,0,1)} = 0.5;
    options.NumLearningCycles (1,1) {mustBePositive, mustBeInteger} = 250;
    options.Title {mustBeTextScalar} = '';
end

TANK = sprintf("%s_%04d_%02d_%02d", SUBJ, YYYY, MM, DD);

A_file_expr = sprintf("%s/%s/%s/%s_A*_%d.poly5", options.InputRoot, SUBJ, TANK, TANK, BLOCK);
A = dir(A_file_expr);
if isempty(A)
    error("No file matches expression: %s", A_file_expr);
elseif numel(A) > 1
    error("Non-specific match: multiple A blocks match file expression (%s)", A_file_expr);
end

B_file_expr = sprintf("%s/%s/%s/%s_B*_%d.poly5", options.InputRoot, SUBJ, TANK, TANK, BLOCK);
B = dir(B_file_expr);
if isempty(B)
    error("No file matches expression: %s", B_file_expr);
elseif numel(A) > 1
    error("Non-specific match: multiple B blocks match file expression (%s)", B_file_expr);
end

[b_env, a_env] = butter(3,options.EnvelopeFilterCutoff/(options.SampleRate/2),'low');

saga = io.load_align_saga_data_many(...
    [string(fullfile(A.folder, A.name)); ...
     string(fullfile(B.folder, B.name))], ...
     'TriggerBitMask',2^options.RestBit, ...
     'IsTextile64', options.IsTextile64, ...
     'TextileTo8x8GridMapping', options.TextileTo8x8GridMapping, ...
     'SampleRate', options.SampleRate, ...
     'ApplyCAR', options.ApplyCAR, ...
     'ApplyGridInterpolation', options.ApplyGridInterpolation, ...
     'ApplySpatialLaplacian', options.ApplySpatialLaplacian, ...
     'ApplyFilter', options.ApplyFilter, ...
     'HighpassFilterCutoff', options.HighpassFilterCutoff);
[iUni, ~, iTrig] = ckc.get_saga_channel_masks(saga.channels);
[S, labels] = parse_instruction_triggers(...
    saga.samples(iTrig(1),:), ...
    'RestBit', options.RestBit, ...
    'LabelsFile', options.InstructionListFile);

% Y = categorical(interp1(single(labels(101:end)),(1:options.DecimationFactor:(numel(labels)-100))','previous'), unique(single(labels)),string(categories(labels)));
% X = filter(b_env,a_env,abs(saga.samples(iUni,:)'),[],1); % Not filtfilt so that decoder is also using causal data w.r.t. labels!
% X(1:100,:) = []; % Drop initial samples, noise at start of recording + filter not yet converged. 
% X = interp1(movmean(X,options.DecimationFactor,1),(1:options.DecimationFactor:size(X,1))');

% mdl = train_ensemble_classifier(X, Y, ...
%     'PlotConfusion', options.PlotConfusion, ...
%     'Title', options.Title, ...
%     'ComputeAccuracy', options.ComputeAccuracy, ...
%     'HoldOut', options.HoldOut, ...
%     'NumLearningCycles', options.NumLearningCycles);

Y = labels_2_cartesian(labels(101:end));
X = filter(b_env,a_env,abs(saga.samples(iUni,:)),[],2); % Not filtfilt so that decoder is also using causal data w.r.t. labels!
X(:,1:100) = []; % Drop initial samples, noise at start of recording + filter not yet converged. 
mdl = struct;
[mdl.beta0, mdl.beta] = fit_poly_model(Y, X);

classifier_filename = sprintf("%s/%s/%s/%s_%s_%d.mat", options.InputRoot, SUBJ, TANK, TANK, options.ClassifierFileID, BLOCK);
save(classifier_filename, 'mdl', '-v7.3');
fprintf(1,'Saved file to %s.\n', classifier_filename);
end