classdef TMSiSAGA_Handler < handle
    %TMSiSAGA_Handler  Handles stuff related to the two TMSi devices
    %
    % Syntax:
    %   obj = TMSiSAGA_Handler()
    
    properties (Access = public)
        pool    parallel.Pool                % Worker for running recording (uses single worker)
    end
    
    properties (GetAccess = public, SetAccess = protected)
        tank    string = strings(1, 1)   % Data tank where files will be saved
        block   string = strings(1, 1)   % Folder in the tank where recordings will be saved
        subject string = strings(1, 1)   % Subject name
        dmeta   struct = struct('A', struct('present', false, 'index', nan, 'block', strings(1, 1)), 'B', struct('present', false, 'index', nan, 'block', strings(1, 1)));
    end
    
    properties (Access = protected)
        run_date                string = strings(1, 1)
        run_time                string = strings(1, 1)
        impedance_file_expr     string = strings(1, 1)
        data_file_expr          string = strings(1, 1)
        start_index             double = -1
        key                     double = nan
        device_config           struct
        channel_config          struct
        trig_channel            double = [nan, nan]
        data_channel            cell = cell(1, 2);
        timer
    end
    
    events
        DiskFileEvent  % Event fired when Poly5 Disk File starts or stops.
        % Has fields: .type = "Start" | "Stop"
        %             .ts  (timestamp)
        %             .key (same as protected class property .key)
        SamplingEvent  % Event fired when data frame fills on a buffer.
    end
    
    methods
        function obj = TMSiSAGA_Handler()
            %TMSISAGA_HANDLER  Wrapper class for two TMSiSAGA 64-bit devices.
            delete(gcp('nocreate'));
            obj.device_config = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
                'Triggers', true, ...
                'BaseSampleRate', 4000, ...
                'RepairLogging', false, ...
                'ImpedanceMode', false, ...
                'AutoReferenceMethod', false, ...
                'ReferenceMethod', 'common',...
                'SyncOutDivider', 4000, ...
                'SyncOutDutyCycle', 500);
            obj.channel_config = struct('uni', 1:64, 'bip', 0, 'dig', 0, 'acc', 0);
            if exist('.messages/broadcast', 'dir')==0
                mkdir('.messages/broadcast');
            else
                TMSiSAGA_Handler.cleanAddress('broadcast');
            end
            if exist('.messages/error', 'dir')==0
                mkdir('.messages/error');
            else
                TMSiSAGA_Handler.cleanAddress('error');
            end
            if exist('.messages/handler', 'dir')==0
                mkdir('.messages/handler');
            else
                TMSiSAGA_Handler.cleanAddress('handler');
            end
            if exist('.messages/status', 'dir')==0
                mkdir('.messages/status');
            else
                TMSiSAGA_Handler.cleanAddress('status');
            end
            if exist('.messages/monitor', 'dir')==0
                mkdir('.messages/monitor');
            else
                TMSiSAGA_Handler.cleanAddress('monitor');
            end
            TMSiSAGA_Handler.putMessage('status', 'idle');
            obj.create_parpool_();
            % Create a timer that checks the 'monitor' location and if
            % anything is there, broadcasts the result as a DiskFileEvent
            obj.timer = timer(...
                'TimerFcn', @(~,evt)obj.handleTimerTick(evt.Data.time), ...
                'StopFcn', @(src, ~)delete(src), ...
                'Period', 0.25, ...
                'ExecutionMode', 'fixedRate');
            start(obj.timer)
        end
        
        function handleTimerTick(obj, t)
            %HANDLETIMERTICK Checks the monitor address periodically. 
            F = dir('.messages/monitor/*');
            F = F(~[F.isdir]);
            for iF = 1:numel(F)
                eventdata = DiskFileEventData(t, F(iF).name);
                notify(obj, "DiskFileEvent", eventdata);
            end
        end
        
        function begin(obj, snA, snB)
            %BEGIN Call this at beginning to connect to devices etc.
            %
            % Syntax:
            %   obj.begin();
            %   obj.begin(snA, snB);
            %
            % Inputs:
            %   snA - Serial-Number of Device A. Default used if not given.
            %   snB - Serial-Number of Device B. Default used if not given.
            if nargin < 3
                snB = 1005210029;
            end
            if nargin < 2
                snA = 1005210028;
            end
            if isempty(char(obj.tank)) || isempty(char(obj.subject))
                error('Please use `setFileInfo` to provide tank and subject information before beginning connection.');
            end
            if ~TMSiSAGA_Handler.getMessage('status', 'idle')
                error('Not in "idle" status. Check initialization and files in .messages.');
            else
                TMSiSAGA_Handler.putMessage('status', 'loading'); 
            end
            if ~obj.pool.Connected
                delete(obj.pool);
                obj.create_parpool_();
            end
            parfeval(obj.pool, @obj.run_and_handle_in_background, 0, snA, snB);
        end
        
        function [file, vec, should_record] = getPoly5Files(obj, device)
            %GETPOLY5FILES  Return Poly5 files, indexing, and if we should record.
            should_record = false;
            vec = 1:2;
            file = cell(1, 2);
            rec_index = struct('A', nan, 'B', nan);
            % In case both devices are present (they should be), we
            % want to be sure that they are in-sync with respect to any
            % parameters key. Therefore, if the other device is
            % present, check that rec_index.B is same as rec_index.A
            % and if not, make sure that the greater of the two indices
            % is used to set the current recording index moving
            % forward.
            if obj.dmeta.A.present && obj.dmeta.B.present
                rec_index.A = device(obj.dmeta.A.index).recording_index;
                rec_index.B = device(obj.dmeta.B.index).recording_index;
                if rec_index.A ~= rec_index.B
                    if rec_index.A > rec_index.B
                        rec_index.B = rec_index.B;
                        device(obj.dmeta.B.index).recording_index = rec_index.B;
                    else
                        rec_index.A = rec_index.B;
                        device(obj.dmeta.A.index).recording_index = rec_index.A;
                    end
                end
            end
            
            % If device A is present, then we should make a poly5 file.
            if obj.dmeta.A.present
                data_file_name = get_new_names(device(obj.dmeta.A.index));
                obj.dmeta.A.block = string(sprintf('%s_%s_%d', obj.block, device(obj.dmeta.A.index).tag, device(obj.dmeta.A.index).recording_index));
                file{obj.dmeta.A.index} = TMSiSAGA.Poly5(fullfile(obj.tank, obj.dmeta.A.block, data_file_name), ...
                    device(obj.dmeta.A.index).sample_rate, device(obj.dmeta.A.index).getActiveChannels());
                should_record = true;
                rec_index.A = device(obj.dmeta.A.index).recording_index;  % This is auto-incremented in `get_new_names` call.
            else
                vec(obj.dmeta.A.index) = nan;
            end
            
            % If device B is present, then we should make a file for that
            % one (too).
            if obj.dmeta.B.present
                data_file_name = get_new_names(device(obj.dmeta.B.index));
                obj.dmeta.B.block = string(sprintf('%s_%s_%d', obj.block, device(obj.dmeta.B.index).tag, device(obj.dmeta.B.index).recording_index));
                file{obj.dmeta.B.index} = TMSiSAGA.Poly5(fullfile(obj.tank, obj.dmeta.B.block, data_file_name), ...
                    device(obj.dmeta.B.index).sample_rate, device(obj.dmeta.B.index).getActiveChannels());
                should_record = true;
                rec_index.B = device(obj.dmeta.B.index).recording_index;  % This is auto-incremented in `get_new_names` call.
            else
                vec(obj.dmeta.B.index) = nan;
            end
            vec(isnan(vec)) = []; % Get rid of any devices that we're not supposed to sample on.
        end
        
        function setFileInfo(obj, subject, tank)
            %SETFILEINFO  Sets the subject and tank as well as other key
            %             protected properties
            obj.subject = subject;
            obj.tank = tank;
            obj.run_date = string(datestr(datetime('now'), 'yyyy_mm_dd'));
            obj.run_time = string(datestr(datetime('now'), 'HH-MM-SS'));
            obj.impedance_file_expr = string(sprintf('%s_%s_%s_%%d - %s_%s.%s', ...
                obj.subject, obj.run_date, '%s', 'impedances', obj.run_time, 'mat'));
            obj.data_file_expr = string(sprintf('%s_%s_%s_%%d - %s_%s.%s', ...
                obj.subject, obj.run_date, '%s', 'data', obj.run_time, 'poly5'));
            obj.start_index = -1;
            tank_info = strsplit(tank, filesep);
            obj.block = string(tank_info{end});
        end
        
        function delete(obj)
            TMSiSAGA_Handler.putMessage('handler', 'pause');
            pause(0.5);
            TMSiSAGA_Handler.putMessage('handler', 'stop'); 
            pause(0.5);
            stop(obj.timer);
            TMSiSAGA_Handler.cleanAddress('handler');
            TMSiSAGA_Handler.cleanAddress('status');
            TMSiSAGA_Handler.cleanAddress('broadcast');
            TMSiSAGA_Handler.cleanAddress('monitor');
            TMSiSAGA_Handler.cleanAddress('error');
        end
        
        
        
        function handleSampleFrame(obj, src, tag)
            %HANDLESAMPLEFRAME  Listener callback for when data buffer fills
            
            data = SampleEventData(src, tag);
            notify(obj, "SamplingEvent", data);
        end
    end
    
    methods (Access = protected)
        function create_parpool_(obj)
            %CREATE_PARPOOL_  Create parallel pool
            
            % Here, just add the path and specify correct files, start the
            % pool, and run it in the background (do this one time).
            toAttach = {'SAGA/Channel.m', 'SAGA/Data.m', 'SAGA/DataRecorderInfo.m', 'SAGA/Device.m', 'SAGA/DeviceLib.m', 'SAGA/DockingStationInfo.m', 'SAGA/HiddenHandle.m', 'SAGA/Library.m', 'SAGA/Poly5.m', 'SAGA/Sensor.m', 'SAGA/SensorChannelDummy.m', 'SAGA/SensorChannelType0.m', 'SAGA/TMSiUtils.m', 'SAGA/TMSiSagaDeviceLib64.m', 'SAGA/TMSiSagaDeviceLib_thunk_pcwin64.dll', 'SAGA/TMSiSagaDeviceLib_thunk_pcwin64.exp', 'SAGA/TMSiSagaDeviceLib_thunk_pcwin64.lib', 'SAGA/TMSiSagaDeviceLib_thunk_pcwin64.obj'};
            if ~contains(strsplit(path, pathsep), 'SAGA')
                addpath('SAGA');
            end
            obj.pool = parpool(1, ...
                'IdleTimeout', 480, ...
                'EnvironmentVariables', {'PATH'}, ...
                'AttachedFiles', toAttach);
        end
        
        function run_and_handle_in_background(obj, snA, snB)
            %RUN_AND_HANDLE_IN_BACKGROUND  Runs on background process with message-passing scheme that lets us still work with frontend.
            lib = Library();
            try
                device = lib.getDevices({'usb'}, {'electrical'});
                connect(device);
                tags = ["A", "B"];
                tagSN = [snA, snB];
                sn = getSerialNumber(device);
                for iTag = 1:numel(tags)
                    if obj.dmeta.(tags(iTag)).present
                        continue;
                    end
                    idx = find(sn == tagSN(iTag));
                    if numel(idx) ~= 1
                        warning('Double-check device serial number for NHP-%s!', tags(iTag));
                        obj.dmeta.(tags(iTag)).present = false;
                    else
                        obj.dmeta.(tags(iTag)).present = true;
                        obj.dmeta.(tags(iTag)).index = idx;
                        device(idx).tag = tags(iTag);
                        device(idx).impedance_file_expr = obj.impedance_file_expr;
                        device(idx).data_file_expr = obj.data_file_expr;
                        getDeviceInfo(device(idx));
                        enableChannels(device(idx), {device(idx).channels});
                        updateDeviceConfig(device(idx));
                        device(idx).setChannelConfig(obj.channel_config);
                        device(idx).recording_index = obj.start_index;
                    end
                end
                for k = 1:2
                    names = getName(device(k).getActiveChannels());
                    obj.trig_channel(k) = find(contains(names, "TRIGGERS"), 1, 'first');
                    obj.data_channel{k} = contains(names, "UNI");
                end
            catch me
                lib.cleanUp();
                fid = fopen('.messages/error/background_handler_init', 'w+');
                db.print_error_message(me, 'handler_init_error', fid);
                fclose(fid);
                TMSiSAGA_Handler.cleanAddress('status');
                TMSiSAGA_Handler.cleanAddress('handler');
                TMSiSAGA_Handler.putMessage('status', 'idle');
                return;
            end
            
            % % % NEXT: RUN "PERMANENT" WHILE LOOP UNTIL SHUTDOWN % % %
            try
                [file, vec, should_record] = obj.getPoly5Files(device);
                if should_record % Allows event listeners to interact with this method           
                    if exist('.messages/status/idle', 'file')~=0
                        delete('.messages/status/idle');
                    end
                    pause(0.025);
                else % Otherwise neither device passed our checks. What happened?
                    fid = fopen('.messages/error/unexpected_state', 'w+');
                    fprintf(fid, 'Neither device was available.\n');
                    fclose(fid);
                    return;
                end
                n = numel(device(vec));
                obj.key = 0;
                buf = DataBuffer([1, 2]);
                lh = [...
                    addlistener(buf(obj.dmeta.A.index), "FrameFilledEvent", @(src, ~)obj.handleSampleFrame(src, "A")), ...
                    addlistener(buf(obj.dmeta.B.index), "FrameFilledEvent", @(src, ~)obj.handleSampleFrame(src, "B"))];
            catch me
                fid = fopen('.messages/error/background_handler_libload', 'w+');
                db.print_error_message(me, 'handler_libload_error', fid);
                fclose(fid);
                lib.cleanUp();
                return;
            end
            
            
            
            try
                if ~TMSiSAGA_Handler.getMessage('status', 'loading')
                    error('Wrong order of operations, check loading...');
                else
                    TMSiSAGA_Handler.putMessage('status', 'waiting'); 
                end
                while ~TMSiSAGA_Handler.getMessage('status', 'begin')
                    pause(0.25);
                end
                
                for k = 1:n
                    start(device(vec(k)));
                    device(vec(k)).is_sampling = true;
                end
                msg = TMSiSAGA_Handler.putMessage('status', 'running');
                TMSiSAGA_Handler.checkRemove('broadcast', 'stopped');
                TMSiSAGA_Handler.checkRemove('broadcast', 'stop');
                
                while ~TMSiSAGA_Handler.getMessage('broadcast', 'stop')
                    if TMSiSAGA_Handler.getMessage('broadcast', 'record')
                        for k = 1:n
                            device(vec(k)).is_recording = true;
                        end
                        delete(msg);
                        msg = TMSiSAGA_Handler.putMessage('handler', 'recording');
                        ts = Microcontroller.convert_to_Mats_ts_format(default.now());
                        start_eventdata = DiskFileEventData(ts, "Start"); % By this point, they should be identical.
                        notify(obj, "DiskFileEvent", start_eventdata);
                        TMSiSAGA_Handler.putMessage('monitor', 'Start');
                    end
                    for k = 1:n  % This is where we are selective about which device to sample
                        try
                            samples = device(vec(k)).sample();
                            buf(vec(k)).append(samples(obj.data_channel{vec(k)}, :));
                        catch me
                            fid = fopen('.messages/error/record', 'w+');
                            db.print_error_message(me, 'recording_error', fid);
                            fclose(fid);
                        end
                        if device(vec(k)).is_recording
                            file{vec(k)}.append(samples);
                        end
                    end
                    
                    % Check if we should stop this recording and go to the
                    % next one.
                    if TMSiSAGA_Handler.getMessage('broadcast', 'pause')
                        for k = 1:n
                            device(vec(k)).is_recording = false;
                            delete(file{vec(k)});
                        end
                        delete(msg);
                        msg = TMSiSAGA_Handler.putMessage('handler', 'sampling'); %#ok<*PROPLC>
                        % Get new Poly5 files. Now we are ready for the
                        % next one.
                        file = obj.getPoly5Files(device);                        
                        ts = Microcontroller.convert_to_Mats_ts_format(default.now());
                        eventdata = DiskFileEventData(ts, "Stop");
                        notify(obj, "DiskFileEvent", eventdata);
                        TMSiSAGA_Handler.putMessage('monitor', 'Stop');
                        obj.key = obj.key + 1;
                    end
                    pause(0.15);
                end
                TMSiSAGA_Handler.cleanAddress('handler');
                TMSiSAGA_Handler.cleanAddress('broadcast');
                TMSiSAGA_Handler.cleanAddress('status');
                TMSiSAGA_Handler.putMessage('monitor', 'Idle');
                TMSiSAGA_Handler.putMessage('status', 'idle');
                delete(lh);
                delete(buf);
                disconnect(device);
                lib.cleanUp();
            catch me
                lib.cleanUp();
                fid = fopen('.messages/error/background_handler_loop', 'w+');
                db.print_error_message(me, 'handler_loop_error', fid);
                fclose(fid);
                delete(lh);
                delete(buf);
                TMSiSAGA_Handler.cleanAddress('handler');
                TMSiSAGA_Handler.cleanAddress('broadcast');
                return;
            end
        end
    end
    
    methods (Static, Access=public)
        function record(max_retries)
            %RECORD   Start recording from both devices.
            n_retries = 0;
            if nargin < 1
                max_retries = 10;
            end
            while TMSiSAGA_Handler.getMessage('status', 'loading') && (n_retries < max_retries)
                pause(1);
                n_retries = n_retries + 1;
            end
            if n_retries == max_retries
                warning('Could not start recording!');
                return;
            end
            TMSiSAGA_Handler.checkRemove('handler', 'pause');
            TMSiSAGA_Handler.checkRemove('handler', 'stop');
            TMSiSAGA_Handler.putMessage('broadcast', 'record');
        end
        
        function ready()
            if TMSiSAGA_Handler.getMessage('status', 'waiting')
                TMSiSAGA_Handler.putMessage('status', 'begin'); 
            end
        end
        
        function shutdown()
            TMSiSAGA_Handler.putMessage('broadcast', 'stop'); 
            TMSiSAGA_Handler.putMessage('status', 'idle');
        end
        
        function stop()
            %STOP This public method only sets the flag, which is used in
            %the protected internal methods of the class to shut down a
            %recording that is in progress (if needed).
            TMSiSAGA_Handler.putMessage('broadcast', 'pause');
        end
        
        function tf = getMessage(addr, name)
            %GETMESSAGE Checks for message at a given path
            msg = sprintf('.messages/%s/%s', addr, name);
            tf = exist(msg, 'file')~=0;
            if tf
                delete(msg);
            end
        end
        
        function msg = putMessage(addr, name)
            %PUTMESSAGE Puts a message on given path
            msg = sprintf('.messages/%s/%s', addr, name);
            fid = fopen(msg, 'w+');
            fprintf(fid, '1\n');
            fclose(fid);
        end
        
        function cleanAddress(addr)
            %CLEANADDRESS "Clean" the address in a given location.
            loc = sprintf('.messages/%s', addr);
            F = dir(loc);
            F = F(~[F.isdir]);
            for iF = 1:numel(F)
                delete(fullfile(F(iF).folder, F(iF).name));
            end
        end
        
        function checkRemove(addr, name)
            %CHECKREMOVE Remove this message if it exists
            msg = sprintf('.messages/%s/%s', addr, name);
            if exist(msg, 'file')~=0
                delete(msg);
            end
        end
    end
    
end
