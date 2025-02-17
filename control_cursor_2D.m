function control_cursor_2D(src, evt, cursor)

data = jsondecode(src.readline());
if cursor.UserData.UseCalibration
    if cursor.UserData.Calibrated
        orig = [data.axis(1), data.axis(2)];
        origc = orig - cursor.UserData.mu;
        origcw = cursor.UserData.W * (origc');
        set(cursor,'XData',cursor.XData*(1-cursor.UserData.Alpha)+cursor.UserData.Alpha*origcw(1), ...
            'YData',cursor.YData*(1-cursor.UserData.Alpha)+cursor.UserData.Alpha*origcw(2)); % Position map
    else
        cursor.UserData.CalibrationData(cursor.UserData.CalibrationIndex,:) = [data.axis(1), data.axis(2)];
        cursor.UserData.CalibrationIndex = cursor.UserData.CalibrationIndex + 1;
        if cursor.UserData.CalibrationIndex > size(cursor.UserData.CalibrationData,1)
            cursor.UserData.Calibrated = true;
            disp('Whitening estimation complete!');
            cursor.UserData.mu = mean(cursor.UserData.CalibrationData,1);
            cursor.UserData.R = cov(cursor.UserData.CalibrationData-cursor.UserData.mu);
            cursor.UserData.W = chol(inv(cursor.UserData.R));
        end
    end
else
    set(cursor,'XData',(cursor.XData*(1-cursor.UserData.Alpha) + data.axis(1)*cursor.UserData.Alpha)/cursor.UserData.Scale(1), ...
            'YData', (cursor.YData*(1-cursor.UserData.Alpha) + data.axis(2)*cursor.UserData.Alpha)/cursor.UserData.Scale(2));
end
end