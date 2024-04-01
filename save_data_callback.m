function save_data_callback(src, m)
%SAVE_DATA_CALLBACK  Update data in file some number of times.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.


k = src.UserData.CurrentIndex;
m.Y(k,1) = src.UserData.CurrentAssignedPose;
m.X(k,1:src.UserData.NTotal) = [src.UserData.A.y', src.UserData.B.y'];
src.UserData.CurrentIndex = k + 1;

% disp('Tick');
end