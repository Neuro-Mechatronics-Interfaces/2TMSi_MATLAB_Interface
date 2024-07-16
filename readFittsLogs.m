function [trialsTable, performance] = readFittsLogs(subjectName, year, month, day, indexKey)
% READFITTSLOGS Reads the trial and cursor log files and returns a timetable of trials.
%
%   [trialsTable, performance] = READFITTSLOGS(subjectName, year, month, day, indexKey)
%   reads the trial and cursor log files associated with the specified
%   subject name, date, and index key, and returns a table of trials.
%   Each row in the table corresponds to a trial, with the following variables:
%
%   StartTime - The start time of the trial.
%   EndTime - The end time of the trial.
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
%
% Arguments:
%   subjectName - The name of the subject.
%   year - The year of the trial date.
%   month - The month of the trial date.
%   day - The day of the trial date.
%   indexKey - The index key appended to the log file names.
%
% Returns:
%   trialsTable - A table of trials.
%   performance - A struct containing the performance model and index of difficulty.

arguments
    subjectName (1,:) char
    year (1,1) double
    month (1,1) double
    day (1,1) double
    indexKey (1,1) double
end

% Construct file names
dt = datetime(year, month, day);
dateStr = sprintf('%04d_%02d_%02d', year, month, day);
trialLogFileName = fullfile(pwd, sprintf('logs/%s_%s_Trials_%d.tsv', subjectName, dateStr, indexKey));
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
                         'FirstContactTime', 'TargetDistance', 'TargetWidth', ...
                         'StartTargetHoldDuration', 'TimeToLeaveStart'};

% Check the number of columns read
numColumns = size(trialData, 2);
if numColumns ~= length(expectedVariableNames)
    error('Unexpected number of columns in the trial log file: %d instead of %d', numColumns, length(expectedVariableNames));
end

trialData.Properties.VariableNames = expectedVariableNames;

% Read the cursor log file
fid = fopen(cursorLogFileName, 'r');
cursorData = fread(fid, [3, Inf], 'double')';
fclose(fid);

% Convert timestamps to datetime
cursorTimes = datetime(cursorData(:, 1)/1000, 'ConvertFrom', 'posixtime');

% Initialize arrays for cursor positions
numTrials = height(trialData);
xPositions = cell(numTrials, 1);
yPositions = cell(numTrials, 1);
cursorTimestamp = cell(numTrials, 1);

% Parse cursor positions for each trial
for i = 1:numTrials
    startTime = dt + seconds(trialData.StartTime(i));
    endTime = dt + seconds(trialData.EndTime(i));
    
    trialMask = cursorTimes >= startTime & cursorTimes <= endTime;
    trialCursorData = cursorData(trialMask, :);

    xPositions{i} = trialCursorData(:, 2);
    yPositions{i} = trialCursorData(:, 3);
    cursorTimestamp{i} = cursorTimes(trialMask);
end

% Compute index of difficulty
targetDistance = trialData.TargetDistance;
targetWidth = trialData.TargetWidth;
indexOfDifficulty = log2((2 .* targetDistance) ./ targetWidth + 1);

% Calculate effective duration
effectiveDuration = trialData.Duration - trialData.StartTargetHoldDuration;

% Create timetable
trialsTable = table(trialData.StartTime, trialData.EndTime, trialData.Duration, trialData.Result, ...
    trialData.FirstContactTime, targetDistance, targetWidth, indexOfDifficulty, cursorTimestamp, xPositions, yPositions, ...
    trialData.StartTargetHoldDuration, trialData.TimeToLeaveStart, effectiveDuration, ...
    'VariableNames', {'StartTime', 'EndTime', 'Duration', 'Result', 'FirstContactTime', 'TargetDistance', 'TargetWidth', ...
    'IndexOfDifficulty', 'CursorTimestamp', 'XPositions', 'YPositions', 'StartTargetHoldDuration', 'TimeToLeaveStart', 'EffectiveDuration'});

performance = struct;
performance.model = fitglme(trialsTable, 'EffectiveDuration ~ 1 + IndexOfDifficulty');
performance.index = 1/performance.model.Coefficients.Estimate(strcmp(performance.model.Coefficients.Name, 'IndexOfDifficulty'));
performance.mean_throughput = mean(trialsTable.IndexOfDifficulty./trialsTable.EffectiveDuration);
performance.std_throughput = std(trialsTable.IndexOfDifficulty./trialsTable.EffectiveDuration);
end
