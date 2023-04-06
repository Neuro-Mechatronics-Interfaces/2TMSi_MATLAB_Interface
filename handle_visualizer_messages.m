function handle_visualizer_messages(src, ~)
%HANDLE_VISUALIZER_MESSAGES  Handles the input messages to the STA visualizer, etc.

message = src.readline();
in = jsondecode(message);
switch in.type
    case 'sta.config'
        src.UserData.n_pre = in.n_pre;
        src.UserData.n_post = in.n_post;
        src.UserData.n_max = in.n_max;
        src.UserData.channel = in.channel;
        src.UserData.trigger_bit = in.trigger_bit;
        if in.reset
            src.UserData.data = zeros(in.n_max, in.n_pre + in.n_post + 1, 68);
            src.UserData.n = 0;
            set(src.UserData.subtitle, 'String', '(N = 0)');
            t = ((-in.n_pre : in.n_post)./4).';
            y_mu = zeros(in.n_pre + in.n_post + 1, 1);
            set(src.UserData.h_mean, ...
                'XData', t, ...
                'YData', y_mu);
            set(src.UserData.h_var, ...
                'Faces', [1:(2*numel(t)), 1], ...
                'Vertices', [[t; flipud(t)], [y_mu; y_mu]]);
        else
            t = ((-in.n_pre : in.n_post)./4).';
            y_mu = mean(abs(src.UserData.data(:, :, src.UserData.channel)), 1)';
            set(src.UserData.h_mean, ...
                'XData', t, ...
                'YData', y_mu);
            y_sigma = std(abs(src.UserData.data(:,:,src.UserData.channel)), 1, 1)';
            set(src.UserData.h_var, ...
                'Faces', [1:(2*numel(t)), 1], ...
                'Vertices', [[t; flipud(t)], [y_mu - y_sigma; flipud(y_mu + y_sigma)]]);
        end
        if in.channel > 64
            parsed_channel = sprintf('BIP-%02d', in.channel - 64);
        else
            parsed_channel = sprintf('UNI-%02d', in.channel);
        end
        set(src.UserData.title, 'String', sprintf('Channel: %s', parsed_channel));
    case 'sta.data'
    case 'snippets.config'
        set(src.UserData.uni_snippets, 'RMS_Range', in.rms_range, 'Enable', in.enable, 'TriggerBit', in.trigger_bit);
end

end