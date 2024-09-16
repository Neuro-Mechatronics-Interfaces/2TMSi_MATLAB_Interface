function gui_1d_timer_callback(src, ~)
%GUI_1D_TIMER_CALLBACK  Callback for timer for 1D tracer GUI.

if ~isvalid(src.UserData.Figure)
    stop(src);
    disp("No valid 1D Tracer figure. Stopped timer.");
    return;
end
if src.UserData.Client.NumBytesAvailable > 0
    val = src.UserData.Client.read(src.UserData.Client.NumBytesAvailable);
    k = src.UserData.CurrentTimeIndex;
    src.UserData.Value(k) = val(end);
    set(src.UserData.Cursor,'XData',src.UserData.Time(k),'YData',val(end));
    xlim(src.UserData.Axes, [src.UserData.Time(k)-src.UserData.AxesWidth/2, src.UserData.Time(k)+src.UserData.AxesWidth/2]);
    if abs(src.UserData.Value(k) - src.UserData.Signal(k)) < src.UserData.ErrorTolerance
        src.UserData.Target.Color = 'b';
        src.UserData.Cursor.MarkerEdgeColor = 'k';
    else
        src.UserData.Target.Color = 'r';
        src.UserData.Cursor.MarkerEdgeColor = 'r';
    end
    src.UserData.CurrentTimeIndex = src.UserData.CurrentTimeIndex + 1;
    drawnow limitrate;
end


end