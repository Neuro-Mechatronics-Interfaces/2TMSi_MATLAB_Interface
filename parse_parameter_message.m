function param = parse_parameter_message(parameter_data, param)
%PARSE_PARAMETER_MESSAGE  Parser for parameter messages to acquisition state loop.
arguments
    parameter_data
    param
end

fprintf(1,'[TMSi]\t->\tParameter: %s\n',parameter_data);
parameter_syntax = strsplit(parameter_data, '.');
parameter_code = lower(parameter_syntax{1});
if numel(parameter_syntax) > 1
    parameter_value = parameter_syntax{2};
end
switch parameter_code
    case 'a' % CAR
        command_chunks = strsplit(parameter_value, ':');
        param.car_mode = str2double(command_chunks{1});
        if numel(command_chunks) > 1
            param.threshold_artifact = str2double(command_chunks{2})/1000;
        end
        fprintf(1,'[TMSi]\t->\t[%s]: CAR Mode = %s\n', parameter_code, parameter_value);
    case 'b' % Name Tag
        command_chunks = strsplit(parameter_value, ':');
        if numel(command_chunks) > 1
            param.name_tag.(command_chunks{1}) = command_chunks{2};
            param.gui.squiggles.tag.(command_chunks{1}) = command_chunks{2};
            param.gui.sch.tag.(command_chunks{1}) = command_chunks{2};
            fprintf(1,'[TMSi]\t->\t[%s]: Tag.%s\n', parameter_code, parameter_value);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Tag **not** updated (invalid value "%s")\n', parameter_code, parameter_value);
        end
    case 'c' % Load calibration file and initialize new calibration for it
        cal_file = strcat(parameter_value, ".mat");
        if exist(cal_file,'file')==0
            fprintf(1,'[TMSi]\t->\t[%s]: Calibration File %s does not exist!\n', parameter_code, cal_file);
            return;
        end
        param.cal.data = load(cal_file);
        param.cal.file = cal_file;
        [~,new_state,~] = fileparts(cal_file);
        new_state = matlab.lang.makeValidName(lower(new_state));
        param.calibration_state = new_state;
        param.n_samples_calibration = param.cal.data.N;
        param = init_new_calibration(param, new_state);
        param.exclude_by_rms = struct('A', false(1,param.n_spike_channels), 'B', false(1, param.n_spike_channels));
        param.gui.sch.state = new_state;
        fprintf(1,'[TMSi]\t->\t[%s]: Initializing new calibration for state: %s\n', parameter_code, new_state);
    case 'd' % Load classifier file
        command_chunks = strsplit(parameter_value, '|');
        if numel(command_chunks) == 1
            parameter_value = sprintf('%s.mat', parameter_value);
            if exist(parameter_value, 'file')==0
                fprintf(1,'[TMSi]\t->\t[%s]: No such file: %s\n', parameter_code, parameter_value);
                return;
            end
            tmp = load(parameter_value);
            if ~isfield(tmp, 'A') || ~isfield(tmp, 'B')
                fprintf(1,'[TMSi]\t->\t[%s]: Invalid file format-missing "A" or "B" struct.\n', parameter_code);
                return;
            end
            if ~isempty(tmp.A)
                if numel(tmp.A.Channels)~=tmp.A.Net.input.size
                    fprintf(1,'[TMSi]\t->\t[%s]: A.Channels does not equal A.Net.input.size.\n', parameter_code);
                    return;
                end
            end
            if ~isempty(tmp.B)
                if numel(tmp.B.Channels)~=tmp.B.Net.input.size
                    fprintf(1,'[TMSi]\t->\t[%s]: B.Channels does not equal B.Net.input.size.\n', parameter_code);
                    return;
                end
            end
            param.classifier = tmp;
        else
            parameter_value = sprintf('%s.mat',command_chunks{2});
            if exist(parameter_value, 'file')==0
                fprintf(1,'[TMSi]\t->\t[%s]: No such file: %s\n', parameter_code, parameter_value);
                return;
            end
            param.classifier.(command_chunks{1}) = load(parameter_value);
        end
        fprintf(1,'[TMSi]\t->\t[%s]: Updated using file = %s\n', parameter_code, parameter_value);
    case 'e' % Single-channel GUI command
        command_chunks = strsplit(parameter_value, ":");
        en = str2double(command_chunks{1})==1;
        if en
            tmp = round(str2double(command_chunks{3}));
            if (tmp <= param.n_spike_channels) && (tmp > 0)
                param.gui.sch.saga = command_chunks{2};
                param.gui.sch.channel = tmp;
                param.gui.sch.enable = true;
                param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
            else
                warning("Received command: %s\n\t->\tNEO Channel must be in the range [1, %d]", ...
                    parameter_data, param.n_spike_channels);
            end 
        else
            param.gui.sch.enable = false;
            param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
        end
        fprintf(1,'[TMSi]\t->\t[%s]: NEO GUI Channel = %s\n', parameter_code, parameter_value);
    case 'f' % Save Location (folder)
        param.save_location = strrep(parameter_value, '\', '/');
        fprintf(1,'[TMSi]\t->\t[%s]: Save Location = %s\n', parameter_code, parameter_value);
    case 'g' % Number of samples for squiggles and/or NEO figure sweeps
        n_samples = round(str2double(parameter_value));
        param.gui.sch.n_samples = n_samples;
        param.gui.squiggles.n_samples = n_samples;
        param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        fprintf(1,'[TMSi]\t->\t[%s]: GUI Line Samples = %s\n', parameter_code, parameter_value);
    case 'h' % HPF cutoff frequency
        fc = str2double(parameter_value);
        [param.hpf.b, param.hpf.a] = butter(2, fc/(param.sample_rate/2), "high");
        fprintf(1,'[TMSi]\t->\t[%s]: HPF Fc = %s Hz\n', parameter_code, parameter_value);
    case 'i' % Interpolate grid
        param.interpolate_grid = ~strcmpi(parameter_value,'0');
        if param.interpolate_grid
            fprintf(1,'[TMSi]\t->\t[%s]: Interpolate Grid = ON\n', parameter_code);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Interpolate Grid = OFF\n', parameter_code);
        end
    case 'j' % Envelope regressor
        command_chunks = strsplit(parameter_value,'|');
        parameter_value = sprintf('%s.mat',command_chunks{2});
        if exist(parameter_value, 'file')==0
            fprintf(1,'[TMSi]\t->\t[%s]: No such file: %s\n', parameter_code, parameter_value);
            return;
        end
        param.envelope_regressor.(command_chunks{1}) = load(parameter_value);
        fprintf(1,'[TMSi]\t->\t[%s]: Updated using file = %s\n', parameter_code, parameter_value);
    case 'k' % Envelope classifier
        [p,f,~] = fileparts(parameter_value);
        fname_env_classifier = fullfile(p,sprintf('%s.mat', f));
        if exist(fname_env_classifier, 'file')==0
            fprintf(1,'[TMSi]\t->\t[%s]: No such file: %s\n', parameter_code, parameter_value);
            return;
        end
        in = load(fname_env_classifier);
        if isfield(in,'mdl')
            param.envelope_classifier = in.mdl;
        else
            fprintf(1,'[TMSi]\t->\t[%s]: File %s exists but has no variable named "mdl" in it.\n', parameter_code, parameter_value);
            return;
        end
        fprintf(1,'[TMSi]\t->\t[%s]: Updated using file = %s\n', parameter_code, parameter_value);
    case 'm' % Re-acquire MVC
        param.acquire_mvc = true;
        tmp = round(str2double(parameter_value));
        if isnumeric(tmp)
            param.acquire_mvc = true;
            param.mvc_samples = tmp;
            param.mvc_data = cell(param.mvc_samples,param.n_device);
            param.n_mvc_acquired = 0;
            fprintf(1,'[TMSi]\t->\t[%s]: Acquiring %d iterations of MVC samples.\n',parameter_code,param.mvc_samples);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Invalid parameter value (should be numeric): %s\n', parameter_code, parameter_value);
        end
    case 'o' % Squiggles offsets
        param.gui.squiggles.offset = str2double(parameter_value);
        param.gui.squiggles.enable = true;
        if ~isempty(param.gui.squiggles.fig)
            delete(param.gui.squiggles.fig);
            param.gui.squiggles.fig = [];
        end
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        fprintf(1,'[TMSi]\t->\t[%s]: Squiggles Line Offset = %s (uV)\n', parameter_code, parameter_value);
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
            if ~isempty(param.gui.squiggles.fig)
                delete(param.gui.squiggles.fig);
                param.gui.squiggles.fig = [];
            end
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        else
            param.gui.squiggles.enable = false;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        end
        fprintf(1,'[TMSi]\t->\t[%s]: SQUIGGLES GUI Channels = %s\n', parameter_code, parameter_value);
    case 'r' % Set rate smoothing
        command_chunks = strsplit(parameter_value, ',');
        n_smooth_kernel = numel(command_chunks);
        param.rate_smoothing_alpha = nan(n_smooth_kernel,1);
        for ii = 1:n_smooth_kernel
            param.rate_smoothing_alpha(ii) = str2double(command_chunks{ii})/1000;
        end
        param.past_rates = struct('A', zeros(numel(param.rate_smoothing_alpha), 64), 'B', zeros(numel(param.rate_smoothing_alpha), 64));
        fprintf(1,['[TMSi]\t->\t[%s]: Rate Smoothing Alpha = ' strjoin(repmat({'%4.3f'}, 1, numel(param.rate_smoothing_alpha)),  ', ') '\n'], parameter_code, param.rate_smoothing_alpha);
    case 'w' % Toggle squiggles mode
        param.gui.squiggles.hpf_mode = ~param.gui.squiggles.hpf_mode;
        if param.gui.squiggles.hpf_mode
            fprintf(1,'[TMSi]\t->\t[%s]: HPF Mode Squiggles\n', parameter_code);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Envelope Mode Squiggles\n', parameter_code);
        end
    case 'x' % Set spike detection/threshold deviations
        param.threshold_deviations = str2double(parameter_value)/1000;
        param.threshold.A.(param.calibration_state) = median(abs(param.calibration_data.A.(param.calibration_state)), 1) * param.threshold_deviations;
        param.threshold.B.(param.calibration_state) = median(abs(param.calibration_data.B.(param.calibration_state)), 1) * param.threshold_deviations;

        param.spike_detector = abs(param.threshold_deviations) > eps; % If threshold is zero, then turn off spike detection
        param.gui.sch.enable = param.spike_detector;
        param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
        fprintf(1,'[TMSi]\t->\t[%s]: Spike Detection Threshold Deviations = %s\n', parameter_code, parameter_value);

    case 'y' % Set upper bound on TRIGGERS axaes
        tmp = str2double(parameter_value);
        if ~isnan(tmp) && (tmp > 0)
            param.gui.squiggles.triggers.y_bound = tmp;
        end
        fprintf(1,'[TMSi]\t->\t[%s]: Triggers Y-Bound = %s\n', parameter_code, parameter_value);

    case 'z' % Save Parameters
        param.save_params = strcmpi(parameter_value, "1");
        fprintf(1,'[TMSi]\t->\t[%s]: Save Parameters = %s\n', parameter_code, parameter_value);
    otherwise
        warning("[TMSi]\t->\tUnrecognized parameter code (%s). Value not assigned (%s)", parameter_code, parameter_value);
end

end