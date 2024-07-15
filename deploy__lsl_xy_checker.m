% Add the necessary LSL library
addpath(genpath('C:/MyRepos/Libraries/liblsl-Matlab'));
lib = lsl_loadlib();

% Resolve the stream
disp('Resolving an LSL stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'SAGACombined_Envelope_Decode');
end

% Create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

%% Create a figure with axes to display the point
hFig = figure('Name', 'LSL Decoded Control', 'NumberTitle', 'off', 'Color', 'w');
hAxes = axes('Parent', hFig, 'XLim', [-2.5, 2.5], 'YLim', [-2.5, 2.5], 'ZLim',[-2.5, 2.5], ...
    'NextPlot','add','View',[-37.5000   30.0000]);
box(hAxes,'on');
grid(hAxes,'on');
hPoint = plot3(hAxes, 0, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');

% Update loop
disp('Now receiving data...');
while ishandle(hFig)
    % Pull a sample from the inlet
    [vec, ts] = inlet.pull_sample();
    
    % Update the point's position
    if ~isempty(vec)
        set(hPoint, 'XData', vec(1), 'YData', vec(2), 'ZData', vec(3));
        drawnow;
    end
    
    % Small pause to prevent excessive CPU usage
    pause(0.01);
end

disp('LSL stream closed.');
