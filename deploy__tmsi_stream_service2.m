%DEPLOY__TMSI_STREAM_SERVICE2 - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) server.
%   -> Takes a hopefully more-efficient approach than the original.
% See details in README.MD

%% Handle some basic startup stuff.
if exist('device', 'var')~=0
    disconnect(device);
end

if exist('lib', 'var')~=0
    lib.cleanUp();
end

if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all; %#ok<*CLALL> 
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

%% SET PARAMETERS
config_file = parameters('config');
fprintf(1, "[TMSi]::Loading configuration file (%s, in 2TMSi_MATLAB_Interface repo folder)...\n", config_file);
[config, TAG, SN, N_CLIENT] = parse_main_config(config_file);

%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();
try
    % Code within the try-catch to ensure that all devices are stopped and 
    % closed properly in case of a failure.
    device = lib.getDevices('usb', config.Default.Interface, 2, 2); 
    connect(device); 
    setDeviceTag(device, SN, TAG);
catch e
    % In case of an error close all still active devices and clean up
    lib.cleanUp();  
        
    % Rethrow error to ensure you get a message in console
    rethrow(e)
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.
    
    getDeviceInfo(device);
    configStandardMode(device);
    for ii = 1:numel(device)
        fprintf(1,'[TMSi]\t->\tDetected device(%d): SAGA=%s | API=%d | INTERFACE=%s\n', ii, device(ii).tag, device(ii).api_version, device(ii).data_recorder.interface_type);
    end
    if numel(device) ~= N_CLIENT
        fprintf(1,'[TMSi]\t->\tWrong number of devices returned. Something went wrong with hardware connections.\n');
    end
catch e
    disconnect(device);
    lib.cleanUp();
    rethrow(e);
end

%% Create TMSi stream client + udpport
ordered_tags = strings(size(device));
ch = struct();
for ii = 1:numel(ordered_tags)
    ordered_tags(ii) = string(device(ii).tag);
    ch.(ordered_tags(ii)) = device(ii).getActiveChannels();
    setSAGA(ch.(ordered_tags(ii)), ordered_tags(ii));
end
node = TMSi_Node(ordered_tags, ch, config, 'device', "virtual");
dt = datetime('now');
node.set_name(config.Default.Subject, year(dt), month(dt), day(dt), 0);

% % Initialize impedance-measurement variables % %
impedance_data = cell(size(device));
iPlot = cell(size(device));

%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    fprintf(1, "\n\t\t->\t[%s] SAGA LOOP BEGIN\t\t<-\n\n",string(datetime('now')));

    while true      
        switch node.state
            case enum.TMSiState.IDLE
                switch node.transition
                    case enum.TMSiTransition.FROM_IMPEDANCE
                        stop(device);
                        configStandardMode(device);
                        for ii = 1:numel(device)
                            try %#ok<TRYNC> 
                                delete(iPlot{ii});
                            end
                            impedance_saver_helper(node.fname, device(ii).tag, impedance_data{ii});
                        end
                        node.reset_buffers();
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RUNNING
                        stop(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RECORDING
                        stop(device);
                        node.save_recording(ordered_tags);
                        node.clear_transition();
                    otherwise 
                end

            case enum.TMSiState.RUNNING
                switch node.transition
                    case enum.TMSiTransition.FROM_IDLE
                        start(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_IMPEDANCE
                        stop(device);
                        for ii = 1:numel(device)
                            try %#ok<TRYNC> 
                                delete(iPlot{ii});
                            end
                            device(ii).configStandardMode();
                            impedance_saver_helper(node.fname, device(ii).tag, impedance_data{ii});
                        end
                        start(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RECORDING
                        node.save_recording(ordered_tags);
                        node.clear_transition();
                    otherwise % Append to the sample buffer
                        for ii = 1:N_CLIENT
                            samples = device(ii).sample();
                            node.append(device(ii).tag, samples);
                        end
                end

            case enum.TMSiState.RECORDING
                switch node.transition
                    case enum.TMSiTransition.FROM_IDLE
                        start(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RUNNING
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_IMPEDANCE
                        stop(device);
                        for ii = 1:numel(device)
                            try %#ok<TRYNC> 
                                delete(iPlot{ii});
                            end
                            device(ii).configStandardMode();
                            impedance_saver_helper(node.fname, device(ii).tag, impedance_data{ii});
                        end
                        start(device);
                        node.clear_transition();
                    otherwise % Append to the sample buffer
                        for ii = 1:N_CLIENT
                            samples = device(ii).sample();
                            node.append(device(ii).tag, samples);
                        end
                end

            case enum.TMSiState.IMPEDANCE
                switch node.transition
                    case {enum.TMSiTransition.FROM_IDLE, enum.TMSiTransition.FROM_RUNNING, enum.TMSiTransition.FROM_RECORDING}
                        if ismember(node.transition, [enum.TMSiTransition.FROM_RUNNING, enum.TMSiTransition.FROM_RECORDING])
                            stop(device);
                            if node.transition == enum.TMSiTransition.FROM_RECORDING
                                node.save_recording(ordered_tags);
                            end
                        end
                        configImpedanceMode(device);
                        for ii = 1:numel(device)
                            start(device(ii));
                            channel_names = getName(getActiveChannels(device(ii)));
                            iPlot{ii} = TMSiSAGA.ImpedancePlot(device(ii).tag, channel_names);
                        end
                        node.clear_transition();
                    otherwise % Do normal stuff for this state
                        for ii = 1:numel(device)
                            if is_fig_valid(iPlot{ii})
                                [samples, num_sets] = device(ii).sample();
                                % Append samples to the plot and redraw
                                if num_sets > 0
                                    impedance_data{ii} = samples ./ 10^6; % need to divide by 10^6
                                    iPlot{ii}.grid_layout(impedance_data{ii});
                                    drawnow;
                                end
                            end
                        end
                end
            case enum.TMSiState.QUIT
                switch node.transition
                    case enum.TMSiTransition.FROM_IMPEDANCE
                        stop(device);
                        for ii = 1:numel(device)
                            try %#ok<TRYNC> 
                                delete(iPlot{ii});
                            end
                            device(ii).configStandardMode();
                            impedance_saver_helper(node.fname, device(ii).tag, impedance_data{ii});
                        end
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_IDLE
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RUNNING
                        stop(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RECORDING
                        stop(device);
                        node.save_recording(ordered_tags);
                        node.clear_transition();
                    otherwise % Execute the actual shutdown process
                        disconnect(device);
                        clear node device
                        lib.cleanUp();  % % % Make sure to run this when you are done! % % %
                        break;
                end
        end
        pause(0.005); % Allow the configured callbacks to execute.
    end
catch me
    % Stop both devices.
    try  %#ok<TRYNC>
        stop(device);
    end
    try %#ok<TRYNC>
        disconnect(device);
    end
    clear node device
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
    rethrow(me);
end
