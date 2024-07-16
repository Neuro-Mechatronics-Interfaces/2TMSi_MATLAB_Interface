% Add the necessary LSL library
lslFolder = parameters('liblsl_folder');
if exist(lslFolder,'dir')==0
    lslFolder = 'C:/MyRepos/Libraries/liblsl-Matlab';
end
addpath(genpath(lslFolder));
lib = lsl_loadlib();



%% Create a figure with axes to display the point
% Resolve the stream
disp('Resolving an LSL stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'SAGACombined_Envelope_Decode');
end

% Create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

hFig = figure('Name', 'LSL Decoded Control', 'NumberTitle', 'off', 'Color', 'w');
% hAxes = axes('Parent', hFig, 'XLim', [-25, 25], 'YLim', [-25, 25], 'ZLim',[-25, 25], ...
%     'NextPlot','add','View',[-37.5000   30.0000]);
% box(hAxes,'on');
% grid(hAxes,'on');
% hPoint = plot3(hAxes, 0, 0, 0, 'ro', 'MarkerSize', 32, 'MarkerFaceColor', 'r');

% hAxes = axes('Parent', hFig, 'XLim', [-0.1,1.5], 'YLim', [-0.1,1.5], 'NextPlot','add');
hAxes = axes('Parent', hFig, 'NextPlot','add');
% hPoint = plot(hAxes, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
hPoint = plot(hAxes, zeros(1,100), zeros(1,100), 'ko-', 'MarkerIndices', 100, 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% client = tcpclient("10.0.0.101",6053);
% mouse = tcpclient("10.0.0.101", 6054);
T = calculate_transformation_matrix(-10, -8, 0, 3);
% T = eye(2);
% Update loop
disp('Now receiving data...');
mu = zeros(1,3);
loc = zeros(1,2);
while ishandle(hFig)
    % Pull a sample from the inlet
    [vec, ts] = inlet.pull_sample();
    % vec(1:2) = vec(2:-1:1);
    % mu = 0.995.*mu + 0.005.*vec;
    % vec = vec - mu;
    vec(1:2) = T * (vec(1:2) .* [1, 1])';
    
    % Update the point's position
    if ~isempty(vec)
        % set(hPoint, 'XData', vec(1), 'YData', vec(2), 'ZData', vec(3));
        set(hPoint, ...
            'XData', [hPoint.XData(2:end), vec(1)], ...
            'YData', [hPoint.YData(2:end), vec(2)]);
        drawnow;
        % loc = loc + vec(1:2);
        % writeline(mouse, sprintf('x,%d,%d',round(loc(1)),round(loc(2))));
    end
    
    % Small pause to prevent excessive CPU usage
    pause(0.01);
end
% delete(client);
% delete(mouse);
delete(inlet);
disp('LSL stream closed.');
