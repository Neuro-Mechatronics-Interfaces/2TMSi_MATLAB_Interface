function fig = init_remote_mouse_controller(options)
    arguments
        options.RemoteIP {mustBeTextScalar} = "10.0.0.101";
        options.XGain (1,1) = 1; % Modifies the x delta sent to remote
        options.YGain (1,1) = 1; % Modifies the y delta sent to remote
    end

    % Create a uifigure with reasonable properties
    fig = uifigure('Name', 'Remote Mouse Controller', ...
                   'Position', [100, 100, 800, 600], ...
                   'WindowButtonMotionFcn', @mouseMovementCallback);

    % Set up TCP connections
    fig.UserData = struct;
    fig.UserData.gamepad = tcpclient(options.RemoteIP, 6053);
    fig.UserData.mouse = tcpclient(options.RemoteIP, 6054);
    fig.UserData.LastMousePosition = get(fig, 'CurrentPoint');
    fig.UserData.XGain = options.XGain;
    fig.UserData.YGain = options.YGain;

    % Callback function for mouse movement
    function mouseMovementCallback(src, ~)
        % Get current mouse position
        currentPoint = get(src, 'CurrentPoint');

        % Calculate delta
        dx = (currentPoint(1) - src.UserData.LastMousePosition(1)) * src.UserData.XGain;
        dy = (src.UserData.LastMousePosition(2) - currentPoint(2)) * src.UserData.YGain;

        % Send the delta to the remote server
        if dx ~= 0 || dy ~= 0
            writeline(src.UserData.mouse, sprintf('x,%d,%d', round(dx), round(dy)));
        end

        % Update last mouse position
        src.UserData.LastMousePosition = currentPoint;
    end
end
