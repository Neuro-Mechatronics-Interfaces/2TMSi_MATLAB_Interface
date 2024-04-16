%EXAMPLE_UNITY_TCP Set up a TCP connection with Unity for exchanging state (from the Unity game) and sending control messages (to the Unity game).

% close all force;
% clear;
clc;

config = load_spike_server_config();

% streamClient = tcpclient(config.TCP.SpikeServer.Address, config.TCP.SpikeServer.Port);
% streamClient.UserData = struct('Message', struct('Name', 'Rate', 'Time', 0, 'Data', [0, 0]));
% streamClient.UserData.X = [ones(1,64)./64, zeros(1,64)];
% streamClient.UserData.Y = [zeros(1,64), ones(1,64)./64];

load('GridWH.mat','W','H');
streamClient = tcpclient(config.TCP.RMSServer.Address, config.TCP.RMSServer.Port);
streamClient.UserData = struct('Message', struct('Name', 'RMS', 'Time', 0, 'Data', [0, 0]),'Index',0);
% streamClient.UserData.X = zeros(1,136);
% streamClient.UserData.Y = zeros(1,136);
% streamClient.UserData.X(4) = 1;
% streamClient.UserData.X(71) = -1;
% streamClient.UserData.Y(101) = 1;
% streamClient.UserData.Y(63) = -1;
% streamClient.UserData.X = mean(W(:,[1,4,6]),2)';
% streamClient.UserData.Y = mean(W(:,[5,7]),2)';
% streamClient.UserData.Data = zeros(136,1000);

% streamClient = tcpclient(config.TCP.MUAPServer.Address, config.TCP.MUAPServer.Port);
% streamClient.UserData = struct('Message', struct('Name', 'MUAPs', 'Time', 0, 'Data', [0, 0]);


% unityStateServer = tcpserver(...
%     "0.0.0.0", ...
%     config.TCP.UnityStateServer.Port);
% configureCallback(unityStateServer, ...
%     "terminator", @(src,~)disp(readline(src)));
% 
% unityControllerServer = tcpserver(...
%     "0.0.0.0", ...
%     config.TCP.UnityControllerServer.Port);
% streamClient.UserData.Unity = struct(...
%     'StateServer', unityStateServer, ...
%     'ControllerServer', unityControllerServer);
streamClient.UserData.HasData = struct('A', 0, 'B', 0);
streamClient.UserData.Samples = struct('A',[],'B',[]);

fig = figure; 
ax = axes(fig,'NextPlot','add'); 
% streamClient.UserData.Bar = bar(ax,1:136,zeros(1,136));
streamClient.UserData.H = imagesc(ax, zeros(8,16));

% configureCallback(streamClient, "terminator", @collectAndSaveStream);
% configureCallback(streamClient, "terminator", @collectAndForwardStream);
configureCallback(streamClient, "terminator", @heatmapCallback);

