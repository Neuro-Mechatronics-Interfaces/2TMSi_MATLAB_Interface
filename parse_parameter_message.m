function param = parse_parameter_message(parameter_data, param)
%PARSE_PARAMETER_MESSAGE  Parser for parameter messages to acquisition state loop.
arguments
    parameter_data
    param
end

fprintf(1,'[TMSi]\t->\tParameter: %s\n',parameter_data);
parameter_syntax = strsplit(parameter_data, '.');
parameter_code = lower(parameter_syntax{1});
parameter_value = parameter_syntax{2};
switch parameter_code
    case 'n' % Number of Buffer Samples
        param.n_recording_buffer_samples = str2double(parameter_value);
        n_sec = floor(param.n_recording_buffer_samples / device(1).sample_rate);
        if n_sec < 60
            fprintf(1,'[TMSi]\t->\t[n]: Set for %d-second recordings.\n', floor(n_sec));
        else
            fprintf(1,'[TMSi]\t->\t[n]: Set for %d-minute recordings.\n', floor(n_sec/60));
        end
    case 't' % Give time in seconds (Buffer Samples)
        n_samples = round(str2double(parameter_value) * device(1).sample_rate);
        param.n_recording_buffer_samples = 2^nextpow2(n_samples);
        n_sec = floor(param.n_recording_buffer_samples / device(1).sample_rate);
        if n_sec < 60
            fprintf(1,'[TMSi]\t->\t[n]: Set for %d-second recordings.\n', floor(n_sec));
        else
            fprintf(1,'[TMSi]\t->\t[n]: Set for %d-minute recordings.\n', floor(n_sec/60));
        end
    case 'f' % Save Location
        param.save_location = strrep(parameter_value, '\', '/');
        fprintf(1,'[TMSi]\t->\t[n]: Save Location = %s\n', parameter_value);
    case 's' % Label State
        new_state = lower(parameter_value);
        param.label_state = new_state;
        if isfield(param.transform.A, new_state)
            param.n_spike_channels = numel(param.threshold.A);
        else
            param = init_new_calibration(param, new_state);
        end
        fprintf(1,'[TMSi]\t->\t[n]: Label State = %s\n', parameter_value);
    case 'c' % Length of calibration buffer (samples)
        param.n_samples_calibration = round(str2double(parameter_value));
        param = init_new_calibration(param, param.label_state);
        fprintf(1,'[TMSi]\t->\t[n]: Calibration Buffer Length = %s\n', parameter_value);
    case 'p' % Number of spike channels (rows in transform matrix)
        param.n_spike_channels = round(str2double(parameter_value));
        param = init_new_calibration(param, param.label_state);
        fprintf(1,'[TMSi]\t->\t[n]: Spike Channels = %s\n', parameter_value);
    case 'q' % s**Q**uiggles GUI command
        command_chunks = strsplit(parameter_value, ":");
        en = str2double(command_chunks{1})==1;
        if en
            for ii = 2:2:numel(command_chunks)
                saga_tag = command_chunks{ii};
                channel_str = strsplit(command_chunks{ii+1}, ',');
                param.gui.squiggles.channels.(saga_tag) = [];
                for ik = 1:numel(channel_str)
                    param.gui.squiggles.channels.(saga_tag) = ...
                        [param.gui.squiggles.channels.(saga_tag), ...
                         round(str2double(channel_str{ik}))];
                end
                param.gui.squiggles.zi.(saga_tag) = zeros(2,numel(param.gui.squiggles.channels.(saga_tag)));
            end
            param.gui.squiggles.enable = true;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        else
            param.gui.squiggles.enable = false;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        end
    case 'e' % nonlinear **E**nergy operator GUI command
        command_chunks = strsplit(parameter_value, ":");
        en = str2double(command_chunks{1})==1;
        if en
            tmp = round(str2double(command_chunks{2}));
            if (tmp <= param.n_spike_channels) && (tmp > 0)
                param.gui.neo.saga = command_chunks{1};
                param.gui.neo.channel = tmp;
                param.gui.neo.enable = true;
                param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.label_state)(param.gui.neo.channel));
            else
                warning("Received command: %s\n\t->\tNEO Channel must be in the range [1, %d]", ...
                    parameter_data, param.n_spike_channels);
            end 
        else
            param.gui.neo.enable = false;
            param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.label_state)(param.gui.neo.channel));
        end
    case 'x' % Set spike detection
        param.spike_detector = strcmpi(parameter_value, "1");
        if ~param.spike_detector
            param.gui.neo.enable = false;
            param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.label_state)(param.gui.neo.channel));
        end
        fprintf(1,'[TMSi]\t->\t[n]: Spike Detection = %s\n', parameter_value);
    case 'h'
        fc = str2double(parameter_value);
        [param.hpf.b, param.hpf.a] = butter(2, fc/(param.sample_rate/2), "high");
        fprintf(1,'[TMSi]\t->\t[n]: HPF Fc = %s Hz\n', parameter_value);
    case 'l' % Number of samples for squiggles and/or NEO figure sweeps
        n_samples = round(str2double(parameter_value));
        param.gui.neo.n_samples = n_samples;
        param.gui.squiggles.n_samples = n_samples;
        param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.label_state)(param.gui.neo.channel));
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        fprintf(1,'[TMSi]\t->\t[n]: GUI Line Samples = %s\n', parameter_value);
    otherwise
        warning("[TMSi]\t->\tUnrecognized parameter code (%s)", parameter_code);
end

end