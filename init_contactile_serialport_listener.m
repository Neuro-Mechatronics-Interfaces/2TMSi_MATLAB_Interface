function sp = init_contactile_serialport_listener(options)
    arguments
        options.COMPort {mustBeTextScalar} = "COM8";
        options.BaudRate (1,1) double {mustBePositive, mustBeInteger} = 9600;
        options.Parity = 'None';
        options.FlowControl = 'None';
        options.DataBits = 8;
        options.StopBits = 1;
        options.PollPeriod (1,1) double = 0.010; % Seconds
        options.RunAcquisition (1,1) logical = false;
    end
    % Constants
    % FRAME_LENGTH = 195; % Total bytes per frame
    % HEADER = uint8([0x55, 0x66, 0x77, 0x88]); % Start frame sequence
    % NUM_CHANNELS = 30; % 10 sensors * 3 channels each (X, Y, Z)
    % NUM_SENSORS = NUM_CHANNELS / 3; % Total sensors
    % PLOT_PERIOD = 0.5; % Seconds to plot
    % FRAME_PERIOD = 0.001; % Period of each frame in seconds
    % SAMPLES_PER_TRACE = round(PLOT_PERIOD / FRAME_PERIOD);
    % X_OFFSETS = fliplr(repmat(1.1*(SAMPLES_PER_TRACE * (0:(NUM_SENSORS/2-1))),1,2)); % Offset for XData of each sensor group
    % SENSOR_NAME = ["S0_A", "S0_B", "S0_C", "S0_D", "S0_E", ...
    %                "S1_A", "S1_B", "S1_C", "S1_D", "S1_E"];

    % Open serial port
    sp = serialport(options.COMPort, ...
        options.BaudRate, ...
        "Timeout", 1, ...
        "Parity",options.Parity, ...
        "StopBits",options.StopBits , ...
        "DataBits",options.DataBits, ...
        "FlowControl",options.FlowControl, ...
        'Tag','Contactile Hub');

    % % Create figure with pre-allocated traces
    % fig = uifigure('Color','w','Name','Contactile Listener','Icon','contactile-icon.png',...
    %     'DeleteFcn', @(~,~)handleFigureDeletion(sp));
    % L = uigridlayout(fig,'BackgroundColor','w','ColumnWidth',{'1x'},'RowHeight',{'1x'});
    % ax = uiaxes(L,'NextPlot','add','FontName','Tahoma','FontSize',14,'BusyAction','cancel');
    % ax.YLabel.String = 'Force (N)';
    % ax.YLabel.FontSize = 12;
    % ax.YLabel.FontName = 'Consolas';
    % ax.YLabel.Color = 'k';
    % ax.Title.String = 'Contactile 3D-Forces Button Array';
    % ax.Title.FontSize = 16;
    % ax.Title.FontWeight = 'bold';
    % ax.Title.FontName = 'Consolas';
    % ax.Title.Color = 'k';
    % ax.XColor = 'none';
    % 
    % hLines = gobjects(NUM_CHANNELS, 1);
    % cdata = turbo(NUM_SENSORS);
    % hTxt = gobjects(NUM_SENSORS,1);
    % for ch = 1:NUM_CHANNELS
    %     % Compute the X offset for the current channel
    %     sensorIdx = ceil(ch / 3); % Sensor group
    %     xData = (0:SAMPLES_PER_TRACE-1) + X_OFFSETS(sensorIdx);
    %     yOffset = 20 * (sensorIdx > (NUM_SENSORS / 2)); % Top row offset
    %     hLines(ch) = plot(ax, xData, nan(1, SAMPLES_PER_TRACE), ...
    %         'LineWidth', 1.5, 'UserData', yOffset, 'Color', cdata(sensorIdx,:));
    %     if rem(ch,3)==0
    %         if (sensorIdx > (NUM_SENSORS / 2))
    %             yTxt = yOffset + 15;
    %         else
    %             yTxt = -15;
    %         end
    %         hTxt(sensorIdx) = text(ax, SAMPLES_PER_TRACE/2 + X_OFFSETS(sensorIdx), ...
    %                  yTxt, SENSOR_NAME(sensorIdx), 'Color', cdata(sensorIdx,:), ...
    %                  'FontName','Consolas','FontSize',12,'FontWeight','bold', ...
    %                  'HorizontalAlignment','center','VerticalAlignment','baseline');
    %     end
    % end
    % xlim(ax,[0, X_OFFSETS(1) + SAMPLES_PER_TRACE]);
    % ylim(ax,[-20, 40]); % Adjust Y limits as needed
    % 
    % % Set up UserData
    % sp.UserData = struct(...
    %     'LineHandles', hLines, ...
    %     'SampleIndex', 1, ...
    %     'SensorGain', ones(10,1), ... 
    %     'Labels', hTxt, ...
    %     'SamplesPerTrace', SAMPLES_PER_TRACE);

    % % Synchronize with data stream
    % synchronize_to_frame(sp, HEADER); % Not necessary - it always starts
                                        % the same way.

    % % Configure callback
    % % configureCallback(sp, "byte", FRAME_LENGTH, @(src, ~) process_data_frame(src, FRAME_LENGTH));
    % if options.RunAcquisition
    %     while (isvalid(fig))
    %         try
    %             if sp.NumBytesAvailable > 0
    %                 process_data_frame(sp, sp.NumBytesAvailable);
    %             end
    %         catch
    %             delete(sp);
    %             break;
    %         end
    %     end
    % 
    % end
end

% function handleFigureDeletion(sp)
%     delete(sp);
% end

% function synchronize_to_frame(sp, header)
%     fprintf('Synchronizing to frame...\n');
%     iBuffer = 1;
%     while true
%         % Read one byte at a time
%         byte = read(sp, 1, "uint8");
%         if byte == header(iBuffer)
%             iBuffer = iBuffer + 1;
%         else
%             iBuffer = 1;
%         end
% 
%         % Check for the header
%         if iBuffer > numel(header)
%             fprintf('Frame header found. Synchronization complete.\n');
%             break;
%         end
%     end
% 
%     % Read remaining bytes to complete the first frame
%     extraBytes = 195 - length(header);
%     read(sp, extraBytes, "uint8");
% end

% function process_data_frame(sp, readBytes)
%     % Read the full frame
%     frame = read(sp, readBytes, "uint8");
% 
%     % Extract payload
%     payload = frame(50:end-4);
% 
%     % Parse data
%     numChannels = 30;
%     for ch = 1:numChannels
%         sensorIdx = ceil(ch / 3);
%         channelStart = (ch-1) * 4 + ...
%                        (sensorIdx * 2) + 1;
%         channelEnd = channelStart + 3;
% 
%         % Extract and update data
%         channelData = uint8(payload(channelStart:channelEnd));
%         if (channelData(2)==0xC0) && (channelData(3)==0x7F)
%             channelValue = nan;
%             sp.UserData.Labels(sensorIdx).Visible = matlab.lang.OnOffSwitchState.off;
%         else
%             channelValue = typecast(channelData, 'single');
%             if sp.UserData.Labels(sensorIdx).Visible == matlab.lang.OnOffSwitchState.off
%                 sp.UserData.Labels(sensorIdx).Visible = matlab.lang.OnOffSwitchState.on;
%             end
%         end
%         sp.UserData.LineHandles(ch).YData(sp.UserData.SampleIndex) = channelValue + sp.UserData.LineHandles(ch).UserData; % Adds the Y-Offset
%     end
%     drawnow limitrate;
% 
%     % Increment sample index with wrap-around
%     sp.UserData.SampleIndex = mod(sp.UserData.SampleIndex, sp.UserData.SamplesPerTrace) + 1;
%     % if sp.UserData.SampleIndex == 1
%     %     for ch = 1:3:numChannels
%     %         mag = sqrt((sp.UserData.LineHandles(ch).YData-sp.UserData.LineHandles(ch).UserData).^2 + ...
%     %                    (sp.UserData.LineHandles(ch+1).YData-sp.UserData.LineHandles(ch+1).UserData).^2 + ...
%     %                    (sp.UserData.LineHandles(ch+2).YData-sp.UserData.LineHandles(ch+2).UserData).^2);
%     %         sensorIdx = ceil(ch/3);
%     %         sp.UserData.SensorGain(sensorIdx) = 0.25 ./ nanstd(mag) + 0.75 * sp.UserData.SensorGain(sensorIdx); %#ok<NANSTD>
%     %     end
%     %     disp(sp.UserData.SensorGain);
%     % end
% end
