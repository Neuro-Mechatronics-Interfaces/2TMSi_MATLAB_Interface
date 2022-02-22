function print_error_message(me, stack_variable_name, fid)
%PRINT_ERROR_MESSAGE Prints error message details to command window.
%
% Syntax:
%   debugging.print_error_message(me);
%   debugging.print_error_message(me, stack_variable_name);
%
% Inputs:
%   me - Matlab Error struct (such as returned by an exception inside a
%           `try ... catch` statement).
%   stack_variable_name - (Optional: default is 'last_error_stack') 
%           --> Name that MATLAB ERROR object variable assigned in base
%               workspace should take.
%
% See also: Contents

if nargin < 2
    stack_variable_name = 'last_error_stack'; 
end

if nargin < 3
    fid = 1; 
end

disp(me);
fprintf(fid, '\n\tMessage\t-->%s\n', me.message);
for iStack = 1:numel(me.stack)
    fprintf(fid,'\t\t-->me.stack(%d)<--\n',iStack);
    fprintf(fid,'\t\tFile\t-->%s\n', me.stack(iStack).file);
    fprintf(fid,'\t\tName\t-->%s\n', me.stack(iStack).name);
    fprintf(fid,'\t\tLine\t-->%d\n', me.stack(iStack).line);
    disp(me.stack(iStack));
end
assignin('base', stack_variable_name, me);

end