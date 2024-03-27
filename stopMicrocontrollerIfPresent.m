function stopMicrocontrollerIfPresent(src,~)
%STARTMICROCONTROLLERIFPRESENT Starts the microcontroller indicator of task running.
if isstruct(src.UserData)
    if isfield(src.UserData,'Teensy')
        if isempty(src.UserData.Teensy)
            warning('Teensy field in UserData has not been initialized yet!'); 
        else
            writeline(src.UserData.Teensy, '0');
        end
    else
        warning('No `Teensy` field in UserData of timer object!');
    end
else
    warning('Timer UserData is not a struct- has it been initialized yet?');
end