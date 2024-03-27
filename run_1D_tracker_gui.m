%RUN_1D_TRACKER_GUI  Runs tracker GUI for 1D target tracking task
clear; close all force; clc;
guiTimer = init_1D_tracer_gui('Subject', 'MCP01', 'Block', 100);
addMicrocontrollerToGuiTimer(guiTimer);
% addNotesToTimer(guiTimer, "Add notes like this!");

clientFor1DTracker = create1DTaskTCPClient(guiTimer, ...
    "Address", "192.168.88.101", "Port", 6054);

% start(guiTimer);