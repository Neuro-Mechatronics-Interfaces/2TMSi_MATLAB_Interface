function startMicrocontrollerIfPresent(src,~)
%STARTMICROCONTROLLERIFPRESENT Starts the microcontroller indicator of task running.
if isstruct(src.UserData)
    if isfield(src.UserData,'Teensy')
        if isempty(src.UserData.Teensy)
            warning('Teensy field in UserData has not been initialized yet!'); 
        else
            writeline(src.UserData.Teensy, '1');
        end
    else
        warning('No `Teensy` field in UserData of timer object!');
    end
else
    warning('Timer UserData is not a struct- has it been initialized yet?');
end

dt = datetime('now', 'TimeZone', 'America/New_York');
writeline(src.UserData.UDP, sprintf(src.UserData.FileString, src.UserData.Subject, ...
    year(dt), month(dt), day(dt), src.UserData.Block), src.UserData.TMSiAddress, 3031);
src.UserData.Block = src.UserData.Block + 1;
pause(0.010);
writeline(src.UserData.UDP, 'rec', src.UseRData.TMSiAddress, 3030);

end