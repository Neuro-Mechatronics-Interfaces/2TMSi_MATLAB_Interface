% Add the necessary LSL library
lslFolder = parameters('liblsl_folder');
if exist(lslFolder,'dir')==0
    lslFolder = 'C:/MyRepos/Libraries/liblsl-Matlab';
end
addpath(genpath(lslFolder));
lib = lsl_loadlib();

disp('Resolving an LSL stream...');
result = {};
while isempty(result)
    result = lsl_resolve_byprop(lib, 'name', 'Gamepad');
end

% Create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});