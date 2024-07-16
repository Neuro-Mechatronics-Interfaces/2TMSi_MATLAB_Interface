function [trialsTable, performance] = init_fitts_gui(inlet, options)

arguments
    inlet = [];
    options.Serial = [];
    options.TrialsPerTarget (1,1) double = 2;
    options.MaxTrialDuration (1,1) double = 20;
    options.TargetDistance (1,:) double = [12, 16];
    options.TargetWidth (1,:) double = [2, 4];
    options.SubjectName (1,:) char = 'Max';
    options.IndexingKey (1,1) double = 0;
    options.TargetBasis (:,2) double = [0 1; 1 0]; % Basis for any targets generated
    options.HoverDuration (1,1) double = 1; % Duration in seconds to hover over target
    options.StartTargetHoldRange (1,2) double = [0.75, 1.25]; % Duration in seconds to delay before showing the second target.
end

% Generate log file name
[trialLogFileName, cursorLogFileName, indexingKey] = generateLogFileNames(options.SubjectName, options.IndexingKey);

% Initialize the figure
fig = figure('Name', 'Fitts Law Task', 'NumberTitle', 'off', 'Pointer', 'crosshair', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Color', 'k', 'WindowState','maximized');

% Set up the axes
ax = axes('Parent', fig, ...
    'XLim', [0 20], 'YLim', [0 20], ...
    'DataAspectRatio', [1 1 1], 'Color', 'none', ...
    'XColor','none','YColor','none');
ax.UserData = options.Serial;
hold(ax, 'on');

% Create the start target
startTarget = createTarget(ax, 2, 2, 2, 'g', 0);
startTarget.Visible = 'on';

% Generate random target positions
[targetPosition, targetRadius] = generateTargetPositions(options.TargetDistance, options.TargetWidth/2, options.TargetBasis);

% Create targets
targets = gobjects(1, length(targetPosition));
for i = 1:length(targetPosition)
    targets(i) = createTarget(ax, targetPosition(i,1), targetPosition(i,2), targetRadius(i), 'r', i);
end

% Initialize cursor
cursor = plot(ax, 9, 9, 'b+', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor','b','LineWidth',3);

% Add text box for trial information
trialTextBox = uicontrol('Style', 'text', 'String', '', ...
    'Position', [20 20 200 40], 'FontSize', 14, 'FontWeight', 'bold', ...
    'ForegroundColor', 'w', 'BackgroundColor', 'k', 'FontName', 'Consolas');

% Open log files
trialLogFile = fopen(trialLogFileName, 'w');
fprintf(trialLogFile, 'TrialNumber\tStartTime\tEndTime\tDuration\tResult\tFirstContactTime\tTargetDistance\tTargetWidth\tStartTargetHoldDuration\tTimeToLeaveStart\n');
cursorLogFile = fopen(cursorLogFileName, 'w');

% Set up the WindowButtonMotionFcn to track mouse movement
set(fig, 'WindowButtonMotionFcn', @(src, event) mouseMove(src, ax, cursor));

% Close the log files when the figure is closed
set(fig, 'CloseRequestFcn', @(~,~) onClose(trialLogFile, cursorLogFile, fig));
dt = datetime('today');

mouseMove(nan, ax, cursor); % Set the initial cursor position.

% Start the task
if isempty(inlet)
    runTaskWithMouse(ax, cursor, startTarget, targets, options, trialTextBox, trialLogFile, cursorLogFile);
else
    runTaskWithInlet(inlet, ax, cursor, startTarget, targets, options, trialTextBox, trialLogFile, cursorLogFile);
end

[trialsTable, performance] = readFittsLogs(options.SubjectName, year(dt), month(dt), day(dt), indexingKey);
head(trialsTable);
disp(performance.index);

end

function onClose(trialLogFile, cursorLogFile, fig)
fclose(trialLogFile);
fclose(cursorLogFile);
delete(fig);
end

function [trialLogFileName, cursorLogFileName, indexingKey] = generateLogFileNames(subjectName, indexingKey)
dt = datetime('today');
dateStr = sprintf('%04d_%02d_%02d', year(dt), month(dt), day(dt));
if exist(fullfile(pwd,'logs'),'dir')==0
    mkdir(fullfile(pwd,'logs'));
end

trialLogFileName = fullfile(pwd,sprintf('logs/%s_%s_Trials_%d.tsv', subjectName, dateStr, indexingKey));

% Check if the file already exists, if so, increment the indexing key
while exist(trialLogFileName, 'file')
    indexingKey = indexingKey + 1;
    trialLogFileName = fullfile(pwd,sprintf('logs/%s_%s_Trials_%d.tsv', subjectName, dateStr, indexingKey));
end
cursorLogFileName = strrep(trialLogFileName, '_Trials_', '_Cursor_');
cursorLogFileName = strrep(cursorLogFileName, '.tsv', '.bin');
end

function target = createTarget(ax, x, y, radius, color, id)
% Create a circular target using a patch object
theta = linspace(0, 2*pi, 100);
xCircle = radius * cos(theta) + x;
yCircle = radius * sin(theta) + y;
verts = [xCircle; yCircle]';
faces = [1:100,1];
target = patch(ax, 'Visible','off', 'Faces',faces,'Vertices',verts, 'FaceColor', color, 'EdgeColor', 'none','UserData',struct('r',radius,'x',x,'y',y,'id',id));
end

function [targetPosition, targetRadius] = generateTargetPositions(distance, radius, basis)
% Generate target positions based on specified distances
% Target positions are set at the bottom right corner and the top left corner
numDistances = length(distance);
numRadius = length(radius);
numBases = size(basis, 1);
targetPosition = zeros(numDistances*numRadius*numBases, 2);
targetRadius = zeros(numDistances*numRadius*numBases, 1);
iCount = 0;
r0 = max([radius,2]); % includes size of start target
for ik = 1:numRadius
    for ii = 1:numDistances
        for ij = 1:numBases
            iCount = iCount + 1;
            targetRadius(iCount) = radius(ik);
            targetPosition(iCount,:) = basis(ij,:).*(distance(ii)-r0) + r0; % e.g. [r0, distance(ii)]; % Top left corner
        end
    end
end
% Randomize the list of positions and matched radii
idx = randsample(numDistances*numRadius*2,numDistances*numRadius*2,false);
targetPosition = targetPosition(idx,:);
targetRadius = targetRadius(idx,:);
end

function mouseMove(~, ax, cursor)
% Get the current cursor position in axes coordinates
cursorPoint = get(ax, 'CurrentPoint');
cursorX = cursorPoint(1,1);
cursorY = cursorPoint(1,2);

% Update the cursor position
set(cursor, 'XData', cursorX, 'YData', cursorY);
end

function runTaskWithInlet(inlet, ax, cursor, startTarget, targets, options, trialTextBox, trialLogFile, cursorLogFile)
    % Run the Fitts Law task with LSL inlet
    numTargets = length(targets);
    totalTrials = options.TrialsPerTarget * numTargets;
    trialCount = 0;
    targetIndex = randsample(numTargets, 1);
    isTrialActive = false;
    trialStartTime = 0;
    hoverStartTime = 0;
    leaveStartTargetTime = 0;
    isHovering = false;
    firstContactTime = [];

    % Calibration phase
    T = calibrateInlet(ax, trialTextBox, inlet);

    while (trialCount < totalTrials) && ishandle(ax)
        % Get the current cursor position from the inlet
        sample = inlet.pull_sample();
        sample = T * sample(1:2,1);
        cursorX = sample(1);
        cursorY = sample(2);

        % Update the cursor position
        set(cursor, 'XData', cursorX, 'YData', cursorY);

        if ~isTrialActive
            % Start the trial when cursor enters the start target
            if isInTarget(cursorX, cursorY, startTarget)
                if ~isHovering
                    isHovering = true;
                    hoverStartTime = tic;
                    if ~isempty(ax.UserData)
                        write(ax.UserData, '1', 'c');
                    end
                    set(startTarget, 'FaceColor', 'c');
                    randomDelay = options.StartTargetHoldRange(1) + (options.StartTargetHoldRange(2) - options.StartTargetHoldRange(1)) * rand; % Random delay between 0.75 and 1.25 seconds
                elseif toc(hoverStartTime) >= randomDelay
                    % Random delay duration met, show the target
                    isTrialActive = true;
                    trialStartTime = tic;
                    if ~isempty(ax.UserData)
                        write(ax.UserData, '2', 'c');
                    end
                    set(targets(targetIndex), 'Visible', 'on'); % Show the target
                    startTime = datetime('now');
                    updateTrialText(trialTextBox, trialCount + 1, totalTrials);
                end
            else
                isHovering = false;
            end
        else
            set(startTarget, 'FaceColor', 'g');
            % Check if the trial is completed
            if isInTarget(cursorX, cursorY, targets(targetIndex))
                if isempty(firstContactTime)
                    firstContactTime = toc(trialStartTime);
                    if ~isempty(ax.UserData)
                        write(ax.UserData, '3', 'c');
                    end
                end
                set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                trialCount = trialCount + 1;
                isTrialActive = false;
                leaveStartTargetTime = toc(trialStartTime);
                targetIndex = mod(trialCount, numTargets) + 1;
                endTime = datetime('now');
                if ~isempty(ax.UserData)
                    write(ax.UserData, '0', 'c');
                end
                duration = toc(trialStartTime);
                writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Success', firstContactTime, options.TargetDistance(mod(targetIndex - 1, numel(options.TargetDistance)) + 1), options.TargetWidth(mod(targetIndex - 1, numel(options.TargetWidth)) + 1), randomDelay, leaveStartTargetTime);
                firstContactTime = [];
            end
            % End the trial if max duration is reached
            if toc(trialStartTime) > options.MaxTrialDuration
                set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                isTrialActive = false;
                leaveStartTargetTime = toc(trialStartTime);
                if ~isempty(ax.UserData)
                    write(ax.UserData, '0', 'c');
                end
                endTime = datetime('now');
                duration = toc(trialStartTime);
                writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Failed', firstContactTime, options.TargetDistance(mod(targetIndex - 1, numel(options.TargetDistance)) + 1), options.TargetWidth(mod(targetIndex - 1, numel(options.TargetWidth)) + 1), randomDelay, leaveStartTargetTime);
                firstContactTime = [];
            end
        end

        % Log cursor position
        updateCursorLog(cursorLogFile, cursorX, cursorY);

        drawnow;
        pause(0.030);
    end

    % Task completed
    if ishandle(ax)
        msgbox('Task completed!', 'Fitts Law Task');
        close(ax.Parent);
    else
        msgbox('Task exited!', 'Fitts Law Task');
    end
end

function T = calibrateInlet(ax, trialTextBox, inlet)
    % Calibration phase for the Fitts Law task with LSL inlet
    calibrationPrompts = {'Rest', 'Move Right', 'Move Up'};
    calibrationDurations = [2, 2, 2]; % in seconds

    % Initialize variables to store calibration data
    restSamples = [];
    rightSamples = [];
    upSamples = [];

    for i = 1:length(calibrationPrompts)
        % Display calibration prompt
        set(trialTextBox, 'String', calibrationPrompts{i});
        drawnow;

        % Collect samples during the calibration period
        calibrationStartTime = tic;
        currentSamples = [];
        while toc(calibrationStartTime) < calibrationDurations(i)
            sample = inlet.pull_sample();
            cursorX = sample(1);
            cursorY = sample(2);
            currentSamples = [currentSamples; cursorX, cursorY]; %#ok<AGROW>

            % Update the cursor position
            set(cursor, 'XData', cursorX, 'YData', cursorY);

            drawnow;
            pause(0.030);
        end

        % Store samples for each calibration phase
        switch calibrationPrompts{i}
            case 'Rest'
                restSamples = currentSamples;
            case 'Move Right'
                rightSamples = currentSamples;
            case 'Move Up'
                upSamples = currentSamples;
        end

        % Clear the prompt
        set(trialTextBox, 'String', '');
        drawnow;
        pause(0.5);
    end

    % Compute average cursor positions for each phase
    restPos = mean(restSamples, 1);
    rightPos = mean(rightSamples, 1);
    upPos = mean(upSamples, 1);

    % Compute transformation matrix to map cursor positions to task space directions
    rightVector = rightPos - restPos;
    upVector = upPos - restPos;

    % Normalize the vectors
    rightVector = rightVector / norm(rightVector);
    upVector = upVector / norm(upVector);

    % Compute the transformation matrix
    T = [rightVector(:), upVector(:)];
end


function runTaskWithMouse(ax, cursor, startTarget, targets, options, trialTextBox, trialLogFile, cursorLogFile)
% Run the Fitts Law task with mouse cursor
numTargets = length(targets);
totalTrials = options.TrialsPerTarget * numTargets;
trialCount = 0;
targetIndex = randsample(numTargets,1);
isTrialActive = false;
trialStartTime = 0;
hoverStartTime = 0;
isHovering = false;
firstContactTime = [];

while (trialCount < totalTrials) && ishandle(ax)
    % Cursor position is updated by the mouseMove function

    % Get the current cursor position from the cursor object
    cursorX = get(cursor, 'XData');
    cursorY = get(cursor, 'YData');

    if ~isTrialActive
        % Start the trial when cursor enters the start target
        if isInTarget(cursorX, cursorY, startTarget)
            if ~isHovering
                isHovering = true;
                hoverStartTime = tic;
                set(startTarget,'FaceColor','c');
                if ~isempty(ax.UserData)
                    write(ax.UserData,'1','c');
                end
                randomDelay = options.StartTargetHoldRange(1) + (options.StartTargetHoldRange(2)-options.StartTargetHoldRange(1))*rand; % Random delay between 0.75 and 1.25 seconds
            elseif toc(hoverStartTime) >= randomDelay
                % Random delay duration met, show the target
                isTrialActive = true;
                trialStartTime = tic;
                set(targets(targetIndex), 'Visible', 'on'); % Show the target
                if ~isempty(ax.UserData)
                    write(ax.UserData,'2','c');
                end
                startTime = datetime('now');
                updateTrialText(trialTextBox, trialCount + 1, totalTrials);
            end
        else
            isHovering = false;
        end
    else
        set(startTarget,'FaceColor','g');
        % Check if the cursor is hovering over the target
        if isInTarget(cursorX, cursorY, targets(targetIndex))
            if isempty(firstContactTime)
                firstContactTime = toc(trialStartTime);
                if ~isempty(ax.UserData)
                    write(ax.UserData,'3','c');
                end
            end
            if ~isHovering
                isHovering = true;
                hoverStartTime = tic;
                set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
            elseif toc(hoverStartTime) >= options.HoverDuration
                % Hovering duration met, trial completed
                set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                if ~isempty(ax.UserData)
                    write(ax.UserData,'0','c');
                end
                trialCount = trialCount + 1;
                isTrialActive = false;
                isHovering = false;
                leaveStartTargetTime = toc(trialStartTime);
                targetIndex = mod(trialCount, numTargets) + 1;
                endTime = datetime('now');
                duration = toc(trialStartTime);
                writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Success', firstContactTime, options.TargetDistance(mod(targetIndex-1, numel(options.TargetDistance))+1), options.TargetWidth(mod(targetIndex-1, numel(options.TargetWidth))+1), randomDelay, leaveStartTargetTime);
                firstContactTime = [];
            end
        else
            if isHovering
                isHovering = false;
                set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
            end
        end
        % End the trial if max duration is reached
        if toc(trialStartTime) > options.MaxTrialDuration
            set(targets(targetIndex), 'Visible', 'off'); % Hide the target
            isTrialActive = false;
            isHovering = false;
            leaveStartTargetTime = toc(trialStartTime);
            if ~isempty(ax.UserData)
                write(ax.UserData,'0','c');
            end
            set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
            endTime = datetime('now');
            duration = toc(trialStartTime);
            writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Failed', firstContactTime, options.TargetDistance(mod(targetIndex-1, numel(options.TargetDistance))+1), options.TargetWidth(mod(targetIndex-1, numel(options.TargetWidth))+1), randomDelay, leaveStartTargetTime);
            firstContactTime = [];
        end
    end

    % Log cursor position
    updateCursorLog(cursorLogFile, cursorX, cursorY);

    drawnow;
    pause(0.030);
end

% Task completed
if ishandle(ax)
    msgbox('Task completed!', 'Fitts Law Task');
    close(ax.Parent);
else
    msgbox('Task exited!', 'Fitts Law Task');
end
end


function updateTrialText(trialTextBox, trialCount, totalTrials)
set(trialTextBox, 'String', sprintf('Trial %d of %d', trialCount, totalTrials));
end

function isInside = isInTarget(x, y, target)
% Get the target's center coordinates and radius from the UserData property
centerX = target.UserData.x;
centerY = target.UserData.y;
radius = target.UserData.r;

% Calculate the distance from the point (x, y) to the target's center
distance = sqrt((x - centerX)^2 + (y - centerY)^2);

% Check if the point is inside the target (distance is less than or equal to radius)
isInside = distance <= radius;
end

function updateCursorLog(cursorLogFile, cursorX, cursorY)
% Log cursor position with timestamp
timestamp = posixtime(datetime('now')) * 1000; % Current time in milliseconds since epoch
fwrite(cursorLogFile, [timestamp, cursorX, cursorY], 'double');
end

