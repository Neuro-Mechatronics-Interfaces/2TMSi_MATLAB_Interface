function test_report_spikes(src, evt)
data = jsondecode(src.readline);
for ii = 1:numel(data.n)
    if data.n(ii) > 0
        fprintf(1,'%s::Channel-%d=%d spikes\n', evt.AbsoluteTime, ii, data.n(ii));
    end
end
src.UserData = data.n;
end