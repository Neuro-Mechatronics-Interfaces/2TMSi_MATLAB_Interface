function test_and_save_impedances(device, fname)
%TEST_AND_SAVE_IMPEDANCES  Test and save impedance for arrays connected to device or devices
%
% Syntax:
%   test_and_save_impedances(devices);
%
% Inputs:
%   device - A scalar or array of TMSiSAGA.Device objects
%
% Output:
%   Creates ImpedancePlot for each device in array, and saves them to
%   named output file.

if numel(device) > 1
    for ii = 1:numel(device)
        test_and_save_impedances(device(ii), fname(ii));
    end
    return;
end

CONFIG_IMPEDANCE = struct('ImpedanceMode', true, ... 
                          'ReferenceMethod', 'common', ...
                          'Triggers', false);
CONFIG_CHANNELS = struct('uni',1:64);

% Open a connection to the device
device.connect();

% Update configuration for impedance measurement
device.setDeviceConfig(CONFIG_IMPEDANCE);
device.setChannelConfig(CONFIG_CHANNELS);

% Create a list of channel names that can be used for printing the
% impedance values next to the figure
nCh = length(device.getActiveChannels());
channel_names = cell(nCh, 1);
for i=1:nCh
    channel_names{i}=sprintf('%s: %s', device.tag, device.channels(i).alternative_name);
end

% Create an ImpedancePlot object
iPlot = TMSiSAGA.ImpedancePlot(...
    make_ui_figure(sprintf('HD-EMG Array %s', device.tag)), ...
    2:65, channel_names, 64);

% Start sampling on the device
device.start();

% Remain in impedance mode until the figure is closed
while iPlot.is_visible
    % Sample from device
    [samples, num_sets] = device.sample();

    % Append samples to the plot and redraw need to divide by 10^6.
    if num_sets > 0
        impedance=samples ./ 10^6;
        iPlot.grid_layout(impedance);
    end   
end
try
    delete(iPlot);
catch
    fprintf('[MATLAB] Impedance plot for Device-%s closed.\n', device.tag);
end
device.stop();

[p, ~, ~] = fileparts(fname);
if exist(p, 'dir') == 0
    mkdir(p);
end

% Save the measured impedances.
fprintf(1,'[MATLAB] Saving impedances to file:\n\t<strong>%s</strong>\n', fname);
save(fname, 'impedance', '-v7.3'); % added
fprintf(1,'\t->\tcomplete.\n');

end