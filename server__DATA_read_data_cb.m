function server__DATA_read_data_cb(src, evt)
%SERVER__DATA_READ_DATA_CB  Read callback for DATA server.

n_data = src.UserData.n.samples * src.UserData.n.channels;
src.UserData.data = reshape(read(src, n_data, "double"), ...
    src.UserData.n.samples, src.UserData.n.channels);
src.UserData.lab.String = sprintf(src.UserData.lab_expr, ...
    string(evt.AbsoluteTime));
sync_data = ~(bitand(src.UserData.data(:, src.UserData.sync.ch), 2^src.UserData.sync.bit) == 2^src.UserData.sync.bit);
if sum(sync_data) == 0
    return;
end
onset = find(sync_data, 1, 'first');
e = src.UserData.rms.epoch;
if (onset + e(2)) > size(src.UserData.data, 1)
    return;
end

x = src.UserData.data(e(1):e(2), src.UserData.channels.UNI);
q = sqrt(sum(((x - mean(x, 1)).^2), 1)./(e(2) - e(1))); % RMS
q = q + 0.1*randn(size(q)); % For visualizing changes
src.UserData.rms.evoked(:, :, src.UserData.rms.index) = reshape(q, 8, 8);
mu = mean(src.UserData.rms.evoked, 3);
set(src.UserData.contour, 'ZData', mu);
src.UserData.rms.index = rem(src.UserData.rms.index, src.UserData.rms.index_max) + 1;
% fprintf(1, "%s::%s::%d\n", src.UserData.tag, string(evt.AbsoluteTime), ...
%     src.UserData.data(1, 72) - src.UserData.last_set(2));
% src.UserData.last.set = [src.UserData.data(1, 72), src.UserData.data(src.UserData.n.samples, 72)];
% set(src.UserData.line, ...
%     'XData', union(0:src.UserData.n.samples:n, (src.UserData.n.samples+1):src.UserData.n.samples:n:n), ...
%     'YData', [src.UserData.line.YData, yy]);


end