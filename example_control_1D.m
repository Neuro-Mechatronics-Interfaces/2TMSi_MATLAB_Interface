%EXAMPLE_CONTROL_1D Example of 1D controller GUI

if exist('guiTimer','var')~=0
    stop(guiTimer);
    delete(guiTimer);
end
clear; close all force;

guiTimer = init_1D_tracer_gui();


config = load_spike_server_config();
spikeClient = tcpclient(guiTimer.UserData.TMSiAddress, config.TCP.SpikeServer.Port);
spikeClient.UserData = struct(...
    'Timer', guiTimer, ...
    'ControlChannel', 26, ...
    'SelectedSAGA', 'B', ...
    'CurrentTime', 0, ...
    'Running', true);
addMicrocontrollerToGuiTimer(guiTimer);
% guiTimer.UserData.SpikeClient = spikeClient;
configureCallback(spikeClient, "terminator", @update_value_callback);
% start(guiTimer);