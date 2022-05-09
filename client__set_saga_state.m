function client__set_saga_state(client, state)
%CLIENT__SET_SAGA_STATE  Set SAGA controller/device state.
%
% Example:
% >> client__set_saga_state(client, "run");
%
% Syntax:
%   client__set_saga_state(client, state);
%
% Inputs:
%   client - tcpclient that is connected to CONTROLLER tcpserver
%   state  - "idle" | "run" | "rec" | "quit"



state_expr = sprintf('set.state.%s', state);
writeline(client, state_expr);
end