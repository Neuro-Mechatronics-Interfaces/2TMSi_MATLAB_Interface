function bar_height_update_callback(hBarA, hBarB)
%BAR_HEIGHT_UPDATE_CALLBACK Update the heights of the bars according to counts in tcpclient UserData.A.x, UserData.A.y, UserData.B.x, UserData.B.y fields.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.
global spikeClient; %#ok<GVMIS> 
set(hBarA,'XData',spikeClient.UserData.A.x, 'YData', spikeClient.UserData.A.y);
set(hBarB,'XData',spikeClient.UserData.B.x, 'YData', spikeClient.UserData.B.y);
drawnow();

end