function fig = init_lsl_debug_outlet(lib)
% CREATE_LSL_OUTLET_WITH_FIGURE Create an LSL outlet and a figure to control it.
%
%   The figure listens to keystrokes 'w', 'a', 's', 'd' and updates the
%   position state accordingly. The 2D position is transmitted to the outlet
%   as a sample.

% Create a figure to listen to keystrokes
fig = figure('Name', 'Keystroke Control', 'NumberTitle', 'off', ...
    'KeyPressFcn', @keyPressCallback, ...
    'UserData',struct('position',[0; 0]),...
    'DeleteFcn',@handleDeletion);

% Create an LSL outlet
fig.UserData.info = lsl_streaminfo(lib, 'MATLAB_Keystroke_Position', 'Position', 2, 30, 'cf_float32', 'matlab_keystroke_position');
chns = fig.UserData.info.desc().append_child('channels');
c = chns.append_child('channel');
c.append_child_value('name', 'X');
c.append_child_value('label', 'X');
c.append_child_value('unit', 'none');
c.append_child_value('type','Control');
c = chns.append_child('channel');
c.append_child_value('name', 'Y');
c.append_child_value('label', 'Y');
c.append_child_value('unit', 'none');
c.append_child_value('type','Control');
fig.UserData.outlet = lsl_outlet(fig.UserData.info);

    function handleDeletion(src,~)
        delete(src.UserData.outlet);
        delete(src.UserData.info);
    end

% Nested callback function to handle keystrokes
    function keyPressCallback(src, event)
        switch event.Key
            case 'w'
                src.UserData.position(2) = src.UserData.position(2) + 1; % Up
            case 'a'
                src.UserData.position(1) = src.UserData.position(1) - 1; % Left
            case 's'
                src.UserData.position(2) = src.UserData.position(2) - 1; % Down
            case 'd'
                src.UserData.position(1) = src.UserData.position(1) + 1; % Right
        end
        % Transmit the new position as a sample
        src.UserData.outlet.push_sample(src.UserData.position);
        disp("Sample sent!");
    end
end
