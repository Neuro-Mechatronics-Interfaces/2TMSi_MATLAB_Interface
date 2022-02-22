function fast_save_impedance(device, fname)
%FAST_SAVE_IMPEDANCE  Take impedance measurement and save quickly.

if numel(device) > 1
    for ii = 1:numel(device)
        fast_save_impedance(device(ii), fname(ii));
    end
    return;
end

CONFIG_IMPEDANCE = struct('ImpedanceMode', true, ... 
                          'ReferenceMethod', 'common', ...
                          'Triggers', false);
CONFIG_CHANNELS = struct('uni',1:64);

% Open a connection to the device
if ~device.is_connected
    device.connect();
else
    if device.is_sampling
        device.stop();
    end
end

% Update configuration for impedance measurement
device.setDeviceConfig(CONFIG_IMPEDANCE);
device.setChannelConfig(CONFIG_CHANNELS);
% Start sampling on the device
device.start();

% Remain in impedance mode until the figure is closed
% Sample from device
[samples, num_sets] = device.sample();
while num_sets == 0
    [samples, num_sets] = device.sample();
end
impedance=samples ./ 10^6;
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