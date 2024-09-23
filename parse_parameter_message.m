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
        virtual_ref_code = str2double(command_chunks{1});
        if virtual_ref_code < 0
            param.enable_filters = false;
            fprintf(1,'[TMSi]\t->\t[%s]: Filtering OFF.\n', parameter_code);
        else
            param.enable_filters = true;
            param.virtual_ref_mode = virtual_ref_code;
            fprintf(1,'[TMSi]\t->\t[%s]: Filtering ON. Virtual Reference Mode = %s\n', parameter_code, parameter_value);
        end
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
    case 'c' % Set the new bit mask for left/right mouse-click triggers
        command_chunks = strsplit(parameter_value, ',');
        click_code = {'Left', 'Right'};
        for iChunk = 1:numel(command_chunks)
            parameter_value_numeric = round(str2double(command_chunks{iChunk}));
            if parameter_value_numeric < 0
                fprintf(1,'[TMSi]\t->\t[%s]: %s-MOUSE BIT DISABLED\n', parameter_code, upper(click_code{iChunk}));
                param.trig_out_en(iChunk) = false;
                return;
            end
            if parameter_value_numeric > 15
                fprintf(1,'[TMSi]\t->\t[%s]: DID NOT UPDATE %s MOUSE TRIGGER BIT (must be <= 15; received value: %s)\n', parameter_code, upper(click_code{iChunk}), parameter_value);
                return;
            end
            param.trig_out_mask(iChunk) = 2^parameter_value_numeric;
            param.trig_out_en(iChunk) = true;
            fprintf(1,'[TMSi]\t->\t[%s]: Updated %s-Mouse-Click Trigger Bit to BIT-%d\n', parameter_code, click_code{iChunk}, parameter_value_numeric);
        end
    case 'd' % Load classifier file
        command_chunks = strsplit(parameter_value, '|');
        if isscalar(command_chunks)
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
    case 'f' % Save Location (folder)
        param.save_location = strrep(parameter_value, '\', '/');
        fprintf(1,'[TMSi]\t->\t[%s]: Save Location = %s\n', parameter_code, parameter_value);
    case 'g' % Number of samples for squiggles and/or NEO figure sweeps
        n_samples = round(str2double(parameter_value));
        % param.gui.sch.n_samples = n_samples;
        param.gui.squiggles.n_samples = n_samples;
        % param.gui.sch = init_single_ch_gui(param.gui.sch, param.threshold.(param.gui.sch.saga).(param.calibration_state)(param.gui.sch.channel));
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        fprintf(1,'[TMSi]\t->\t[%s]: GUI Line Samples = %s\n', parameter_code, parameter_value);
    case 'h' % HPF cutoff frequency
        fc = str2double(parameter_value);
        [param.hpf.b, param.hpf.a] = butter(2, fc/(param.sample_rate/2), "high");
        param.zi.hpf = struct('A',size(param.zi.hpf.A), 'B', size(param.zi.hpf.B));
        fprintf(1,'[TMSi]\t->\t[%s]: HPF Fc = %s Hz\n', parameter_code, parameter_value);
    case 'i' % Interpolate grid
        param.interpolate_grid = ~strcmpi(parameter_value,'0');
        if param.interpolate_grid
            fprintf(1,'[TMSi]\t->\t[%s]: Interpolate Grid = ON\n', parameter_code);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Interpolate Grid = OFF\n', parameter_code);
        end
    case 'j' % ENVELOPE cutoff frequency
        fc = str2double(parameter_value)/1000;
        [param.env.b, param.env.a] = butter(2, fc/(param.sample_rate/2), "low");
        param.zi.env = struct('A',size(param.zi.env.A), 'B', size(param.zi.env.B));
        fprintf(1,'[TMSi]\t->\t[%s]: HPF Fc = %s Hz\n', parameter_code, parameter_value);
    case 'k' % Any "model" upload
        [p,f,~] = fileparts(parameter_value);
        fname = fullfile(p,sprintf('%s.mat', f));
        if exist(fname, 'file')==0
            fprintf(1,'[TMSi]\t->\t[%s]: No such file: %s\n', parameter_code, parameter_value);
            return;
        end
        in = load(fname);
        if isfield(in,'mdl')
            param.envelope_classifier = in.mdl;
            fprintf(1,'[TMSi]\t->\t[%s]: Updloaded new envelope classifier model.\n', parameter_code);
        end
        if isfield(in, 'extFactor')
            param.dsp_extension_factor = in.extFactor;
            param.prev_data = struct('A', zeros(in.extFactor,64), 'B', zeros(in.extFactor,64));
            fprintf(1,'[TMSi]\t->\t[%s]: Parsed extension factor: %d\n', parameter_code, in.extFactor);
        end
        has_new_squiggles = false;
        if isfield(in,'A')
            sz = (size(in.A.P,1)/64);
            if sz == param.dsp_extension_factor
                param.P.A = in.A;
                param.P.A.Wz = construct_uni_whitening_window(param.dsp_extension_factor, param.P.A.windowingVector);
                param.gui.squiggles.whiten.A = true;
                fprintf(1,'[TMSi]\t->\t[%s]: Updloaded new pseudo-inverse matrix for SAGA-A.\n', parameter_code);
            else
                param.P.A = [];
                param.gui.squiggles.whiten.A = false;
                fprintf(1,'[TMSi]\t->\t[%s]: Detected new pseudo-inverse matrix for SAGA-A, but DID NOT USE (extension mismatch: found extension factor = %d but should be %d!)\n', parameter_code, sz, param.dsp_extension_factor);
            end
            has_new_squiggles = true;
        end
        if isfield(in,'B')
            sz = (size(in.B.P,1)/64);
            if sz == param.dsp_extension_factor
                param.P.B = in.B;
                param.P.B.Wz = construct_uni_whitening_window(param.dsp_extension_factor, param.P.B.windowingVector);
                param.gui.squiggles.whiten.B = true;
                fprintf(1,'[TMSi]\t->\t[%s]: Updloaded new pseudo-inverse matrix for SAGA-B.\n', parameter_code);
            else
                param.P.B = [];
                param.gui.squiggles.whiten.B = false;
                fprintf(1,'[TMSi]\t->\t[%s]: Detected new pseudo-inverse matrix for SAGA-B, but DID NOT USE (extension mismatch: found extension factor = %d but should be %d!)\n', parameter_code, sz, param.dsp_extension_factor);
            end
            has_new_squiggles = true;
        end
        if has_new_squiggles
            fprintf(1,'[TMSi]\t->\t[%s]: Entered whitening-mode!\n',parameter_code);
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles);
        elseif ~param.gui.squiggles.whiten.A && ~param.gui.squiggles.whiten.B
            fprintf(1,'[TMSi]\t->\t[%s]: Not using whitening-mode!\n', parameter_code);
        end
        fprintf(1,'[TMSi]\t->\t[%s]: Updated using file = %s\n', parameter_code, parameter_value);
    case 'l' % Set Left or Right trigger channel for parsing
        command_chunks = strsplit(parameter_value,':');
        if numel(command_chunks) < 2
            fprintf(1,'[TMSi]\t->\t[%s]: Command must be in syntax `l.<L or R>:<channel index>` where channel index ranges between 1 and %d (number of channels on SAGA-A).\n', parameter_code, param.n_channels.A);
            return;
        end
        value_numeric = round(str2double(command_chunks{2}));
        if (value_numeric < 1) || (value_numeric > param.n_channels.A)
            fprintf(1,'[TMSi]\t->\t[%s]: Value must be greater than or equal to 1 and less than or equal to number of channels on SAGA-A (%d).\n', parameter_code, param.n_channels.A);
            return;
        end
        if strcmpi(command_chunks{1},'L')
            param.trig_out_chan(1) = value_numeric;
        else
            param.trig_out_chan(2) = value_numeric;
        end
        fprintf(1,'[TMSi]\t->\t[%s]: %s-Channel = %d\n', parameter_code, upper(command_chunks{1}), value_numeric);
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
    case 'p' % Parse from bits?
        command_chunks = strsplit(parameter_value,':');
        param.parse_from_bits = strcmpi(command_chunks{1}, '1');
        if numel(command_chunks) > 1
            param.trig_out_sliding_threshold(1,1) = str2double(command_chunks{2})/100;
        end
        if numel(command_chunks) > 2
            param.trig_out_threshold(1,1) = str2double(command_chunks{3})/100;
        end
        if numel(command_chunks) > 3
            param.trig_out_threshold(1,2) = str2double(command_chunks{4})/100;
        end
        if numel(command_chunks) > 4
            param.trig_out_sliding_threshold(1,2) = str2double(command_chunks{5})/100;
        end
        if numel(command_chunks) > 5
            param.trig_out_threshold(2,1) = str2double(command_chunks{6})/100;
        end
        if numel(command_chunks) > 6
            param.trig_out_threshold(2,2) = str2double(command_chunks{7})/100;
        end
        if param.parse_from_bits
            fprintf(1,'[TMSi]\t->\t[%s]: Using BITMASK Parsing for TRIGGERS\n', parameter_code);
        else
            fprintf(1,'[TMSi]\t->\t[%s]: Using CHANNEL-THRESHOLDING Parsing for TRIGGERS\n', parameter_code);
        end
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
    case 's' % Assign covariance matrix
        
    case 'v' % Loop debounce iterations
        param.trig_out_debounce_iterations = str2double(parameter_value);
        fprintf(1,'[TMSi]\t->\t[%s]: Loop Debounce Iterations = %s\n', parameter_code, parameter_value);
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
    case 'y' % Change state of websocket for triggers
        command_chunks = strsplit(parameter_value, ':');
        new_enable = strcmpi(command_chunks{1},'1');
        new_emulation_mode = strcmpi(command_chunks{2},'1');
        if (new_enable ~= param.enable_trigger_controller) || (new_emulation_mode ~= param.emulate_mouse) 
            param.enable_trigger_controller = new_enable;
            param.emulate_mouse = new_emulation_mode;
            param = setup_or_teardown_triggers_socket_connection(param);
            fprintf(1,'[TMSi\t->\t[%s]: Updated Triggers Socket connection state. (%s)\n', parameter_code, parameter_value);
        else
            fprintf(1,'[TMSi\t->\t[%s]: Triggers Socket connection state UNCHANGED! (No new parameter values: %s)\n', parameter_code, parameter_value);
        end
    case 'z' % Save Parameters
        param.save_params = strcmpi(parameter_value, "1");
        fprintf(1,'[TMSi]\t->\t[%s]: Save Parameters = %s\n', parameter_code, parameter_value);
    otherwise
        warning("[TMSi]\t->\tUnrecognized parameter code (%s). Value not assigned (%s)", parameter_code, parameter_value);
end

end