%DEPLOY__MICROCONTROLLER_LISTENER  Deploys GUI for sending serial commands that generate TTL sync logic on Teensy microcontroller.

config = load_spike_server_config();
fig = init_microcontroller_listener_fig('SerialDevice',config.Default.Teensy_Port);
waitfor(fig);
disp("[MICRO]::Microcontroller listener interface GUI exited.");
pause(1);