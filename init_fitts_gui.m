function fig = init_fitts_gui(inlet, options)

arguments
    inlet
    options.TrialsPerTarget (1,1) double = 10;
    options.MaxTrialDuration (1,1) double = 20;
    options.TargetDistance (1,:) double = [8, 12, 16];
    options.TargetWidth (1,:) double = [1, 2, 4];
end

% Initialize the figure
fig = figure('Name', 'Fitts Law Task', 'NumberTitle', 'off', ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Color', 'w');

% Set up the axes
ax = axes('Parent', fig, ...
    'XLim', [0 20], 'YLim', [0 20], ...
    'DataAspectRatio', [1 1 1]);
hold(ax, 'on');

% Create the start target
startTarget = createTarget(ax, 1, 1, 2, 'g');

% Generate random target positions
targetPositions = generateTargetPositions(options.TargetDistance);

% Create targets
targets = gobjects(1, length(targetPositions));
for i = 1:length(targetPositions)
    targets(i) = createTarget(ax, targetPositions(i,1), targetPositions(i,2), options.TargetWidth(i)/2, 'r');
end

% Initialize cursor
cursor = plot(ax, 2, 2, 'b+', 'MarkerSize', 10, 'MarkerFaceColor', 'b', 'MarkerEdgeColor','b','LineWidth',3);

% Start the task
runTask(inlet, ax, cursor, startTarget, targets, options);

end

function target = createTarget(ax, x, y, radius, color)
    % Create a circular target using a patch object
    theta = linspace(0, 2*pi, 100);
    xCircle = radius * cos(theta) + x;
    yCircle = radius * sin(theta) + y;
    target = patch(ax, xCircle, yCircle, color, 'EdgeColor', 'none');
end

function targetPositions = generateTargetPositions(distances)
    % Generate target positions based on specified distances
    % Target positions are set at the far right corner and the top left corner
    numDistances = length(distances);
    targetPositions = zeros(numDistances, 2);
    for i = 1:numDistances
        if mod(i, 2) == 1
            targetPositions(i,:) = [20 - distances(i), 20]; % Far right corner
        else
            targetPositions(i,:) = [distances(i), 20]; % Top left corner
        end
    end
end

function runTask(inlet, ax, cursor, startTarget, targets, options)
    % Run the Fitts Law task
    numTargets = length(targets);
    trialCount = 0;
    targetIndex = 1;
    isTrialActive = false;
    trialStartTime = 0;

    while trialCount < options.TrialsPerTarget * numTargets
        % Get the current cursor position
        sample = inlet.pull_sample();
        cursorX = sample(1);
        cursorY = sample(2);

        % Update the cursor position
        set(cursor, 'XData', cursorX, 'YData', cursorY);

        if ~isTrialActive
            % Start the trial when cursor enters the start target
            if isInTarget(cursorX, cursorY, startTarget)
                isTrialActive = true;
                trialStartTime = tic;
                set(targets(targetIndex), 'Visible', 'on'); % Show the target
            end
        else
            % Check if the trial is completed
            if isInTarget(cursorX, cursorY, targets(targetIndex))
                set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                trialCount = trialCount + 1;
                isTrialActive = false;
                targetIndex = mod(trialCount, numTargets) + 1;
            end
            % End the trial if max duration is reached
            if toc(trialStartTime) > options.MaxTrialDuration
                set(targets(targetIndex), 'Visible', 'off'); % Hide the target
                isTrialActive = false;
            end
        end

        drawnow;
        pause(0.030);
    end

    % Task completed
    msgbox('Task completed!', 'Fitts Law Task');
end

function isInside = isInTarget(x, y, target)
    % Check if the point (x, y) is inside the target
    targetVertices = get(target, 'Vertices');
    targetX = targetVertices(:,1);
    targetY = targetVertices(:,2);
    isInside = inpolygon(x, y, targetX, targetY);
end
