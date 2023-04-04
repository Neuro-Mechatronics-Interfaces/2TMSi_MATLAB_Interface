function handle_tmsi_viewer_refresh(src, ~)
%HANDLE_TMSI_VIEWER_REFRESH  Timer callback

y = src.UserData.client.UserData.sample_data;
if isempty(y)
    return;
end
nSamples = size(y,2);
if nSamples < src.UserData.n_samples_refresh
    return;
end
iTrig = src.UserData.client.UserData.channels.iTrig;
iCount = src.UserData.client.UserData.channels.iCount;
counterdata = y(iCount,:) ./ src.UserData.fs;
set(src.UserData.uni_snippets, 'TrigData', y(iTrig,:)', 'YData', y(1:64,:)', 'XData', counterdata');
for ii = 1:numel(src.UserData.h_bip)
    set(src.UserData.h_bip(ii), 'YData', y(64+ii,:), 'XData', 1:nSamples);
end
set(src.UserData.h_trig,'XData', 1:nSamples, 'YData', y(iTrig, :));
set(src.UserData.h_count, 'XData', counterdata, 'YData', y(iCount,:));
if ~isempty(src.UserData.client.UserData.pca.proj)
    for ii = 1:numel(src.UserData.h_pca)
        set(src.UserData.h_pca(ii), 'YData', src.UserData.client.UserData.pca.proj(:, ii+2), 'XData', 1:nSamples);
    end
end

src.UserData.client.UserData.sample_data = [];
if src.UserData.client.UserData.flags.pcs_ready
    src.UserData.client.UserData.pca.proj = [];
    src.UserData.client.UserData.flags.pcs_synchronized = true;
end
trig_buf = src.UserData.client.UserData.udp.UserData;
t = ((-trig_buf.n_pre : trig_buf.n_post) ./ 4)'; % 4 kHz, show in milliseconds
mu = mean(abs(trig_buf.data(:, :, trig_buf.channel)), 1).';
trig_buf.subtitle.String = sprintf('(N = %d)', trig_buf.n);
set(trig_buf.h_mean, 'XData', t, 'YData', mu);
sigma = std(abs(trig_buf.data(:, :, trig_buf.channel)), 1, 1).';
set(trig_buf.h_var, 'Vertices', [[t; flipud(t)], [(mu - sigma); flipud(mu + sigma)]]);

drawnow limitrate;
end