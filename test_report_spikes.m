function test_report_spikes(src, ~)
data = jsondecode(src.readline);
% disp(data);
% for ii = 1:numel(data.n)
%     if data.n(ii) > 0
%         fprintf(1,'%s::Channel-%d=%d spikes\n', evt.AbsoluteTime, ii, data.n(ii));
%     end
% end
src.UserData.UserData.(data.SAGA).x = (1:numel(data.rate))';
src.UserData.UserData.(data.SAGA).y = data.rate;
% refreshdata;
end