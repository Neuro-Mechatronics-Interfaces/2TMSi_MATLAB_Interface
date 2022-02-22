classdef TMSiSAGA_Handler < handle
    %TMSiSAGA_Handler  Handles stuff related to the two TMSi devices
    %
    % This is the version prior to moving to full background library load.
    %
    % Syntax:
    %   obj = TMSiSAGA_Handler()
    
    properties (Access = public)
        lib                       % The `TMSiSAGA.Library` object handling dlls
        device                    % Array of `TMSiSAGA.Device` objects
        file    cell = cell(2, 1)            % Poly5 files associated with each device's recording
        pool    parallel.Pool                % Worker for running recording (uses single worker)
        edata   struct = struct('stop', []); % Event Data struct with (see FutureFeval)
    end
    
    properties (GetAccess = public, SetAccess = protected)
        tank    string = strings(1, 1)   % Data tank where files will be saved
        block   string = strings(1, 1)   % Folder in the tank where recordings will be saved
        subject string = strings(1, 1)   % Subject name
        dmeta   struct = struct('A', struct('present', false, 'index', nan, 'block', strings(1, 1)), 'B', struct('present', false, 'index', nan, 'block', strings(1, 1)));
        flags   struct = struct('stop', false, 'is_stopped', false);
        msg     struct = struct('idle', false, 'running', false, 'stop', false);
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
    end
    
    events
        DiskFileEvent  % Event fired when Poly5 Disk File starts or stops.
        % Has fields: .type = "Start" | "Stop"
        %             .ts  (timestamp)
        %             .key (same as protected class property .key)
        StatusEvent    % Event fired on key status changes monitored by `status_pool` worker
    end
    
    methods
        function obj = TMSiSAGA_Handler()
            %TMSISAGA_HANDLER  Wrapper class for two TMSiSAGA 64-bit devices.
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
            fid = fopen('.messages/idle', 'w+');
            fprintf(fid, '1\n');
            fclose(fid);
            obj.msg.idle = true;
            if exist('.messages/broadcast', 'dir')==0
                mkdir('.messages/broadcast');
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
            toAttach = { ...
                which(fullfile(pwd, '+TMSiSAGA\Channel.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\DataRecorderInfo.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\DockingStationInfo.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\HiddenHandle.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\Library.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\DeviceLib.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\Device.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\Poly5.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiUtils.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib64.m')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.dll')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.exp')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.lib')), ...
                which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.obj')) ...
                }; 
%             toAttach = {'TMSiSagaDeviceLib.dll', 'TMSiSagaDeviceLib64.m', 'TMSiSagaDeviceLib_thunk_pcwin64.dll', 'TMSiSagaDeviceLib_thunk_pcwin64.exp', 'TMSiSagaDeviceLib_thunk_pcwin64.lib', 'TMSiSagaDeviceLib_thunk_pcwin64.obj'};
            obj.pool = parpool(1, ...
                'IdleTimeout', 240, ...
                'EnvironmentVariables', {'PATH'}, ...
                'AttachedFiles', toAttach);
            obj.lib = TMSiSAGA.Library();
            spmd
                TMSiSAGA.Library.loadLibrary(); 
            end
            obj.device = obj.lib.getDevices({'usb'}, {'electrical'});
            connect(obj.device);
            tags = ["A", "B"];
            tagSN = [snA, snB];
            sn = getSerialNumber(obj.device);
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
                    obj.device(idx).tag = tags(iTag);
                    obj.device(idx).impedance_file_expr = obj.impedance_file_expr;
                    obj.device(idx).data_file_expr = obj.data_file_expr;
                    getDeviceInfo(obj.device(idx));
                    enableChannels(obj.device(idx), {obj.device(idx).channels});
                    updateDeviceConfig(obj.device(idx));
                    obj.device(idx).setChannelConfig(obj.channel_config);
                    obj.device(idx).recording_index = obj.start_index;
                end
            end
            for k = 1:2
                names = getName(obj.device(k).getActiveChannels());
                obj.trig_channel(k) = find(contains(names, "TRIGGERS"), 1, 'first');
                obj.data_channel{k} = contains(names, "UNI");
            end
        end
        
        function delete(obj)
            %DELETE  Since it is overloaded builtin, make sure everything
            %is in a `try catch` enclosure so that it doesn't mess up the
            %actual object destructor.
            try
                stop(obj.device);
            catch
            end
            try
                disconnect(obj.device);
            catch
            end
            try
                close(obj.file);
            catch
            end
            try
                obj.lib.cleanUp();
            catch
            end
            try
                delete(gcp('nocreate'));
            catch
            end
            
            f = fieldnames(obj.msg);
            for iF = 1:numel(f)
                if obj.msg.(f{iF})
                    try
                        delete(sprintf('.messages/%s', f{iF})); 
                    catch
                    end
                end
            end
        end
        
        function tf = has_received_stop_signal(obj)
            %HAS_RECEIVED_STOP_SIGNAL  Check if wrapper "stop" flag has been set.
            tf = exist('.messages/stop', 'file')~=0;
            if tf  % If we should stop, then stop sampling.
                try
                    if exist('.messages/running', 'file')~=0
                        delete('.messages/running');
                    end
                    obj.msg.running = false;
                catch me
                    db.print_error_message(me);
                end
            end
        end
        
        function record(obj)
            %RECORD   Start recording from both devices.
            should_record = false;
            vec = 1:2;
            rec_index = struct('A', nan, 'B', nan);
            % In case both devices are present (they should be), we
            % want to be sure that they are in-sync with respect to any
            % parameters key. Therefore, if the other device is
            % present, check that rec_index.B is same as rec_index.A
            % and if not, make sure that the greater of the two indices
            % is used to set the current recording index moving
            % forward.
            if obj.dmeta.A.present && obj.dmeta.B.present
                rec_index.A = obj.device(obj.dmeta.A.index).recording_index;
                rec_index.B = obj.device(obj.dmeta.B.index).recording_index;
                if rec_index.A ~= rec_index.B
                    if rec_index.A > rec_index.B
                        rec_index.B = rec_index.B;
                        obj.device(obj.dmeta.B.index).recording_index = rec_index.B;
                    else
                        rec_index.A = rec_index.B;
                        obj.device(obj.dmeta.A.index).recording_index = rec_index.A;
                    end
                end
            end
            
            % If device A is present, then we should make a poly5 file.
            if obj.dmeta.A.present
                data_file_name = get_new_names(obj.device(obj.dmeta.A.index));
                obj.dmeta.A.block = string(sprintf('%s_%s_%d', obj.block, obj.device(obj.dmeta.A.index).tag, obj.device(obj.dmeta.A.index).recording_index));
                obj.file{obj.dmeta.A.index} = TMSiSAGA.Poly5(fullfile(obj.tank, obj.dmeta.A.block, data_file_name), ...
                    obj.device(obj.dmeta.A.index).sample_rate, obj.device(obj.dmeta.A.index).getActiveChannels());
                should_record = true;
                obj.device(obj.dmeta.A.index).is_recording = true;
                rec_index.A = obj.device(obj.dmeta.A.index).recording_index;  % This is auto-incremented in `get_new_names` call.
            else
                vec(obj.dmeta.A.index) = nan;
            end
            
            % If device B is present, then we should make a file for that
            % one (too).
            if obj.dmeta.B.present
                data_file_name = get_new_names(obj.device(obj.dmeta.B.index));
                obj.dmeta.B.block = string(sprintf('%s_%s_%d', obj.block, obj.device(obj.dmeta.B.index).tag, obj.device(obj.dmeta.B.index).recording_index));
                obj.file{obj.dmeta.B.index} = TMSiSAGA.Poly5(fullfile(obj.tank, obj.dmeta.B.block, data_file_name), ...
                    obj.device(obj.dmeta.B.index).sample_rate, obj.device(obj.dmeta.B.index).getActiveChannels());
                should_record = true;
                obj.device(obj.dmeta.B.index).is_recording = true;
                rec_index.B = obj.device(obj.dmeta.B.index).recording_index;  % This is auto-incremented in `get_new_names` call.
            else
                vec(obj.dmeta.B.index) = nan;
            end
            vec(isnan(vec)) = []; % Get rid of any devices that we're not supposed to sample on.
            if ~obj.pool.Connected
                try
                    delete(gcp('nocreate'));
                catch
                end
                toAttach = { ...
                    which(fullfile(pwd, '+TMSiSAGA\Channel.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\DataRecorderInfo.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\DockingStationInfo.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\HiddenHandle.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\Library.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\DeviceLib.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\Device.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\Poly5.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiUtils.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib64.m')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.dll')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.exp')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.lib')), ...
                    which(fullfile(pwd, '+TMSiSAGA\TMSiSagaDeviceLib_thunk_pcwin64.obj')) ...
                    }; 
%                 toAttach = {'TMSiSagaDeviceLib.dll', 'TMSiSagaDeviceLib64.m', 'TMSiSagaDeviceLib_thunk_pcwin64.dll', 'TMSiSagaDeviceLib_thunk_pcwin64.exp', 'TMSiSagaDeviceLib_thunk_pcwin64.lib', 'TMSiSagaDeviceLib_thunk_pcwin64.obj'};
                obj.pool = parpool(1, ...
                    'IdleTimeout', 240, ...
                    'EnvironmentVariables', {'PATH'}, ...
                    'AttachedFiles', toAttach);
                spmd
                    TMSiSAGA.Library.loadLibrary(); 
                end
            end
            if should_record % Allows event listeners to interact with this method
                obj.flags.stop = false; % Make sure we revert the "stop" flag.
                obj.flags.is_stopped = false; % Also update that it is not yet stopped.
                
                disp('Removing `idle` message.');
                if exist('.messages/idle', 'file')~=0
                    delete('.messages/idle');
                end
                obj.msg.idle = false;
                pause(0.025);
                
                disp('Adding `running` message.');
                fid = -1;
                while (fid == -1)
                    fid = fopen('.messages/running', 'w+');
                    pause(0.025);
                    fprintf(1, 'FID: %d\n', fid);
                end
                fprintf(fid, '1\n');
                fclose(fid);
                obj.msg.running = true;
                for k = 1:numel(vec)
                    start(obj.device(vec(k)));
                    obj.device(vec(k)).is_recording = true;
                end
%                 try
%                     TMSiSAGA.Library.unloadLibrary();
%                 catch me
%                     db.print_error_message(me, 'unload_error', 1);
%                 end
                pause(0.05);
                ts = Microcontroller.convert_to_Mats_ts_format(default.now());
                start_eventdata = DiskFileEventData(ts, "Start", rec_index.A); % By this point, they should be identical.
                notify(obj, "DiskFileEvent", start_eventdata);
                parfeval(obj.pool, @obj.record_, 0, vec);
            else % Otherwise neither device passed our checks. What happened?
                warning('No devices ready to start recording! Did not start anything...');
            end
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
        
        function shutdown(obj)
            %SHUTDOWN  Call this at the end to unload library etc.
            try
                stop(obj.device);
            catch
            end
            try
                disconnect(obj.device);
            catch
            end
            try
                close(obj.file);
            catch
            end
            try
                obj.lib.cleanUp();
            catch
            end
            obj.dmeta.A.present = false;
            obj.dmeta.B.present = false;
            delete(obj.pool);
            try
                fclose('all');
            catch
            end
            f = fieldnames(obj.msg);
            for iF = 1:numel(f)
                if obj.msg.(f{iF})
                    try
                        fname = sprintf('.messages/%s', f{iF});
                        if exist(fname, 'file')~=0
                            delete(fname);
                        end
                        obj.msg.(f{iF}) = false;
                    catch
                    end
                end
            end
            fid = fopen('.messages/idle', 'w+');
            fprintf(fid, '1\n');
            fclose(fid);
            obj.msg.idle = true;
        end
        
        function stop(obj)
            %STOP This public method only sets the flag, which is used in
            %the protected internal methods of the class to shut down a
            %recording that is in progress (if needed).
            if exist('.messages/running', 'file')~=0
                fid = fopen('.messages/stop', 'w+');
                fprintf(fid, '1\n');
                fclose(fid);
                obj.msg.stop = true;
            end
            obj.flags.stop = true;
            % Now introduce blocking part:
            pause(0.5);
            while (exist('.messages/running', 'file')~=0)
                disp('Process still running...');
                pause(1); 
            end
            
            try
                if exist('.messages/stop', 'file')~=0
                    delete('.messages/stop');
                end
                obj.msg.stop = false;
            catch me
                db.print_error_message(me);
            end
            fid = fopen('.messages/idle', 'w+');
            fprintf(fid, '1\n');
            fclose(fid);
%             try
%                 TMSiSAGA.Library.loadLibrary();
%             catch me
%                 db.print_error_message(me, 'reload_error', 1);
%             end
            stop(obj.device);
            if obj.dmeta.A.present
                obj.device(obj.dmeta.A.index).stop();
                delete(obj.file{obj.dmeta.A.index}); % Does `close`
                pause(0.25);
            end
            if obj.dmeta.B.present
                obj.device(obj.dmeta.B.index).stop();
                delete(obj.file{obj.dmeta.B.index}); % Does `close`
                pause(0.25);
            end
            obj.msg.idle = true;
            ts = Microcontroller.convert_to_Mats_ts_format(default.now());
            eventdata = DiskFileEventData(ts, "Stop", obj.key);
            notify(obj, "DiskFileEvent", eventdata);
        end
    end
    
    methods (Access = protected)     
        function monitor_(obj)
            %MONITOR_ This gets parallel pool as well to monitor for StatusEvent notifications
            keep_monitoring = true;
            % First, clear out any indicator files that may have
            % accumulated in this folder.
            F = dir('.messages/broadcast/*');
            F = F(~[F.isdir]);
            for iF = 1:numel(F)
                delete(fullfile(F(iF).folder, F(iF).name)); 
            end
            % Now, until we receive "quit" (special indicator) file in
            % .messages/broadcast/, continue to look for .event indicator
            % files.
            while keep_monitoring
                F = dir('.messages/broadcast/*.event');
                if ~isempty(F)
                    [~, idx] = sort([F.datenum], 'ascend');
                    for ii = 1:numel(idx)
                        [~, type, ~] = fileparts(F(idx(ii)).name);
                        ts = Microcontroller.convert_to_Mats_ts_format(default.now());
                        data = SAGAEventData(ts, type);
                        notify(obj, "StatusEvent", data);
                        delete(fullfile(F(idx(ii)).folder, F(idx(ii)).name));
                    end
                end
                pause(0.25); % Sleep for 250-ms
                if exist('.messages/broadcast/quit', 'file')~=0
                    delete('.messages/broadcast/quit');
                    keep_monitoring = false;
                end
            end
        end
        
        function record_(obj, vec)
            %RECORD_  This is the part that goes to parallel pool for eval
%             try
%                 TMSiSAGA.Library.loadLibrary();
%             catch me
%                 fid = fopen('.messages/error/lib', 'w+');
%                 db.print_error_message(me, 'library_error', fid);
%                 fclose(fid);
%                 return;
%             end
            n = numel(obj.device(vec));
            for k = 1:n
                obj.device(vec(k)).is_sampling = true;
                obj.device(vec(k)).is_recording = true;
            end
            try
                while any([obj.device(vec).is_recording]) && (~obj.has_received_stop_signal())
                    for k = 1:n  % This is where we are selective about which device to sample
                        if obj.device(vec(k)).is_sampling
                            try
                                % % % TODO: This is where we implement a
                                % circular buffer in order to get the
                                % "real-time" stuff to actually work... % %
                                samples = obj.device(vec(k)).sample();
                                obj.file{vec(k)}.append(samples);
                            catch me
                                fid = fopen('.messages/error/record', 'w+');
                                db.print_error_message(me, 'recording_error', fid);
                                fclose(fid);
                            end
                        end
                    end
                end
            catch me
                db.print_error_message(me);
%                 TMSiSAGA.Library.unloadLibrary();
            end
%             TMSiSAGA.Library.unloadLibrary();
            
        end
    end
    
end
