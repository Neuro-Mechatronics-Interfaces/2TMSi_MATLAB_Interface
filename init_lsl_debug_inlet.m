function inlet = init_lsl_debug_inlet(lib)
%INIT_LSL_DEBUG_INLET Create an LSL inlet to connect to the test outlet.
%
%   The inlet connects to the test outlet and prints the received samples
%   to the MATLAB command window.

% Resolve the stream info for the test outlet
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'MATLAB_Keystroke_Position');
end

fprintf(1,'Found %d inlets for MATLAB_Keystroke_Position!\n',numel(result));
for ii = 1:(numel(result)-1)
    delete(result{ii});
end
% Create an LSL inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{end});

end
