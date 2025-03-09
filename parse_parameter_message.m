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
            switch virtual_ref_code
                case {1,2} % CAR: no spatial ref
                    param.ref_projection.A = eye(64);
                    param.ref_projection.B = eye(64);
                case 3 % Discrete Laplacian: Standard Grids
                    param.ref_projection.A = generateLaplacianMatrix([8,8]);
                    param.ref_projection.B = generateLaplacianMatrix([8,8]);
                case 4 % Discrete Laplacian: Textiles
                    param.ref_projection.A = generateLaplacianMatrix([8,4; 8,4]);
                    param.ref_projection.B = generateLaplacianMatrix([8,4; 8,4]); 
                case 5 % Single Differential Rows: Standard Grids
                    param.ref_projection.A = generateSingleDifferentialRows([8,8]);
                    param.ref_projection.B = generateSingleDifferentialRows([8,8]);
                case 6 % Single Differential Rows: Textiles
                    param.ref_projection.A = generateSingleDifferentialRows([8,4; 8,4]);
                    param.ref_projection.B = generateSingleDifferentialRows([8,4; 8,4]); 
                case 7 % Single Differential Cols: Standard Grids
                    param.ref_projection.A = generateSingleDifferentialColumns([8,8]);
                    param.ref_projection.B = generateSingleDifferentialColumns([8,8]);
                case 8 % Single Differential Cols: Textiles
                    param.ref_projection.A = generateSingleDifferentialColumns([8,4; 8,4]);
                    param.ref_projection.B = generateSingleDifferentialColumns([8,4; 8,4]); 
                otherwise
                    fprintf(1,'[TMSi]\t->\t[%s]: Unhandled filter code. Actually filtering is OFF.\n', virtual_ref_code);
            end
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
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                'Topoplot', param.topoplot, ...
                'AuxTarget', param.aux_target, ...
                'AuxSamples', param.aux_samples, ...
                'AuxSAGA', param.aux_saga, ...
                'AuxChannel', param.aux_channel);
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
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                'Topoplot', param.topoplot, ...
                'AuxTarget', param.aux_target, ...
                'AuxSamples', param.aux_samples, ...
                'AuxSAGA', param.aux_saga, ...
                'AuxChannel', param.aux_channel);
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
    case 'n' % Split coefficients for both SAGAs
        command_chunks = strsplit(parameter_value,':');
        hpf_A = str2double(command_chunks{1});
        lpf_A = str2double(command_chunks{2});
        hpf_B = str2double(command_chunks{3});
        lpf_B = str2double(command_chunks{4});
        [param.lpf.A.b, param.lpf.B.a] = butter(3, hpf_A/(param.sample_rate/2), "high");
        [param.hpf.A.b, param.hpf.A.a] = butter(3, lpf_A/(param.sample_rate/2), "high");
        [param.lpf.B.b, param.lpf.B.a] = butter(3, hpf_B/(param.sample_rate/2), "high");
        [param.hpf.B.b, param.hpf.B.a] = butter(3, lpf_B/(param.sample_rate/2), "high");
        fprintf(1,'[TMSi]\t->\t[%s]: SAGA-A Fc: [%.2f - %.2f] Hz   |   SAGA-B Fc: [%.2f - %.2f] Hz\n', parameter_code, hpf_A, lpf_A, hpf_B, lpf_B);
    case 'o' % Squiggles offsets
        param.gui.squiggles.offset = str2double(parameter_value);
        param.gui.squiggles.enable = true;
        if ~isempty(param.gui.squiggles.fig)
            delete(param.gui.squiggles.fig);
            param.gui.squiggles.fig = [];
        end
        param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                'Topoplot', param.topoplot, ...
                'AuxTarget', param.aux_target, ...
                'AuxSamples', param.aux_samples, ...
                'AuxSAGA', param.aux_saga, ...
                'AuxChannel', param.aux_channel);
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
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                'Topoplot', param.topoplot, ...
                'AuxTarget', param.aux_target, ...
                'AuxSamples', param.aux_samples, ...
                'AuxSAGA', param.aux_saga, ...
                'AuxChannel', param.aux_channel);
        else
            param.gui.squiggles.enable = false;
            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                'Topoplot', param.topoplot, ...
                'AuxTarget', param.aux_target, ...
                'AuxSamples', param.aux_samples, ...
                'AuxSAGA', param.aux_saga, ...
                'AuxChannel', param.aux_channel);
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
    case 's' % Sets the channel for LSL FORCE outlet selected SAGA and channel index
        command_chunks = strsplit(parameter_value, ':');
        if numel(command_chunks)~=2
            fprintf(1,'[TMSi]\t->\t[%s]: Error setting LSL FORCE from received code (should be format of "<SAGA>:<1-indexed CHANNEL>"):  %s\n', parameter_code, parameter_value);
            return;
        end
        param.force.SAGA = command_chunks{1};
        param.force.Channel = str2double(command_chunks{2});
        fprintf(1,'[TMSi]\t->\t[%s]: Updated LSL FORCE SAGA and Channel = %s\n', parameter_code, parameter_value);
    case 't' % JSON message
        msg = strjoin(parameter_syntax(2:end),'.');
        data = jsondecode(msg);
        switch string(data.name)
            case "debug"
                fprintf(1,'[TMSi]\t->\t[%s]: Handled JSON DEBUG message = %s\n', parameter_code, data.value);
            case "get"
                switch string(data.value)
                    case "get_aux_offset"
                        if ~isfield(data,'address')
                            fprintf(1,'[TMSi]\t->\t[%s]: Missing "address" field in "get" command for get_aux_offset! Request not updated. %s\n', parameter_code, msg);
                            return;
                        end
                        if ~isfield(data,'port')
                            fprintf(1,'[TMSi]\t->\t[%s]: Missing "port" field in "get" command for get_aux_offset! Request not updated. %s\n', parameter_code, msg);
                            return;
                        end
                        param.send_aux_offset = true;
                        param.aux_return_address = data.address;
                        param.aux_return_port = data.port;
                        fprintf(1,'[TMSi]\t->\t[%s]: Handled "get" command for get_aux_offset: %s\n', parameter_code, msg);
                    case "get_aux_scale"
                        if ~isfield(data,'address')
                            fprintf(1,'[TMSi]\t->\t[%s]: Missing "address" field in "get" command for get_aux_scale! Request not updated. %s\n', parameter_code, msg);
                            return;
                        end
                        if ~isfield(data,'port')
                            fprintf(1,'[TMSi]\t->\t[%s]: Missing "port" field in "get" command for get_aux_scale! Request not updated. %s\n', parameter_code,msg);
                            return;
                        end
                        param.send_aux_scale = true;
                        param.aux_return_address = data.address;
                        param.aux_return_port = data.port;
                        fprintf(1,'[TMSi]\t->\t[%s]: Handled "get" command for get_aux_scale: %s\n', parameter_code, msg);
                    otherwise
                        fprintf(1,'[TMSi]\t->\t[%s]: UNHANDLED "get" command: %s\n', parameter_code, data.value);
                end
            otherwise
                param.(data.name) = data.value;
                if isfield(data,'extra')
                    switch string(data.extra)
                        case "convert"
                            param.(data.name) = round(param.sample_rate * data.value);
                            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                                'Topoplot', param.topoplot, ...
                                'AuxTarget', param.aux_target, ...
                                'AuxSamples', param.aux_samples, ...
                                'AuxSAGA', param.aux_saga, ...
                                'AuxChannel', param.aux_channel);
                            fprintf(1,'[TMSi]\t->\t[%s]: Handled "extra" command: %s\n', parameter_code, data.extra);
                        case "refresh"
                            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                                'Topoplot', param.topoplot, ...
                                'AuxTarget', param.aux_target, ...
                                'AuxSamples', param.aux_samples, ...
                                'AuxSAGA', param.aux_saga, ...
                                'AuxChannel', param.aux_channel);
                            fprintf(1,'[TMSi]\t->\t[%s]: Handled "extra" command: %s\n', parameter_code, data.extra);
                        case "target"
                            xt = round(param.aux_knots(1,:).*param.sample_rate);
                            xt = max(xt,ones(size(xt)));
                            yt = param.aux_knots(2,:);
                            param.aux_target = zeros(1,xt(end));
                            k = 0;
                            ki = 1;
                            yi = 0;
                            while k < numel(xt)
                                vec = ki:xt(k+1);
                                param.aux_target(vec) = linspace(yi,yt(k+1),numel(vec));
                                k = k + 1;
                                ki = xt(k)+1;
                                yi = yt(k);
                            end
                            param.gui.squiggles = init_squiggles_gui(param.gui.squiggles, ...
                                'Topoplot', param.topoplot, ...
                                'AuxTarget', param.aux_target, ...
                                'AuxSamples', param.aux_samples, ...
                                'AuxSAGA', param.aux_saga, ...
                                'AuxChannel', param.aux_channel);
                            fprintf(1,'[TMSi]\t->\t[%s]: Handled "extra" command: %s\n', parameter_code, data.extra);
                        otherwise
                            fprintf(1,'[TMSi]\t->\t[%s]: UNHANDLED "extra" command: %s\n', parameter_code, data.extra);
                    end
                end
        end
        fprintf(1,'[TMSi]\t->\t[%s]: Handled JSON message = %s\n', parameter_code, msg);
    case 'v' % Loop debounce iterations
        param.trig_out_debounce_iterations = str2double(parameter_value);
        fprintf(1,'[TMSi]\t->\t[%s]: Loop Debounce Iterations = %s\n', parameter_code, parameter_value);
    case 'w' % Toggle squiggles mode
        command_chunks = strsplit(parameter_value,':');
        if numel(command_chunks) > 1
            saga = upper(command_chunks{1});
            val = ~logical(str2double(parameter_value));
            param.gui.squiggles.hpf_mode.(saga) = val;
            if val
                param.i_all.(saga) = param.i_all.(sprintf('%so',saga));
                fprintf(1,'[TMSi]\t->\t[%s]: SAGA-%s->HPF Mode Squiggles\n', parameter_code, upper(command_chunks{1}));
            else
                param.i_all.(saga) = 1:64;
                fprintf(1,'[TMSi]\t->\t[%s]: SAGA-%s->BPF Mode Squiggles\n', parameter_code, upper(command_chunks{1}));
            end
        else
            param.gui.squiggles.hpf_mode = ~logical(str2double(parameter_value));
            if param.gui.squiggles.hpf_mode
                fprintf(1,'[TMSi]\t->\t[%s]: Both SAGA->HPF Mode Squiggles\n', parameter_code);
            else
                fprintf(1,'[TMSi]\t->\t[%s]: Both SAGA->Envelope Mode Squiggles\n', parameter_code);
            end
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