javaaddpath('C:\Program Files\Force Dimension\sdk-3.17.1\extensions\Java\classes\forcedimension-sdk.jar');

dhd = javaObject('com.forcedimension.sdk.DHD');
drd = javaObject('com.forcedimension.sdk.DRD');


% Open a connection to the first available device
if drd.Open() < 0
    disp(['Error: Cannot open device (' char(DHD.GetLastErrorString()) ')']);
    return;
end

% Assign device ID for haptic control functions
dhd.SetDeviceID(drd.GetDeviceID());

% Initialize the device if needed
if ~drd.IsInitialized() && (drd.AutoInit() < 0)
    disp(['Error: Initialization failed (' char(DHD.GetLastErrorString()) ')']);
    return;
end

% Start robot control loop
if drd.Start() < 0
    disp(['Error: Control loop failed to start (' char(DHD.GetLastErrorString()) ')']);
    return;
end

% Set up the plot
fig = figure('Color','w','Name','Force Dimension Forces Readout', ...
    'Units','inches','Position',[2 1 8 5]);
ax = axes(fig,'NextPlot','add','FontSize',14,'FontName','Tahoma','Grid','on', ...
    'YColor','none','XColor','none','XLim',[1 4000],'YLim',[-75 150]);
plot.add_scale_bar(ax, 1, -75, 2001, -25, ...
    'XUnits', 's', 'XLabelScaleFactor', 1/2000, 'YUnits', 'mN');
title(ax,'Real-Time Force Data','FontName','Tahoma','Color','k');
xlabel(ax, 'Time (samples)','FontName','Tahoma','Color','k');
ylabel(ax, 'Force (N)','FontName','Tahoma','Color','k');
% Preallocate arrays to store data
nSamples = 4000; % Number of samples to store
time = 1:nSamples;
forceX = zeros(1, nSamples);
forceY = zeros(1, nSamples);
forceZ = zeros(1, nSamples);

% Initialize plot handles
hX = plot(ax, time, forceX, 'r', 'DisplayName', 'Force X');
hY = plot(ax, time, forceY, 'g', 'DisplayName', 'Force Y');
hZ = plot(ax, time, forceZ, 'b', 'DisplayName', 'Force Z');
legend(ax,'Location','eastoutside');

% Start acquisition loop
while isvalid(fig)
    % Get the force data
    force = dhd.GetForce();
    
    % Shift the data to make room for the new sample
    forceX = circshift(forceX, -1);
    forceY = circshift(forceY, -1);
    forceZ = circshift(forceZ, -1);
    
    % Append new sample
    forceX(end) = force(1);
    forceY(end) = force(2);
    forceZ(end) = force(3);
    
    % Update the plots
    set(hX, 'YData', forceX);
    set(hY, 'YData', forceY + 50);
    set(hZ, 'YData', forceZ + 100);
    
    % Pause to control update rate
    pause(0.01); % Adjust as needed for smoother plotting
end

% Close connection when done
DHD.Close(deviceId);
