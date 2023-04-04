function handle_tmsi_acq_stream(src, evt)
%HANDLE_TMSI_ACQ_STREAM  Similar to that implemented in SAGA_GUI for enum.TMSiPacketMode.StreamMode case.

message = src.readline();
in = jsondecode(message);

if src.UserData.verbose
    evt.AbsoluteTime.Format = 'uuuu-MM-dd_hh:mm:ss.SSS';
    src.UserData.logger.info(sprintf('%s :: %s :: Sent', string(evt.AbsoluteTime), in.type));
end

switch in.type
    case 'stream.tmsi'
        src.UserData.channels.iTrig = in.channels==100;
        src.UserData.channels.iCount = in.channels==101;
        y = reshape(in.data, src.UserData.n.channels, []);
        trigdata = y(src.UserData.channels.iTrig,:);
        trigmask = bitand(trigdata, 2^src.UserData.udp.UserData.trigger_bit) == 0;
        y(1:(end-2), trigmask) = 0;
        % Save the data temporarily, making sure not to save too much of
        % it.
        if size(src.UserData.sample_data, 2) < src.UserData.n.max_samples
            src.UserData.sample_data = horzcat(src.UserData.sample_data, y);
        elseif size(y, 2) > size(src.UserData.sample_data, 2)
            src.UserData.sample_data = y;
        else
            src.UserData.sample_data = circshift(src.UserData.sample_data, -size(y,2), 2);
            src.UserData.sample_data(:, (end-size(y,2)+1):end) = y;
        end
        % Deal with PCA stuff.
        if ~src.UserData.flags.pcs_ready
            if size(src.UserData.sample_data, 2) >= src.UserData.n.min_pc_samples
                [src.UserData.pca.coeff, ~, ~, ~, src.UserData.pca.explained, src.UserData.pca.mu] = pca(src.UserData.sample_data(1:64, :)' + randn(size(src.UserData.sample_data, 2), 64).*0.25, 'Algorithm', 'svd', 'Economy', true, 'NumComponents', 7);
                for ii = 1:numel(src.UserData.h_ax_pca)
                    title(src.UserData.h_ax_pca(ii), sprintf('PC-%02d (%3.2f%%)', ii+2, src.UserData.pca.explained(ii+2)));
                end
                src.UserData.flags.pcs_ready = true;
            end
        elseif src.UserData.flags.pcs_synchronized
            proj = (y(1:64, :)'-src.UserData.pca.mu) * src.UserData.pca.coeff;
            if size(src.UserData.pca.proj, 1) < src.UserData.n.max_samples
                src.UserData.pca.proj = vertcat(src.UserData.pca.proj, proj);
            elseif size(proj, 1) > size(src.UserData.pca.proj,1)
                src.UserData.pca.proj = proj;
            else
                src.UserData.pca.proj = circshift(src.UserData.pca.proj, -size(proj,1), 1);
                src.UserData.pca.proj((end-size(proj,1)+1):end, :) = proj;
            end
        end

        % Deal with the STA stuff.
        i_stim = find(diff(trigmask) > 0);
        ii = 1;
        n_pre = src.UserData.udp.UserData.n_pre;
        n_post = src.UserData.udp.UserData.n_post;

        % (Debounce stims)
        while ii < numel(i_stim)
            if i_stim(ii+1) - i_stim(ii) < n_post
                i_stim(ii+1) = [];
            else
                ii = ii + 1;
            end
        end
        n_sta = numel(i_stim);
        
        if n_sta > 0
            vec = -n_pre : n_post;
            assign_vec = 1:(n_pre + n_post + 1);
            sta_snippet_data = zeros(n_sta, (n_pre + n_post + 1), 68);
            for ii = 1:n_sta
                vec_snippet = i_stim(ii) + vec;
                vec_mask = (vec_snippet > 0) & (vec_snippet < numel(trigmask));
                sta_snippet_data(ii, assign_vec(vec_mask), :) = reshape(y(1:68, vec_snippet(vec_mask))', 1, sum(vec_mask), 68);
            end
            src.UserData.udp.UserData.data = circshift(src.UserData.udp.UserData.data, 1, n_sta);
            src.UserData.udp.UserData.data(1:n_sta,:, :) = sta_snippet_data;
            src.UserData.udp.UserData.n = min(src.UserData.udp.UserData.n + n_sta, src.UserData.udp.UserData.n_max);
        end
    case 'name.tmsi'
        name =  sprintf('%s: %04d-%02d-%02d (%s::%d)', in.subject, in.year, in.month, in.day, src.UserData.tag, in.block);
        title(src.UserData.L, name, 'FontName','Tahoma');
end
if src.UserData.verbose
    src.UserData.logger.info(sprintf('%s :: %s :: Handled', string(datetime('now','Format','uuuu-MM-dd_hh:mm:ss.SSS')), in.type));
end

end