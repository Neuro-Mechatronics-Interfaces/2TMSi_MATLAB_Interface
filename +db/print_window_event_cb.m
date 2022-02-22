function print_window_event_cb(fig, evt)
%PRINT_WINDOW_EVENT_CB  Prints event callback debugging info and moves `evt` to base workspace.
%
% Syntax:
%   db_fig = figure('Name', 'Some Debugger for testing Keypress values',...
%                   'WindowKeyPressFcn', @debugging.print_window_event_cb);
%
% Output:
%   None, but `kp_db_evt` will be created in base workspace any time key is
%   pressed while that window has focus.

fprintf(1,'\n\t-->\t<strong>%s</strong> heard event (%s): %s\t<--\n\n', fig.Name, class(evt), evt.Key)
fprintf(1,'\t\t\t(Assigned following variable to `kp_db_evt` in base workspace):\n\t\t\t');
disp(evt);
assignin('base', 'kp_db_evt', evt);
end