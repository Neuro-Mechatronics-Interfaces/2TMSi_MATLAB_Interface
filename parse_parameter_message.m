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
    case 'a' % CAR
        param.apply_car = strcmpi(parameter_value, "1");
        fprintf(1,'[TMSi]\t->\t[%s]: Apply CAR = %s\n', parameter_code, parameter_value);
    case 'c' % Length of calibration buffer (samples)
        parameter_command = strsplit(parameter_value, ':');
        new_state = matlab.lang.makeValidName(lower(parameter_command{1}));
        param.calibration_state = new_state;
        if numel(parameter_command) > 1
            param.n_samples_calibration = round(str2double(parameter_command{2}));
        end
        if isfield(param.transform.A, new_state)
            param.n_spike_channels = numel(param.threshold.A.(new_state));
        else
            param = init_new_calibration(param, new_state);
        end
        param.gui.neo.state = new_state;
        fprintf(1,'[TMSi]\t->\t[%s]: Label State:Samples = %s\n', parameter_code, parameter_value);
    case 'e' % nonlinear **E**nergy operator GUI command
        command_chunks = strsplit(parameter_value, ":");
        en = str2double(command_chunks{1})==1;
        if en
            tmp = round(str2double(command_chunks{3}));
            if (tmp <= param.n_spike_channels) && (tmp > 0)
                param.gui.neo.saga = command_chunks{2};
                param.gui.neo.channel = tmp;
                param.gui.neo.enable = true;
                param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
            else
                warning("Received command: %s\n\t->\tNEO Channel must be in the range [1, %d]", ...
                    parameter_data, param.n_spike_channels);
            end 
        else
            param.gui.neo.enable = false;
            param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
        end
        fprintf(1,'[TMSi]\t->\t[%s]: NEO GUI Channel = %s\n', parameter_code, parameter_value);
    case 'f' % Save Location (folder)
        param.save_location = strrep(parameter_value, '\', '/');
        fprintf(1,'[TMSi]\t->\t[%s]: Save Location = %s\n', parameter_code, parameter_value);
    case 'g' % Number of samples for squiggles and/or NEO figure sweeps
        n_samples = round(str2double(parameter_value));
        param.gui.neo.n_samples = n_samples;
        param.gui.squiggles.n_samples = n_samples;
        param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        fprintf(1,'[TMSi]\t->\t[%s]: GUI Line Samples = %s\n', parameter_code, parameter_value);
    case 'h' % HPF cutoff frequency
        fc = str2double(parameter_value);
        [param.hpf.b, param.hpf.a] = butter(2, fc/(param.sample_rate/2), "high");
        fprintf(1,'[TMSi]\t->\t[%s]: HPF Fc = %s Hz\n', parameter_code, parameter_value);
    case 'l' % Label State
        parameter_command = strsplit(parameter_value, ':');
        new_state = matlab.lang.makeValidName(lower(parameter_command{1}));
        param.label_state = new_state;
        if numel(parameter_command) > 1
            param.n_samples_label = round(str2double(parameter_command{2}));
        end
        param = init_new_label(param, new_state);
        fprintf(1,'[TMSi]\t->\t[%s]: Label State:Samples = %s\n', parameter_code, parameter_value);
    case 'o' % Squiggles offsets
        param.gui.squiggles.offset = str2double(parameter_value);
        fprintf(1,'[TMSi]\t->\t[%s]: Squiggles Line Offset = %s (uV)\n', parameter_code, parameter_value);
    case 'p' % Number of spike channels (rows in transform matrix)
        param.n_spike_channels = round(str2double(parameter_value));
        param = init_new_calibration(param, param.calibration_state);
        fprintf(1,'[TMSi]\t->\t[%s]: Spike Channels = %s\n', parameter_code, parameter_value);
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
                param.gui.squiggles.zi.(saga_tag) = zeros(numel(param.gui.squiggles.channels.(saga_tag)), 2);
            end
            param.gui.squiggles.enable = true;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        else
            param.gui.squiggles.enable = false;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        end
        fprintf(1,'[TMSi]\t->\t[%s]: SQUIGGLES GUI Channels = %s\n', parameter_code, parameter_value);
    case 'x' % Set spike detection/threshold deviations
        param.threshold_deviations = str2double(parameter_value);
        caldata = param.calibration_data.A.(param.calibration_state)';
        if param.apply_car
            caldata = caldata - mean(caldata,2);
        end
        neocaldata = caldata(3:end,:).^2 - caldata(1:(end-2),:).^2; 
        param.threshold.A.(param.calibration_state) = median(abs(neocaldata * param.transform.A.(param.calibration_state)), 1) * param.threshold_deviations;

        caldata = param.calibration_data.B.(param.calibration_state)';
        if param.apply_car
            caldata = caldata - mean(caldata,2);
        end
        neocaldata = caldata(3:end,:).^2 - caldata(1:(end-2),:).^2; 
        param.threshold.B.(param.calibration_state) = median(abs(neocaldata * param.transform.B.(param.calibration_state)), 1) * param.threshold_deviations;

        param.spike_detector = abs(param.threshold_deviations) > eps; % If threshold is zero, then turn off spike detection
        param.gui.neo.enable = param.spike_detector;
        param.gui.neo = init_neo_gui(param.gui.neo, param.threshold.(param.gui.neo.saga).(param.calibration_state)(param.gui.neo.channel));
        fprintf(1,'[TMSi]\t->\t[%s]: Spike Detection Threshold Deviations = %s\n', parameter_code, parameter_value);
    case 'z' % Save Parameters
        param.save_params = strcmpi(parameter_value, "1");
        fprintf(1,'[TMSi]\t->\t[%s]: Save Parameters = %s\n', parameter_code, parameter_value);
    otherwise
        warning("[TMSi]\t->\tUnrecognized parameter code (%s). Value not assigned (%s)", parameter_code, parameter_value);
end

end