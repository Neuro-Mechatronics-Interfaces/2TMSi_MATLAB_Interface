function stopMicrocontrollerAndSave(src,~)
%STOPMICROCONTROLLERANDSAVE Stops the microcontroller indicator of task running and saves log tracker.
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

dt = datetime('now', 'TimeZone', 'America/New_York');
out_file = fullfile(src.UserData.SaveFolder, sprintf('%04d-%02d-%02d_%02d-%02d-%02d_%s_Tracker_Logs.mat', ...
    year(dt), month(dt), day(dt), hour(dt), minute(dt), second(dt), src.UserData.LogIdentifier));

measured = src.UserData.Value;
target = src.UserData.Signal;
time = src.UserData.Time;
notes = src.UserData.Notes;
save(out_file, 'measured', 'target', 'time', 'notes', '-v7.3');

writeline(src.UserData.UDP, 'run', src.UserData.TMSiAddress, 3030);

end