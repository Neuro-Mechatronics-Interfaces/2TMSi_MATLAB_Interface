function [trialsTable, performance] = init_fitts_gui(inlet, options)

arguments
    inlet = [];
    options.Serial = [];
    options.TrialsPerTarget (1,1) double = 2;
    options.MaxTrialDuration (1,1) double = 10;
    options.TargetDistance (1,:) double = [4, 40];
    options.TargetWidth (1,:) double = [1, 2, 8];
    options.SubjectName (1,:) char = 'Max';
    options.IndexingKey (1,1) double = 0;
    options.TargetBasis (:,2) double = [0 1; 1 0]; % Basis for any targets generated
    options.HoverDuration (1,1) double = 1; % Duration in seconds to hover over target
    options.StartTargetHoldRange (1,2) double = [0.75, 1.25]; % Duration in seconds to delay before showing the second target.
    options.GameLoopPauseDuration (1,1) double = 0.0005; % Duration for pausing game loop.
    options.CursorTailLength (1,1) {mustBePositive, mustBeInteger} = 10;
    options.InletType (1,1) enum.FittsControlType = enum.FittsControlType.LSL_MYO2D_RMS_POSITION_CORNERED;
    options.MouseType (1,1) enum.FittsControlType = enum.FittsControlType.MOUSE;
    options.VelocityGain (1,1) double = 2500.0;
end

% Generate log file name
[trialLogFileName, cursorLogFileName, indexingKey] = generateLogFileNames(options.SubjectName, options.IndexingKey);

% Initialize the figure
fig = figure('Name', 'Fitts Law Task', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Color', 'k', 'WindowState','maximized', ...
    'Pointer', 'custom', 'PointerShapeCData', nan(16,16), ...
    'WindowKeyPressFcn', @updateCursorSettings);

% Set up the axes
dMax = max(options.TargetDistance);
wMax = max(options.TargetWidth);
ax = axes('Parent', fig, ...
    'XLim', [0 dMax+wMax], 'YLim', [0 dMax+wMax], ...
    'DataAspectRatio', [1 1 1], 'Color', 'none', ...
    'XColor','none','YColor','none');
ax.UserData = options.Serial;
hold(ax, 'on');

% Create the start target
startTarget = createTarget(ax, wMax/2, wMax/2, wMax/2, 'g', 0);
startTarget.Visible = 'on';

% Generate random target positions
[targetPosition, targetRadius] = generateTargetPositions(options.TargetDistance, options.TargetWidth/2, options.TargetBasis);

% Create targets
targets = gobjects(1, length(targetPosition));
for i = 1:length(targetPosition)
    targets(i) = createTarget(ax, targetPosition(i,1), targetPosition(i,2), targetRadius(i), 'r', i);
end

% Initialize cursor
p = (dMax-wMax)/2;
cursor = plot(ax,...
    ones(1,options.CursorTailLength).*p, ...
    ones(1,options.CursorTailLength).*p, ...
    'bo-', ...
    'MarkerSize', 3, ...
    'MarkerFaceColor', 'none', ...
    'MarkerEdgeColor','b', ...
    'LineWidth',1.0,...
    'MarkerIndices',options.CursorTailLength);
switch options.InletType
    case enum.FittsControlType.LSL_XBOX_VELOCITY_CENTERED
        cursor.UserData = struct('xg', options.GameLoopPauseDuration*options.VelocityGain, 'yg', -options.GameLoopPauseDuration*options.VelocityGain, 'x0', 0, 'y0', 0);
        cursor.XData = ones(1,options.CursorTailLength).*(wMax/2);
        cursor.YData = ones(1,options.CursorTailLength).*(wMax/2);
    case enum.FittsControlType.LSL_XBOX_VELOCITY
        cursor.UserData = struct('xg', options.GameLoopPauseDuration*options.VelocityGain, 'yg', -options.GameLoopPauseDuration*options.VelocityGain, 'x0', 0, 'y0', 0);
    case enum.FittsControlType.LSL_XBOX_POSITION_CENTERED
        cursor.UserData = struct('xg',(dMax+wMax)/2,'yg',-(dMax+wMax)/2,'x0',(dMax+wMax)/2,'y0',(dMax+wMax)/2);
    case enum.FittsControlType.LSL_XBOX_POSITION_CORNERED
        cursor.UserData = struct('xg',dMax+wMax/2,'yg',-(dMax+wMax/2),'x0',wMax/2,'y0',wMax/2);
    case enum.FittsControlType.LSL_XBOX_POSITION_CORNERED_CHEATING
        cursor.UserData = struct('xg',dMax,'yg',-dMax,'x0',wMax/2,'y0',wMax/2);
    case enum.FittsControlType.LSL_MYO2D_RMS_POSITION_CORNERED
        cursor.UserData = struct('xg',1,'yg',1,'x0',wMax/2,'y0',wMax/2);
    otherwise
        cursor.UserData = struct('xg',1,'yg',1,'x0',wMax/2,'y0',wMax/2);
end
fig.UserData = struct('cursor', cursor);
drawnow();

% Add text box for trial information
info_position = [fig.InnerPosition(3)*0.45, fig.InnerPosition(4)-60, 200, 60];
infoTextBox = uicontrol(...
    'Style', 'text', ...
    'String', '', ...
    'Position', info_position, ...
    'FontSize', 14, ...
    'FontWeight', 'bold', ...
    'ForegroundColor', 'w', ...
    'BackgroundColor', 'k', ...
    'Tag', 'Info', ...
    'FontName', 'Consolas');

syncBoxArray = gobjects(3,1);
w = wMax/5;
H = dMax + wMax;
syncX = [H-w; H; H; H-w];
syncBoxArray(1) = patch(ax,'Faces',[1:4,1],'Vertices',[syncX,[H-w;H-w;H;H]],'FaceColor','w','EdgeColor','w','Tag','Sync_Trial','Visible','off');
syncBoxArray(2) = patch(ax,'Faces',[1:4,1],'Vertices',[syncX,[H-3*w;H-3*w;H-2*w;H-2*w]],'FaceColor','w','EdgeColor','w','Tag','Sync_Active','Visible','off');
syncBoxArray(3) = patch(ax,'Faces',[1:4,1],'Vertices',[syncX,[H-5*w;H-5*w;H-4*w;H-4*w]],'FaceColor','w','EdgeColor','w','Tag','Sync_Hit','Visible','off');

% Open log files
trialLogFile = fopen(trialLogFileName, 'w');
fprintf(trialLogFile, 'TrialNumber\tStartTime\tEndTime\tDuration\tResult\tFirstContactTime\tHorizontalTargetOffset\tVerticalTargetOffset\tTargetDistance\tTargetWidth\tStartTargetHoldDuration\tTimeToLeaveStart\tControlType\n');
cursorLogFile = fopen(cursorLogFileName, 'w');

% Close the log files when the figure is closed
set(fig, 'CloseRequestFcn', @(~,~) onClose(trialLogFile, cursorLogFile, fig));
dt = datetime('today');

% Start the task
if isempty(inlet)
    % Set up the WindowButtonMotionFcn to track mouse movement
    set(fig, 'WindowButtonMotionFcn', @(src, event) mouseMove(src, ax, cursor));
    mouseMove(nan, ax, cursor); % Set the initial cursor position.
    controlType = options.MouseType;
    if ~ismember(controlType, [enum.FittsControlType.MOUSE, enum.FittsControlType.TRACKPAD])
        error("controlType: enum.FittsControlType.%s is NOT a registered valid mouse control type!", string(options.MouseType));
    end
    runTaskWithMouse(ax, cursor, startTarget, targets, syncBoxArray, options, infoTextBox, trialLogFile, cursorLogFile);
else
    controlType = options.InletType;
    switch controlType
        case enum.FittsControlType.LSL_XBOX_VELOCITY
            runTaskWithVelocityInlet(inlet, ax, cursor, startTarget, targets, syncBoxArray, options, infoTextBox, trialLogFile, cursorLogFile);
        case enum.FittsControlType.LSL_XBOX_VELOCITY_CENTERED
            runTaskWithVelocityInlet(inlet, ax, cursor, startTarget, targets, syncBoxArray, options, infoTextBox, trialLogFile, cursorLogFile);
        otherwise
            runTaskWithPositionInlet(inlet, ax, cursor, startTarget, targets, syncBoxArray, options, infoTextBox, trialLogFile, cursorLogFile);
    end
end

[trialsTable, performance] = readFittsLogs(options.SubjectName, year(dt), month(dt), day(dt), indexingKey);
head(trialsTable);
disp(performance.index);


if ~ismissing(performance.model)
    fig = plot_fitts_result(trialsTable, performance,'Subtitle',sprintf('Controller: %s',strrep(string(controlType),"_","\_")));
    fname_fig = strrep(trialLogFileName,'_Trials_','_Fit_');
    [p,f,~]= fileparts(fname_fig);
    utils.save_figure(fig,p,f,'SaveFigure',false,'ExportAs',{'.png'},'CloseFigure',false);
end

    function onClose(trialLogFile, cursorLogFile, fig)
        fclose(trialLogFile);
        fclose(cursorLogFile);
        delete(fig);
    end

    function [trialLogFileName, cursorLogFileName, indexingKey] = generateLogFileNames(subjectName, indexingKey)
        dt_tmp = datetime('today');
        dateStr = sprintf('%04d_%02d_%02d', year(dt_tmp), month(dt_tmp), day(dt_tmp));
        tank = sprintf('%s_%s', subjectName, dateStr);
        if exist(fullfile(pwd,'logs', tank),'dir')==0
            mkdir(fullfile(pwd,'logs', tank));
        end

        trialLogFileName = fullfile(pwd,sprintf('logs/%s/%s_Trials_%d.tsv', tank, tank, indexingKey));

        % Check if the file already exists, if so, increment the indexing key
        while exist(trialLogFileName, 'file')
            indexingKey = indexingKey + 1;
            trialLogFileName = fullfile(pwd,sprintf('logs/%s/%s_Trials_%d.tsv', tank, tank, indexingKey));
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
                    targetPosition(iCount,:) = basis(ij,:).*distance(ii) + r0; % e.g. [r0, distance(ii)+r0]; % Top left corner
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
        set(cursor, 'XData', [cursor.XData(2:end),cursorX], 'YData', [cursor.YData(2:end),cursorY]);
    end

    function runTaskWithPositionInlet(inlet, ax, cursor, startTarget, targets, syncBox, options, infoTextBox, trialLogFile, cursorLogFile)
        % Run the Fitts Law task with LSL inlet
        numTargets = length(targets);
        totalTrials = options.TrialsPerTarget * numTargets;
        trialCount = 0;
        targetIndex = randsample(numTargets, 1);
        isTrialActive = false;
        trialStartTime = 0;
        hoverStartTime = 0;
        isHovering = false;
        firstContactTime = [];
        hasExitedStartTarget = false;
        leaveStartTargetTime = 0;

        % Calibration phase
        % [T,mu] = calibrateInlet(cursor, trialTextBox, inlet, options);
        T = eye(2);
        mu = [0,0];
        cursorX = cursor.XData(end);
        cursorY = cursor.YData(end);

        targetWidth = targets(targetIndex).UserData.r*2;
        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
        targetDistance = sqrt(xOffset.^2 + yOffset.^2);
        while (trialCount < totalTrials) && ishandle(ax)
            % Time this loop iteration.
            loopTic = tic;

            % Get the current cursor position from the inlet
            sample = inlet.pull_chunk();
            if ~isempty(sample)
                sample = ((sample(1:2,end)' - mu) * T) .* [cursor.UserData.xg, cursor.UserData.yg] + [cursor.UserData.x0, cursor.UserData.y0];
                cursorX = sample(1);
                cursorY = sample(2);
            end

            % Update the cursor position
            set(cursor, ...
                'XData', [cursor.XData(2:end),cursorX], ...
                'YData', [cursor.YData(2:end), cursorY]);

            if ~isTrialActive
                % Start the trial when cursor enters the start target
                if isInTarget(cursorX, cursorY, startTarget)
                    if ~isHovering
                        isHovering = true;
                        hoverStartTime = tic;
                        if ~isempty(ax.UserData)
                            write(ax.UserData, '1', 'c');
                        end
                        targetWidth = targets(targetIndex).UserData.r*2;
                        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
                        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
                        targetDistance = sqrt(xOffset.^2 + yOffset.^2);
                        syncBox(1).Visible = 'on';
                        set(startTarget, 'FaceColor', 'c');
                        startTime = datetime('now');
                        randomDelay = options.StartTargetHoldRange(1) + (options.StartTargetHoldRange(2) - options.StartTargetHoldRange(1)) * rand; % Random delay between 0.75 and 1.25 seconds
                    end
                    currentHoldTime = toc(hoverStartTime);
                    if currentHoldTime >= randomDelay
                        % Random delay duration met, show the target
                        isTrialActive = true;
                        trialStartTime = tic;
                        set(targets(targetIndex), 'Visible', 'on'); % Show the target
                        if ~isempty(ax.UserData)
                            write(ax.UserData,'2','c');
                        end
                        syncBox(2).Visible = 'on';
                        updateTrialText(infoTextBox, trialCount + 1, totalTrials);
                        if isInTarget(cursorX,cursorY,targets(targetIndex))
                            isHovering = true;
                            hoverStartTime = tic;
                            set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
                            syncBox(3).Visible = 'on';
                            leaveStartTargetTime = toc(trialStartTime);
                        end
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        "Time:"; ...
                        string(sprintf('Hold: %.3fs', currentHoldTime))]);
                else
                    isHovering = false;
                end
            else
                % Update countdown timer in trialTextBox
                remainingTime = options.MaxTrialDuration - toc(trialStartTime);
                if ~hasExitedStartTarget
                    if ~isInTarget(cursorX, cursorY, startTarget)
                        hasExitedStartTarget = true;
                        set(startTarget, 'FaceColor', 'g');
                        leaveStartTargetTime = toc(trialStartTime);
                    end
                end
                % Check if the trial is completed
                if isInTarget(cursorX, cursorY, targets(targetIndex))
                    if isempty(firstContactTime)
                        firstContactTime = toc(trialStartTime);
                        if ~isempty(ax.UserData)
                            write(ax.UserData, '3', 'c');
                        end
                    end
                    if ~isHovering
                        isHovering = true;
                        hoverStartTime = tic;
                        set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
                        syncBox(3).Visible = 'on';
                    else
                        currentHoldTime = toc(hoverStartTime);
                        set(infoTextBox, 'String', ...
                            [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                            string(sprintf('Time: %.3fs', remainingTime)); ...
                            string(sprintf('Hold: %.3fs', currentHoldTime))]);
                        if currentHoldTime >= options.HoverDuration
                            % Hovering duration met, trial completed
                            set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                            set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                            if ~isempty(ax.UserData)
                                write(ax.UserData,'0','c');
                            end
                            trialCount = trialCount + 1;
                            isTrialActive = false;
                            isHovering = false;
                            targetIndex = mod(trialCount, numTargets) + 1;
                            endTime = datetime('now');
                            duration = toc(trialStartTime);
                            hasExitedStartTarget = false;
                            set(syncBox,'Visible','off');
                            writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Success', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.InletType);
                            firstContactTime = [];
                            leaveStartTargetTime = 0;
                        end
                    end
                else % Left the target
                    if isHovering
                        isHovering = false;
                        set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        string(sprintf('Time: %.3fs', remainingTime)); ...
                        "Hold: 0.000s"]);
                    syncBox(3).Visible = 'off';
                end
                % End the trial if max duration is reached
                if toc(trialStartTime) > options.MaxTrialDuration
                    set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                    isTrialActive = false;
                    isHovering = false;
                    leaveStartTargetTime = toc(trialStartTime);
                    if ~isempty(ax.UserData)
                        write(ax.UserData, '0', 'c');
                    end
                    set(targets(targetIndex), 'FaceColor', 'r');
                    endTime = datetime('now');
                    duration = toc(trialStartTime);
                    trialCount = trialCount + 1;
                    targetIndex = mod(trialCount, numTargets) + 1;
                    set(syncBox,'Visible','off');
                    writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Failed', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.InletType);
                    firstContactTime = [];
                    leaveStartTargetTime = 0;
                end
            end

            % Log cursor position
            updateCursorLog(cursorLogFile, cursorX, cursorY);

            drawnow;
            while toc(loopTic) < options.GameLoopPauseDuration
                pause(0.005);
            end
        end

        % Task completed
        if ishandle(ax)
            close(ax.Parent);
        end
    end

    % function [T,mu] = calibrateInlet(cursor, trialTextBox, inlet, options)
    %     % Calibration phase for the Fitts Law task with LSL inlet
    %     calibrationPrompts = {'Rest', 'Move Right', 'Move Up'};
    %     calibrationDurations = [5, 5, 5]; % in seconds
    % 
    %     % Initialize variables to store calibration data
    %     restSamples = [];
    %     rightSamples = [];
    %     upSamples = [];
    % 
    %     for iCal = 1:length(calibrationPrompts)
    %         % Display calibration prompt
    %         set(trialTextBox, 'String', calibrationPrompts{iCal});
    %         drawnow;
    % 
    %         % Collect samples during the calibration period
    %         calibrationStartTime = tic;
    %         currentSamples = [];
    %         while toc(calibrationStartTime) < calibrationDurations(iCal)
    %             loopTic = tic;
    %             sample = inlet.pull_sample();
    %             cursorX = sample(1);
    %             cursorY = sample(2);
    %             currentSamples = [currentSamples; cursorX, cursorY]; %#ok<AGROW>
    % 
    %             % Update the cursor position
    %             set(cursor, 'XData', cursorX, 'YData', cursorY);
    % 
    %             drawnow;
    %             while toc(loopTic) < options.GameLoopPauseDuration
    %                 pause(0.005);
    %             end
    %         end
    % 
    %         % Store samples for each calibration phase
    %         switch calibrationPrompts{i}
    %             case 'Rest'
    %                 restSamples = currentSamples;
    %             case 'Move Right'
    %                 rightSamples = currentSamples;
    %             case 'Move Up'
    %                 upSamples = currentSamples;
    %         end
    % 
    %         % Clear the prompt
    %         set(trialTextBox, 'String', '');
    %         drawnow;
    %         pause(0.5);
    %     end
    % 
    %     % Compute average cursor positions for each phase
    %     mu = mean(restSamples, 1);
    %     rightPos = mean(rightSamples, 1);
    %     upPos = mean(upSamples, 1);
    % 
    %     % Compute transformation matrix to map cursor positions to task space directions
    %     rightVector = rightPos - mu;
    %     upVector = upPos - mu;
    % 
    %     % Normalize the vectors
    %     rightVector = rightVector / norm(rightVector);
    %     upVector = upVector / norm(upVector);
    % 
    %     % Compute the transformation matrix
    %     T = [rightVector(:), upVector(:)];
    % end
    % 

    function runTaskWithMouse(ax, cursor, startTarget, targets, syncBox, options, infoTextBox, trialLogFile, cursorLogFile)
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
        hasExitedStartTarget = false;
        leaveStartTargetTime = 0;

        targetWidth = targets(targetIndex).UserData.r*2;
        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
        targetDistance = sqrt(xOffset.^2 + yOffset.^2);
        while (trialCount < totalTrials) && ishandle(ax)
            % Cursor position is updated by the mouseMove function
            loopTic = tic;

            % Get the current cursor position from the cursor object
            cursorX = cursor.XData(end);
            cursorY = cursor.YData(end);

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
                        targetWidth = targets(targetIndex).UserData.r*2;
                        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
                        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
                        targetDistance = sqrt(xOffset.^2 + yOffset.^2);
                        syncBox(1).Visible = 'on';
                        startTime = datetime('now');
                        randomDelay = options.StartTargetHoldRange(1) + (options.StartTargetHoldRange(2)-options.StartTargetHoldRange(1))*rand; % Random delay between 0.75 and 1.25 seconds
                    end
                    currentHoldTime = toc(hoverStartTime);
                    if currentHoldTime >= randomDelay
                        % Random delay duration met, show the target
                        isTrialActive = true;
                        trialStartTime = tic;
                        set(targets(targetIndex), 'Visible', 'on'); % Show the target
                        if ~isempty(ax.UserData)
                            write(ax.UserData,'2','c');
                        end
                        syncBox(2).Visible = 'on';
                        updateTrialText(infoTextBox, trialCount + 1, totalTrials);
                        if isInTarget(cursorX,cursorY,targets(targetIndex))
                            isHovering = true;
                            hoverStartTime = tic;
                            set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
                            syncBox(3).Visible = 'on';
                            leaveStartTargetTime = toc(trialStartTime);
                        end
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        "Time: "; ...
                        string(sprintf('Hold: %.3fs', currentHoldTime))]);
                else
                    isHovering = false;
                end
            else
                % Update countdown timer in trialTextBox
                remainingTime = options.MaxTrialDuration - toc(trialStartTime);

                if ~hasExitedStartTarget
                    if ~isInTarget(cursorX, cursorY, startTarget)
                        hasExitedStartTarget = true;
                        set(startTarget, 'FaceColor', 'g');
                        leaveStartTargetTime = toc(trialStartTime);
                    end
                end
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
                        syncBox(3).Visible = 'on';
                    else
                        currentHoldTime = toc(hoverStartTime);
                        set(infoTextBox, 'String', ...
                            [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                            string(sprintf('Time: %.3fs', remainingTime)); ...
                            string(sprintf('Hold: %.3fs', currentHoldTime))]);
                        if currentHoldTime >= options.HoverDuration
                            % Hovering duration met, trial completed
                            set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                            set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                            if ~isempty(ax.UserData)
                                write(ax.UserData,'0','c');
                            end
                            trialCount = trialCount + 1;
                            isTrialActive = false;
                            isHovering = false;
                            targetIndex = mod(trialCount, numTargets) + 1;
                            endTime = datetime('now');
                            duration = toc(trialStartTime);
                            hasExitedStartTarget = false;
                            set(syncBox,'Visible','off');
                            writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Success', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.MouseType);
                            firstContactTime = [];
                            leaveStartTargetTime = 0;
                        end
                    end
                else % Left target
                    if isHovering
                        isHovering = false;
                        set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        string(sprintf('Time: %.3fs', remainingTime)); ...
                        "Hold: 0.000s"]);
                    syncBox(3).Visible = 'off';
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
                    trialCount = trialCount + 1;
                    targetIndex = mod(trialCount, numTargets) + 1;
                    set(syncBox,'Visible','off');
                    writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Failed', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.MouseType);
                    firstContactTime = [];
                    leaveStartTargetTime = 0;
                end
            end

            % Log cursor position
            updateCursorLog(cursorLogFile, cursorX, cursorY);

            drawnow;
            while toc(loopTic) < options.GameLoopPauseDuration
                pause(0.005);
            end
        end

        % Task completed
        if ishandle(ax)
            close(ax.Parent);
        end
    end

    function runTaskWithVelocityInlet(inlet, ax, cursor, startTarget, targets, syncBox, options, infoTextBox, trialLogFile, cursorLogFile)
        % Run the Fitts Law task with LSL inlet
        numTargets = length(targets);
        totalTrials = options.TrialsPerTarget * numTargets;
        trialCount = 0;
        targetIndex = randsample(numTargets, 1);
        isTrialActive = false;
        trialStartTime = 0;
        hoverStartTime = 0;
        isHovering = false;
        firstContactTime = [];
        hasExitedStartTarget = false;
        leaveStartTargetTime = 0;
        set(ax)

        % Calibration phase
        % [T,mu] = calibrateInlet(cursor, trialTextBox, inlet);
        T = eye(2);
        mu = [0,0];
        cursorX = cursor.XData(end);
        cursorY = cursor.YData(end);
        targetWidth = targets(targetIndex).UserData.r*2;
        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
        targetDistance = sqrt(xOffset.^2 + yOffset.^2);

        while (trialCount < totalTrials) && ishandle(ax)
            % Time this loop iteration.
            loopTic = tic;

            % Get the current cursor position from the inlet
            sample = inlet.pull_chunk();
            if ~isempty(sample)
                v = ((sample(1:2,end)' - mu) * T) .* [cursor.UserData.xg, cursor.UserData.yg] + [cursor.UserData.x0, cursor.UserData.y0];
                cursorX = cursorX + v(1);
                cursorY = cursorY + v(2);
            end

            % Update the cursor position
            set(cursor, ...
                'XData', [cursor.XData(2:end),cursorX], ...
                'YData', [cursor.YData(2:end), cursorY]);

            if ~isTrialActive
                % Start the trial when cursor enters the start target
                if isInTarget(cursorX, cursorY, startTarget)
                    if ~isHovering
                        isHovering = true;
                        hoverStartTime = tic;
                        if ~isempty(ax.UserData)
                            write(ax.UserData, '1', 'c');
                        end
                        targetWidth = targets(targetIndex).UserData.r*2;
                        xOffset = targets(targetIndex).UserData.x - startTarget.UserData.x;
                        yOffset = targets(targetIndex).UserData.y - startTarget.UserData.y;
                        targetDistance = sqrt(xOffset.^2 + yOffset.^2);
                        syncBox(1).Visible = 'on';
                        set(startTarget, 'FaceColor', 'c');
                        startTime = datetime('now');
                        randomDelay = options.StartTargetHoldRange(1) + (options.StartTargetHoldRange(2) - options.StartTargetHoldRange(1)) * rand; % Random delay between 0.75 and 1.25 seconds
                    end
                    currentHoldTime = toc(hoverStartTime);
                    if currentHoldTime >= randomDelay
                        % Random delay duration met, show the target
                        isTrialActive = true;
                        trialStartTime = tic;
                        set(targets(targetIndex), 'Visible', 'on'); % Show the target
                        if ~isempty(ax.UserData)
                            write(ax.UserData,'2','c');
                        end
                        syncBox(2).Visible = 'on';
                        updateTrialText(infoTextBox, trialCount + 1, totalTrials);
                        if isInTarget(cursorX,cursorY,targets(targetIndex))
                            isHovering = true;
                            hoverStartTime = tic;
                            set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
                            syncBox(3).Visible = 'on';
                            leaveStartTargetTime = toc(trialStartTime);
                        end
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        "Time:"; ...
                        string(sprintf('Hold: %.3fs', currentHoldTime))]);
                else
                    isHovering = false;
                end
            else
                % Update countdown timer in trialTextBox
                remainingTime = options.MaxTrialDuration - toc(trialStartTime);


                if ~hasExitedStartTarget
                    if ~isInTarget(cursorX, cursorY, startTarget)
                        hasExitedStartTarget = true;
                        set(startTarget, 'FaceColor', 'g');
                        leaveStartTargetTime = toc(trialStartTime);
                    end
                end
                % Check if the trial is completed
                if isInTarget(cursorX, cursorY, targets(targetIndex))
                    if isempty(firstContactTime)
                        firstContactTime = toc(trialStartTime);
                        if ~isempty(ax.UserData)
                            write(ax.UserData, '3', 'c');
                        end
                    end
                    if ~isHovering
                        isHovering = true;
                        hoverStartTime = tic;
                        set(targets(targetIndex), 'FaceColor', 'c'); % Change color to cyan
                        syncBox(3).Visible = 'on';
                    else
                        currentHoldTime = toc(hoverStartTime);
                        set(infoTextBox, 'String', ...
                            [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                            string(sprintf('Time: %.3fs', remainingTime)); ...
                            string(sprintf('Hold: %.3fs', currentHoldTime))]);
                        if currentHoldTime >= options.HoverDuration
                            % Hovering duration met, trial completed
                            set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                            set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                            if ~isempty(ax.UserData)
                                write(ax.UserData,'0','c');
                            end
                            trialCount = trialCount + 1;
                            isTrialActive = false;
                            isHovering = false;
                            targetIndex = mod(trialCount, numTargets) + 1;
                            endTime = datetime('now');
                            duration = toc(trialStartTime);
                            hasExitedStartTarget = false;
                            set(syncBox,'Visible','off');
                            writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Success', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.InletType);
                            if options.InletType == enum.FittsControlType.LSL_XBOX_VELOCITY_CENTERED
                                cursorX = startTarget.UserData.x;
                                cursorY = startTarget.UserData.y;
                            end
                            firstContactTime = [];
                            leaveStartTargetTime = 0;
                        end
                    end
                else % Left the target
                    if isHovering
                        isHovering = false;
                        set(targets(targetIndex), 'FaceColor', 'r'); % Reset color to red
                    end
                    set(infoTextBox, 'String', ...
                        [string(sprintf('Trial %d of %d',trialCount+1,totalTrials)); ...
                        string(sprintf('Time: %.3fs', remainingTime)); ...
                        "Hold: 0.000s"]);
                    syncBox(3).Visible = 'off';
                end
                % End the trial if max duration is reached
                if toc(trialStartTime) > options.MaxTrialDuration
                    set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                    isTrialActive = false;
                    isHovering = false;
                    leaveStartTargetTime = toc(trialStartTime);
                    if ~isempty(ax.UserData)
                        write(ax.UserData, '0', 'c');
                    end
                    set(targets(targetIndex), 'FaceColor', 'r');
                    endTime = datetime('now');
                    duration = toc(trialStartTime);
                    trialCount = trialCount + 1;
                    targetIndex = mod(trialCount, numTargets) + 1;
                    set(syncBox,'Visible','off');
                    writeFittsLog(trialLogFile, trialCount, startTime, endTime, duration, 'Failed', firstContactTime, xOffset, yOffset, targetDistance, targetWidth, randomDelay, leaveStartTargetTime, options.InletType);
                    if options.InletType == enum.FittsControlType.LSL_XBOX_VELOCITY_CENTERED
                        cursorX = startTarget.UserData.x;
                        cursorY = startTarget.UserData.y;
                    end
                    firstContactTime = [];
                    leaveStartTargetTime = 0;
                end
            end

            % Log cursor position
            updateCursorLog(cursorLogFile, cursorX, cursorY);

            drawnow;
            while toc(loopTic) < options.GameLoopPauseDuration
                pause(0.005);
            end
        end

        % Task completed
        if ishandle(ax)
            close(ax.Parent);
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

    function updateCursorSettings(src,evt)
        switch evt.Key
            case 'w'
                src.UserData.cursor.UserData.y0 = src.UserData.cursor.UserData.y0 + 1;
            case 's'
                src.UserData.cursor.UserData.y0 = src.UserData.cursor.UserData.y0 - 1;
            case 'a'
                src.UserData.cursor.UserData.x0 = src.UserData.cursor.UserData.x0 - 1;
            case 'd'
                src.UserData.cursor.UserData.x0 = src.UserData.cursor.UserData.x0 + 1;
            case 'uparrow'
                src.UserData.cursor.UserData.yg = src.UserData.cursor.UserData.yg + 0.25;
            case 'downarrow'
                src.UserData.cursor.UserData.yg = src.UserData.cursor.UserData.yg - 0.25;
            case 'leftarrow'
                src.UserData.cursor.UserData.xg = src.UserData.cursor.UserData.xg - 0.25;
            case 'rightarrow'
                src.UserData.cursor.UserData.xg = src.UserData.cursor.UserData.xg + 0.25;
            case 'escape'
                close(src);
            % otherwise
                % disp(evt);
        end
    end
end

