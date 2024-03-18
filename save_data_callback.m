function save_data_callback(src, m)
%SAVE_DATA_CALLBACK  Update data in file some number of times.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.


k = size(m.Y,1) + 1;
m.Y(k,1) = src.UserData.CurrentAssignedPose;
m.X(k,1:src.UserData.NTotal) = [src.UserData.A.y', src.UserData.B.y'];
m.Pose(k,1) = int32(src.UserData.CurrentReportedPose);

% disp('Tick');
end