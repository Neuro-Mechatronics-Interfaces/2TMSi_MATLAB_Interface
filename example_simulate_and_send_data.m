%EXAMPLE_SIMULATE_AND_SEND_DATA Synthesizes data and sends it to Unity

close all force;
clear;
clc;

MESSAGE_RATE = 100; % Hz

config = load_spike_server_config();
unityControllerSocket = tcpserver("0.0.0.0",config.TCP.UnityControllerServer.Port);
unityControllerSocket.ConnectionChangedFcn = @(~,evt)disp(evt);

unityStateSocket = tcpserver("0.0.0.0",config.TCP.UnityStateServer.Port);

timerObj = timer('TimerFcn',@send_simulated_data, ...
    'ExecutionMode','FixedRate', ...
    'Period',round(1/MESSAGE_RATE,3));
timerObj.UserData = struct('theta',0,'srv',unityControllerSocket);

%timerObj.start();