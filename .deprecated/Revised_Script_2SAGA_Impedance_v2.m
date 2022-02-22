% Script that enables sampling from two devices. Assumption is that the
% first device receives Sync In via the DIGI channel and that the second
% device sends Sync Out signals using the Sync Out Waveform.
%
% Best practice is to first stop sampling from the second device, as this
% can be reflected clearly in the STATUS channel of the first device as
% well (as no Sync In data is obtained when sampling has stopped on the
% second device). 

% If the script has been terminated manually, it can occur that the device
% keeps sampling. To be sure, a lib.cleanUp() is performed prior to running
% the example.

clear all
clc

%% Initialize Program

Filename1 = sprintf('impedance_%s.mat', datestr(now,'mm-dd-yyyy HH-MM-SS')); % added
if exist('lib', 'var')
    disp('[N/A] Ensure library is cleaned...')
    lib.cleanUp();
end

if ~license('test', 'Signal_Toolbox')
    error('This example requires the Signal Processing Toolbox to be installed')    
end

% Initialize the library
lib = TMSiSAGA.Library();

% Normalisation initialisation
normalisation = 0;

% Direction the connector points to seen from an anterior view of the
% frontal plane ('left', 'down', 'right' and 'up')
connector_orientation = 'up';

%% Set Configurations

% Impedance configuration
config_impedance = struct('ImpedanceMode', true, ... 
                          'ReferenceMethod', 'common', ...
                          'Triggers', false);

% Measurement configuration
config_measurement = struct('ImpedanceMode', false, ... 
                          'ReferenceMethod', 'common', ...
                          'AutoReferenceMethod', true, ...
                          'BaseSampleRate', 4000, ...
                          'Dividers', {{'uni', 0;}}, ...
                          'RepairLogging', false);
                      
% Configuration for Device 1 (Digi IN)
config_device_1 = struct('Dividers', {{'uni', 0;}}, ...
                        'BaseSampleRate', 4000, ...
                        'ReferenceMethod', 'common',...
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);

% Configuration for Device 2 (Sync Out)
config_device_2 = struct('Dividers', {{'uni',0;}}, ...
                        'BaseSampleRate', 4000, ...
                        'ReferenceMethod', 'common', ...
                        'SyncOutDivider', -1, ...
                        'SyncOutDutyCycle', 500);
                                     
% Channel configuration
channel_config = struct('uni',1:64);
% channel_config_device2 = struct('bip', 1:2);
                     
% Filter configuration
order = 2;
Fc = 10; % Hz

%% Connect and Update Devices

% Code within the try-catch to ensure that all devices are stopped and 
% closed properly in case of a failure.
%try
    % Get a list with the connected devices
    % possible interfaces 'usb'/'network' and 'electrical'/'optical/'wifi'
    devices = lib.getDevices('usb', 'electrical');
    
    % Assign the first found device
    device_1 = devices{1};
    
    % Check whether a second device is detected
    if devices{2}.device_id ~= 0
        device_2 = devices{2}; 
    end
    
    % Open a connection to the first device.
    device_1.connect();
    
    % Open a connection to the second device.
    if exist('device_2','var')
        device_2.connect();
    else
        error('Not able to make connection to two devices');
    end
    
    % Set whether a SAGA32+ or SAGA64+ by getting the total number of
    % hardware channels and substracting 15 (for other channel types).
    SAGA_type = device_1.num_hw_channels - 15;    
    
    % Update device configuration  
    device_1.setDeviceConfig(config_impedance);  
    device_2.setDeviceConfig(config_impedance);  
        
    % Update channel configuration
    device_1.setChannelConfig(channel_config);
    device_2.setChannelConfig(channel_config);
    
%% Check Impedance for Grid 1

    % Create a list of channel names that can be used for printing the
    % impedance values next to the figure
    for i=1:length(device_1.getActiveChannels())
        channel_names{i}=device_1.getActiveChannels{i}.alternative_name;
    end

    % Create an ImpedancePlot object
    iPlot = TMSiSAGA.ImpedancePlot('Impedance of the HD EMG grid (Grid 1)', channel_config.uni, channel_names, SAGA_type);
    iPlot.show();

    % Start sampling on the device
    device_1.start();
    
    % Remain in impedance mode until the figure is closed
    while iPlot.is_visible
        % Sample from device
        [samples, num_sets, type] = device_1.sample();
        % Append samples to the plot and redraw
        if num_sets > 0
            s1=samples ./ 10^6; % need to divide by 10^6
            iPlot.grid_layout(s1);
        end        
    end
    
    % Stop sampling on the device
    device_1.stop(); 
      
%% Check Impedance for Grid 2
    
    % Create a list of channel names that can be used for printing the
    % impedance values next to the figure
    clear channel_names
    for i=1:length(device_2.getActiveChannels())
        channel_names{i}=device_2.getActiveChannels{i}.alternative_name;
    end
    
    % Create an ImpedancePlot object
    iPlot = TMSiSAGA.ImpedancePlot('Impedance of the HD EMG grid (Grid 2)', channel_config.uni, channel_names, SAGA_type);
    iPlot.show();
    
    % Start sampling on the device
    device_2.start();
    
    % Remain in impedance mode until the figure is closed
    while iPlot.is_visible
        % Sample from device
        [samples, num_sets, type] = device_2.sample();
        % Append samples to the plot and redraw
        if num_sets > 0
            s2=samples ./ 10^6;
            iPlot.grid_layout(s2); % need to divide by 10^6.
        end
    end
    
    % Stop sampling on the device
    device_2.stop();
    
%% Initialize Objects to Plot and Save Data and Update Devices
    
    % Update device configuration
%     device_1.setDeviceConfig(config_measurement);
%     device_2.setDeviceConfig(config_measurement);
    device_1.setDeviceConfig(config_device_1);
    device_2.setDeviceConfig(config_device_2);
    
    % Create a list of channel names 
    for i=1:length(device_1.getActiveChannels())
        channel_names_1{i}=device_1.getActiveChannels{i}.alternative_name;
    end
    for i=1:length(device_2.getActiveChannels())
        channel_names_2{i}=device_2.getActiveChannels{i}.alternative_name;
    end
    
    % Initialise the sample buffer and the window_size
    sample_buffer = zeros(numel(device_1.getActiveChannels()), 0);
    window_seconds = 0.5;
    window_samples = round(window_seconds * device_1.sample_rate);
    
    % Initialise the objects to be used in the workflow
    vPlot_1 = TMSiSAGA.Visualisation(device_1.sample_rate, device_1.getActiveChannels(), window_samples);
    vPlot_2 = TMSiSAGA.Visualisation(device_2.sample_rate, device_2.getActiveChannels(), window_samples);
%     rPlot_1 = TMSiSAGA.RealTimePlot('Plot', device_1.sample_rate, device_1.getActiveChannels());
%     rPlot_1.show();
%     rPlot_2 = TMSiSAGA.RealTimePlot('Plot', device_2.sample_rate, device_2.getActiveChannels());
%     rPlot_2.show();
    
    % Create a data object for storage to memory and a RealTimePlot object
    poly5_dev1 = TMSiSAGA.Poly5(['./HD_EMG_measurement_Grid1_' datestr(datetime('now'), 'dd-mm-yyyy_HH.MM.SS') '.poly5'], ...
        'Plot', device_1.sample_rate, device_1.getActiveChannels()); % for device 1
    poly5_dev2 = TMSiSAGA.Poly5(['./HD_EMG_measurement_Grid2_' datestr(datetime('now'),'dd-mm-yyyy_HH.MM.SS') '.poly5'], ...
        'Plot', device_2.sample_rate, device_2.getActiveChannels()); % for device 2
       
 %% Sample Data for a Device as Long as its Respective Plot Object is Visible 
 
%     % Start sampling 
%     device_1.start(); % on device 1
%     device_2.start(); % on device 2
%     
%     %  Device 1
%     while vPlot_1.is_visible 
%         if vPlot_1.is_visible
%             % Sample from device 1
%             [samples_1, num_sets_1, type_1] = device_1.sample();
%             % When samples are retrieved, append the data to the Poly5 and Plot objects.
%             if num_sets_1 > 0
% %                 if isempty(device_2.is_sampling)
% %                     Start sampling on device 2
% %                    device_2.start();
% %                 end
%                 poly5_dev1.append(samples_1);
% %                 rPlot_1.append(samples_1);
% %                 rPlot_1.draw();
%                 % Append samples to a buffer, so that there is always
%                 % a minimum of window_samples to process the data
%                 sample_buffer(:, size(sample_buffer, 2) + size(samples_1, 2)) = 0;
%                 sample_buffer(:, end-size(samples_1, 2) + 1:end) = samples_1;
%                 % As long as we have enough samples calculate RMS values.
%                 while size(sample_buffer, 2) >= window_samples
%                     % Find the RMS value of the window
%                     data_plot_1 = vPlot_1.RMSEnvelope(sample_buffer(:,1:window_samples), Fc, order);
%                     % Call the visualisation function
%                     vPlot_1.EMG_Visualisation(sample_buffer, data_plot_1, normalisation,...
%                         'Heat map of the muscle activation (Grid 1)', ...
%                         connector_orientation)
%                     % Check if there are no missed samples due to processing time.
% %                     if any(diff(sample_buffer(end,:)) > 1)
% %                         % Cleanup internal data storage buffer
% %                         poly5_dev1.close();
% %                         error('Sample counter error. Samples are lost due to slow processing of the HD EMG visualisation.')
% %                     end
%                     
%                     % Clear the processed window from the sample buffer
%                     sample_buffer = sample_buffer(:, window_samples + 1:end);
%                 end
%             end
%             % Stop sampling from device when the Plot object of device 1 is destroyed.
%         elseif device_1.is_sampling
%             % Sample the data one last time
%             [samples_1, num_sets_1, type] = device_1.sample();
%             device_1.stop();
%             % When samples are retrieved, append the data to the Poly5 and Plot objects.
%             if num_sets_1 > 0
%                 poly5_dev1.append(samples_1);
%             end
%         end   
%     end
%     
%     % Device 2
%     while vPlot_2.is_visible
%         %   while rPlot_2.is_visible
%         if vPlot_2.is_visible
%             %       if rPlot_2.is_visible
%             % Sample from device 2.
%             [samples_2, num_sets_2, type_2] = device_2.sample();
%             % When samples are retrieved, append the data to the Poly5 and Plot objects.
%             if num_sets_2 > 0
%                 poly5_dev2.append(samples_2);
%                 %             rPlot_2.append(samples_2);
%                 %             rPlot_2.draw();
%                 % Append samples to a buffer, so that there is always
%                 % a minimum of window_samples to process the data
%                 sample_buffer(:, size(sample_buffer, 2) + size(samples_2, 2)) = 0;
%                 sample_buffer(:, end-size(samples_2, 2) + 1:end) = samples_2;
%                 % As long as we have enough samples calculate RMS values.
%                 while size(sample_buffer, 2) >= window_samples
%                     % Find the RMS value of the window
%                     data_plot_2 = vPlot_2.RMSEnvelope(sample_buffer(:,1:window_samples), Fc, order);
%                     % Call the visualisation function
%                     vPlot_2.EMG_Visualisation(sample_buffer, data_plot_2, normalisation,...
%                         'Heat map of the muscle activation (Grid 2)', ...
%                         connector_orientation)
%                     % Check if there are no missed samples due to processing time.
%                     %                 if any(diff(sample_buffer(end,:)) > 1)
%                     %                     % Cleanup internal data storage buffer
%                     %                     poly5_dev2.close();
%                     %                     error('Sample counter error. Samples are lost due to slow processing of the HD EMG visualisation.')
%                     %                 end
%                     % Clear the processed window from the sample buffer
%                     sample_buffer = sample_buffer(:, window_samples + 1:end);
%                 end
%             end
%             % Stop sampling from device when the Plot object of device 2 is destroyed.
%         elseif device_2.is_sampling
%             % Sample the data one last time
%             [samples_2, num_sets_2, type] = device_2.sample();
%             device_2.stop();
%             % When samples are retrieved, append the data to the Poly5 and Plot objects.
%             if num_sets_2 > 0
%                 poly5_dev2.append(samples_2);
%             end
%         end
%     end

%% Sample from data for 40 seconds

    % Start sampling 
    device_1.start(); % on device 1
    device_2.start(); % on device 2
    
    disp('Recording has begun!')
    
    %  Device 1
    %set start time
    t0 = clock;

    %count to 60 seconds
    while etime(clock, t0) < 40
        if etime(clock, t0) < 40
            % Sample from device 1
            [samples_1, num_sets_1, type_1] = device_1.sample();
            % When samples are retrieved, append the data to the Poly5 and Plot objects.
            if num_sets_1 > 0
%                 if isempty(device_2.is_sampling)
%                     Start sampling on device 2
%                    device_2.start();
%                 end
                poly5_dev1.append(samples_1);
%                 rPlot_1.append(samples_1);
%                 rPlot_1.draw();
                % Append samples to a buffer, so that there is always
                % a minimum of window_samples to process the data
                sample_buffer(:, size(sample_buffer, 2) + size(samples_1, 2)) = 0;
                sample_buffer(:, end-size(samples_1, 2) + 1:end) = samples_1;
                % As long as we have enough samples calculate RMS values.
                while size(sample_buffer, 2) >= window_samples
                    % Find the RMS value of the window
                    data_plot_1 = vPlot_1.RMSEnvelope(sample_buffer(:,1:window_samples), Fc, order);
                    % Call the visualisation function
                    vPlot_1.EMG_Visualisation(sample_buffer, data_plot_1, normalisation,...
                        'Heat map of the muscle activation (Grid 1)', ...
                        connector_orientation)
                    % Check if there are no missed samples due to processing time.
%                     if any(diff(sample_buffer(end,:)) > 1)
%                         % Cleanup internal data storage buffer
%                         poly5_dev1.close();
%                         error('Sample counter error. Samples are lost due to slow processing of the HD EMG visualisation.')
%                     end
                    
                    % Clear the processed window from the sample buffer
                    sample_buffer = sample_buffer(:, window_samples + 1:end);
                end
            end
            % Stop sampling from device when the Plot object of device 1 is destroyed.
        elseif device_1.is_sampling
            % Sample the data one last time
            [samples_1, num_sets_1, type] = device_1.sample();
            device_1.stop();
            % When samples are retrieved, append the data to the Poly5 and Plot objects.
            if num_sets_1 > 0
                poly5_dev1.append(samples_1);
            end
        end   
    end
    
    
    % Device 2
    while etime(clock, t0) < 40
        if etime(clock, t0) < 40
            %       if rPlot_2.is_visible
            % Sample from device 2.
            [samples_2, num_sets_2, type_2] = device_2.sample();
            % When samples are retrieved, append the data to the Poly5 and Plot objects.
            if num_sets_2 > 0
                poly5_dev2.append(samples_2);
                %             rPlot_2.append(samples_2);
                %             rPlot_2.draw();
                % Append samples to a buffer, so that there is always
                % a minimum of window_samples to process the data
                sample_buffer(:, size(sample_buffer, 2) + size(samples_2, 2)) = 0;
                sample_buffer(:, end-size(samples_2, 2) + 1:end) = samples_2;
                % As long as we have enough samples calculate RMS values.
                while size(sample_buffer, 2) >= window_samples
                    % Find the RMS value of the window
                    data_plot_2 = vPlot_2.RMSEnvelope(sample_buffer(:,1:window_samples), Fc, order);
                    % Call the visualisation function
                    vPlot_2.EMG_Visualisation(sample_buffer, data_plot_2, normalisation,...
                        'Heat map of the muscle activation (Grid 2)', ...
                        connector_orientation)
                    % Check if there are no missed samples due to processing time.
                    %                 if any(diff(sample_buffer(end,:)) > 1)
                    %                     % Cleanup internal data storage buffer
                    %                     poly5_dev2.close();
                    %                     error('Sample counter error. Samples are lost due to slow processing of the HD EMG visualisation.')
                    %                 end
                    % Clear the processed window from the sample buffer
                    sample_buffer = sample_buffer(:, window_samples + 1:end);
                end
            end
            % Stop sampling from device when the Plot object of device 2 is destroyed.
        elseif device_2.is_sampling
            % Sample the data one last time
            [samples_2, num_sets_2, type] = device_2.sample();
            device_2.stop();
            % When samples are retrieved, append the data to the Poly5 and Plot objects.
            if num_sets_2 > 0
                poly5_dev2.append(samples_2);
            end
        end
    end
    
    disp('Recording has finished!')

%% Make Sure Devices Are Stopped and Close Poly5 File
% Depending on which RealTimePlot is destroyed last, the device needs
% to stop sampling from the device that is stopped last.
if device_1.is_sampling
    % Sample the data one last time
    [samples_1, num_sets_1, type] = device_1.sample();
    device_1.stop();
    % When samples are retrieved, append data to the Poly5 object.
    if num_sets_1 > 0
        poly5_dev1.append(samples_1);
    end
end

if device_2.is_sampling
    % Sample the data one last time
    [samples_2, num_sets_2, type] = device_2.sample();
    device_2.stop();
    
    % When samples are retrieved, append data to the Poly5 object.
    if num_sets_2 > 0
        poly5_dev2.append(samples_2);
    end
    
end

% Close Poly5 files.
poly5_dev1.close();
poly5_dev2.close();

%% Disconnect Devices

% Disconnect both devices.
device_1.disconnect();
device_2.disconnect();

% clean up and unload the library
lib.cleanUp();

% catch e
%     % Close Poly5 files.
%     poly5_dev1.close();
%     poly5_dev2.close();
%     
%     % In case of an error close all still active devices and clean up
%     % library itself
%     lib.cleanUp();  
%         
%     % Rethrow error to ensure you get a message in console
%     rethrow(e)
% end

%% Save Impedance Files

impedance1 =s1; % added
save(Filename1,'impedance1') % added

Filename2 = sprintf('impedance_%s.mat', datestr(now,'mm-dd-yyyy HH-MM-SS')); % added
impedance2 =s2; % added
save(Filename2,'impedance2') % added
