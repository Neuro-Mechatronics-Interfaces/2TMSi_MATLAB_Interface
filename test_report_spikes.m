function test_report_spikes(src, ~)
data = jsondecode(src.readline);
% disp(data);
% for ii = 1:numel(data.n)
%     if data.n(ii) > 0
%         fprintf(1,'%s::Channel-%d=%d spikes\n', evt.AbsoluteTime, ii, data.n(ii));
%     end
% end
src.UserData.Timer.UserData.(data.SAGA).x = (1:numel(data.rate))';
tmpRate = data.rate';
src.UserData.Timer.UserData.(data.SAGA).y = (tmpRate(:))';
nTotalUpdate = numel(src.UserData.Timer.UserData.A.y) + numel(src.UserData.Timer.UserData.B.y);
src.UserData.Timer.UserData.CurrentReportedPose = TMSiAccPose.(data.pose);
if nTotalUpdate ~= src.UserData.Timer.UserData.NTotal
    src.UserData.Timer.UserData.NTotal = nTotalUpdate;
    src.UserData.Timer.UserData.Zprev = zeros(nTotalUpdate, 1);
    src.UserData.Timer.UserData.Data = struct( ...
        'Y', zeros(0,1), ...
        'X', zeros(0, nTotalUpdate), ...
        'Pose', TMSiAccPose(zeros(0,1)));
end
% refreshdata;
end