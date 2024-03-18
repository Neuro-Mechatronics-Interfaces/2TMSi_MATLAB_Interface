function bar_height_update_callback(src, hBarA, hBarB, hTxt, hTxt2, autoEnc, net, Label, hBarZ)
%BAR_HEIGHT_UPDATE_CALLBACK Update the heights of the bars according to counts in tcpclient UserData.A.x, UserData.A.y, UserData.B.x, UserData.B.y fields.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.

set(hBarA,'XData',src.UserData.A.x, 'YData', src.UserData.A.y);
set(hBarB,'XData',src.UserData.B.x, 'YData', src.UserData.B.y);
if nargin > 3
    set(hTxt, 'String', string(src.UserData.CurrentReportedPose));
end
drawnow();

if nargin > 8
    src.UserData.Zprev = 0.25 .* predict(autoEnc, [src.UserData.A.y; src.UserData.B.y]) + 0.25.*src.UserData.Zprev;
    predicted = net(src.UserData.Zprev);
    [~,idx] = max(predicted);
    set(hTxt2,'String',Label(idx));
    set(hBarZ,'XData',(1:numel(src.UserData.Zprev))', 'YData', src.UserData.Zprev);
end

% k = numel(src.UserData.Data.Y) + 1;
% 
% src.UserData.Data.X(k,:) = [src.UserData.A.y, src.UserData.B.y];
% src.UserData.Data.Pose(k) = src.UserData.CurrentAssignedPose;

% disp('Tick');
end