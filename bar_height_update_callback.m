function bar_height_update_callback(src, hBarA, hBarB)
%BAR_HEIGHT_UPDATE_CALLBACK Update the heights of the bars according to counts in tcpclient UserData.A.x, UserData.A.y, UserData.B.x, UserData.B.y fields.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.

set(hBarA,'XData',src.UserData.A.x, 'YData', src.UserData.A.y);
set(hBarB,'XData',src.UserData.B.x, 'YData', src.UserData.B.y);
drawnow();
% disp('Tick');
end