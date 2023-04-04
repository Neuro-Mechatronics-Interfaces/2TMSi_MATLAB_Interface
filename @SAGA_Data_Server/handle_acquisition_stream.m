function handle_acquisition_stream(self, src, ~)
%HANDLE_ACQUISITION_STREAM  Handle incoming streams from acquisition TCP

if ~self.Ready
    return;
end

message = src.readline();
in = jsondecode(message);

switch in.type
    case 'stream.tmsi'
        k = src.UserData.SAGA_Index;
        
        self.trigger_channel(k) = find(in.channels==100,1,'first');
        self.counter_channel(k) = find(in.channels==101,1,'first');
        y = reshape(in.data, 70, []);
        trigdata = y(self.trigger_channel(k),:);
        trigmask = bitand(trigdata, 2^self.sync_bit(k)) == 0;
        y(1:(end-2), trigmask) = 0;
        
        % Deal with the STA stuff.
        i_stim = find(diff(trigmask) > 0);
        ii = 1;
        
        % (Debounce stims)
        while ii < numel(i_stim)
            if i_stim(ii+1) - i_stim(ii) < self.n_post
                i_stim(ii+1) = [];
            else
                ii = ii + 1;
            end
        end
        n_new = numel(i_stim);
        
        if n_new > 0
            vec = -self.n_pre : self.n_post;
            assign_vec = 1:(self.n_pre + self.n_post + 1);
            sta_snippet_data = zeros(68, (self.n_pre + self.n_post + 1), n_new);
            for ii = 1:n_new
                vec_snippet = i_stim(ii) + vec;
                vec_mask = (vec_snippet > 0) & (vec_snippet < numel(trigmask));
                sta_snippet_data(:, assign_vec(vec_mask), ii) = y(1:68, vec_snippet(vec_mask));
            end
            updated_channels = ((k - 1)*68 + 1) : (k*68);
            updated_snippets = (self.n_sta + 1):(self.n_sta + n_new);
            self.sample_data(updated_channels, :, updated_snippets) = sta_snippet_data;
            self.n_sta = self.n_sta + n_new;
        end
    case 'name.tmsi'
        self.subject = in.subject;
        self.year = in.year;
        self.month = in.month;
        self.day = in.day;
        self.block = in.block;
        self.update_experiment_text();
        
end    

end