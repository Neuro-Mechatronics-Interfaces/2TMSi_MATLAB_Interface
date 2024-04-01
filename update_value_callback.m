function update_value_callback(src, ~)

data = jsondecode(src.readline());
if strcmpi(src.UserData.SelectedSAGA, data.SAGA) && src.UserData.Running
    % disp(data.rate(src.UserData.ControlChannel
    
    set(src.UserData.Timer.UserData.Cursor,'YData',0.1 * (data.rate(src.UserData.ControlChannel)/100) + 0.9 * (src.UserData.Timer.UserData.Cursor.YData),'XData',src.UserData.CurrentTime);
    src.UserData.CurrentTime = src.UserData.CurrentTime + data.n/4000;
    set(src.UserData.Timer.UserData.Axes, 'XLim', [src.UserData.CurrentTime - 0.5, src.UserData.CurrentTime + 0.5]);
    if src.UserData.CurrentTime > src.UserData.Timer.UserData.Time(end)
        src.UserData.Running = false;
    end
end


% if (src.UserData.CurrentTimeIndex > 1) && strcmpi(src.UserData.SelectedSAGA, data.SAGA)
%     src.UserData.Value(src.UserData.CurrentTimeIndex) = src.UserData.Value(src.UserData.CurrentTimeIndex-1) + 0.25*data.rate(src.UserData.ControlChannel);
% else
%     src.UserData.Value(1) = 0.75*src.UserData.Value(1) + 0.25*data.rate(src.UserData.ControlChannel);
% end
% delete(src.UserData.h.(data.SAGA));
% src.UserData.h.(data.SAGA) = bar(src.UserData.h.ax,1:64,data.rate','Color','k');
% drawnow();
end