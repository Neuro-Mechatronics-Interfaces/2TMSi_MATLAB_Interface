function [trialsTable, performance, cursorData] = readFittsLogs(SUBJ, YYYY, MM, DD, block)
% READFITTSLOGS Reads the trial and cursor log files and returns a timetable of trials.
%
%   [trialsTable, performance] = READFITTSLOGS(SUBJ, YYYY, MM, DD, block)
%   reads the trial and cursor log files associated with the specified
%   subject name, date, and index key, and returns a table of trials.
%   Each row in the table corresponds to a trial, with the following variables:
%
%   Date - The date for these trials.
%   StartTime - The start time of the trial.
%   EndTime - The end time of the trial.
%   TrialNumber - Number of trial within a given block. 
%   Duration - The duration of the trial.
%   Result - The result of the trial ('Success' or 'Failed').
%   FirstContactTime - The time from target appearance to first contact.
%   TargetDistance - The distance to the target.
%   TargetWidth - The width of the target.
%   IndexOfDifficulty - The computed index of difficulty for the trial.
%   CursorTimestamp - A cell array of the cursor timestamps during the trial.
%   XPositions - A cell array of the x cursor positions during the trial.
%   YPositions - A cell array of the y cursor positions during the trial.
%   StartTargetHoldDuration - The required hold duration on the start target.
%   TimeToLeaveStart - The duration from when the second target appears to when the subject leaves the start target.
%   EffectiveDuration - The duration of the trial excluding the required hold duration.
%   ReactionDuration  - The duration from "GO" cue to actually leaving the start target.
%   ControlType - The type of control used in the Fitts' Law trial.
%
% Arguments:
%   SUBJ - The name of the subject.
%   YYYY - The year of the trial date.
%   MM - The month of the trial date.
%   DD - The day of the trial date.
%   block - The index key appended to the log file names.
%
% Returns:
%   trialsTable - A table of trials.
%   performance - A struct containing the performance model and index of difficulty.
%   cursorData - Cursor data as read from the log file directly.

arguments
    SUBJ (1,:) char
    YYYY (1,1) double
    MM (1,1) double
    DD (1,1) double
    block (1,1) double
end

% Construct file names
dt = datetime(YYYY, MM, DD);
dateStr = sprintf('%04d_%02d_%02d', YYYY, MM, DD);
tank = sprintf('%s_%s', SUBJ, dateStr);
trialLogFileName = fullfile(pwd, sprintf('logs/%s/%s_Trials_%d.tsv', tank, tank, block));
cursorLogFileName = strrep(trialLogFileName, '_Trials_', '_Cursor_');
cursorLogFileName = strrep(cursorLogFileName, '.tsv', '.bin');

% Check if the files exist
if ~exist(trialLogFileName, 'file') || ~exist(cursorLogFileName, 'file')
    error('The specified trial or cursor log files do not exist.');
end

% Read the trial log file
trialData = readtable(trialLogFileName, 'FileType', 'text', 'Delimiter', '\t', 'ReadVariableNames', false);

% Print the first row of the table to debug
% disp('First row of the table:');
% disp(trialData(1,:));

% Define the variable names for the table
expectedVariableNames = {'TrialNumber', 'StartTime', 'EndTime', 'Duration', 'Result', ...
                         'FirstContactTime', 'HorizontalTargetOffset', 'VerticalTargetOffset', 'TargetDistance', 'TargetWidth', ...
                         'StartTargetHoldDuration', 'TimeToLeaveStart', 'ControlType'};

% Check the number of columns read
numColumns = size(trialData, 2);
numExpected = length(expectedVariableNames);
if numColumns ~= length(expectedVariableNames)
    if (numExpected-1)==numColumns
        expectedVariableNames = expectedVariableNames(1:(end-1));
        % numExpected = numExpected - 1;
        missingControlType = true;
    else
        error('Unexpected number of columns in the trial log file: %d instead of %d', numColumns, length(expectedVariableNames));
    end
else
    missingControlType = false;
end

trialData.Properties.VariableNames = expectedVariableNames;

% Read the cursor log file
fid = fopen(cursorLogFileName, 'r');
cursorData = fread(fid, [3 Inf], 'double')';
fclose(fid);

% Convert timestamps to datetime
cursorTimes = datetime(cursorData(:, 1)/1000, 'ConvertFrom', 'posixtime');
cursorTimes = cursorTimes - dt;

% Initialize arrays for cursor positions
numTrials = height(trialData);
xPositions = cell(numTrials, 1);
yPositions = cell(numTrials, 1);
cursorTimestamp = cell(numTrials, 1);

if numTrials < 1
    trialsTable = missing;
    performance = struct('model', missing, 'index', missing, 'mean_reaction', missing, 'std_reaction', missing, ...
        'mean_acquisition', missing, 'std_acquisition', missing, ...
        'mean_dialin', missing, 'std_dialin', missing, ...
        'mean_throughput', missing, 'std_throughput', missing);
    return;
end

% Parse cursor positions for each trial
for i = 1:numTrials    
    trialMask = (cursorTimes >= trialData.StartTime(i)) & (cursorTimes <= trialData.EndTime(i));
    trialCursorData = cursorData(trialMask, :);

    xPositions{i} = trialCursorData(:, 2);
    yPositions{i} = trialCursorData(:, 3);
    cursorTimestamp{i} = cursorTimes(trialMask);
end

% Compute index of difficulty
targetDistance = trialData.TargetDistance;
targetWidth = trialData.TargetWidth;
indexOfDifficulty = log2((2 .* targetDistance) ./ targetWidth); % Fitts
indexOfDifficultyAdj = log2((2.*targetDistance + targetWidth)./targetWidth); % Mackenzie, Hargrove

% Create timetable
if missingControlType
    controlType = enum.FittsControlType(ones(size(effectiveDuration)).*-1);
else
    controlType = enum.FittsControlType(trialData.ControlType);
end


trialsTable = table(...
    repmat(dt,size(trialData,1),1),trialData.StartTime, trialData.EndTime, trialData.TrialNumber, trialData.Result, ...
    trialData.HorizontalTargetOffset, trialData.VerticalTargetOffset, targetDistance, targetWidth, ...
    indexOfDifficulty, indexOfDifficultyAdj, ...
    cursorTimestamp, xPositions, yPositions, ...
    trialData.StartTargetHoldDuration, trialData.TimeToLeaveStart, trialData.FirstContactTime, trialData.Duration, controlType, ...
    'VariableNames', { ...
        'Date','StartTime', 'EndTime', 'TrialNumber', 'Result', ...
        'TargetHorizontalOffset', 'TargetVerticalOffset', 'TargetDistance', 'TargetWidth', ...
        'ID','IDadj', ...
        'CursorTimestamp', 'XPositions', 'YPositions', ...
        'HoldTime', 'ReactionTime', 'AcquisitionTime', 'DialInTime', 'ControlType'});

performance = struct;
if size(trialsTable,1) > 2
    performance.model = fitglme(trialsTable, 'DialInTime ~ 1 + ID');
    performance.index = 1/performance.model.Coefficients.Estimate(strcmp(performance.model.Coefficients.Name, 'ID'));
else
    performance.model = missing;
    performance.index = missing;
end
performance.mean_reaction = mean(trialsTable.ReactionTime);
performance.std_reaction = std(trialsTable.ReactionTime);
performance.mean_acquisition = mean(trialsTable.AcquisitionTime);
performance.std_acquisition = std(trialsTable.AcquisitionTime);
performance.mean_dialin = mean(trialsTable.DialInTime);
performance.std_dialin = std(trialsTable.DialInTime);
performance.mean_throughput = mean(trialsTable.IDadj./trialsTable.DialInTime);
performance.std_throughput = std(trialsTable.IDadj./trialsTable.DialInTime);
end
