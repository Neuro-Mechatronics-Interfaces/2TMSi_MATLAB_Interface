function addMicrocontrollerToGuiTimer(timerObj, options)
%ADDMICROCONTROLLERTOGUITIMER  Adds Microcontroller to Timer GUI for experiment/synchronization purposes.
%
% Syntax:
%   addMicrocontrollerToGuiTimer(timerObj, 'Name', value, ...);
%
% Inputs:
%   timerObj - MATLAB timer object.
%
% See also: Contents

arguments
    timerObj
    options.BaudRate (1,1) double {mustBeInteger, mustBePositive} = 115200;
    options.Port {mustBeTextScalar} = "";
end
if strlength(options.Port) == 0
    s = serialportlist;
    if isempty(s)
        error("No COM ports detected!");
    end
    if numel(s) > 1
        fprintf(1,'Please specify "Port" option as one of the following:\n');
        for ii = 1:numel(s)
            fprintf(1,'\t->\t%s\n', s(ii));
        end
        error("Multiple valid COM ports - unsure which to use!");
    else
        fprintf(1,'No COM port specified- using %s.\n',s);
    end
    port = s;
else
    port = options.Port;
end
timerObj.UserData.Teensy = serialport(port, options.BaudRate);

end