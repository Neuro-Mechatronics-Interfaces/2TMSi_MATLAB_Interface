% MATLAB Script to send a message using udpport
host = '127.0.0.1';  % Target IP address (loopback for local testing)
port = 12000;        % Target port (must match Python listener)

% Create the udpport object
udpSender = udpport('IPv4', 'LocalPort', 0);  % Bind to any available local port

% Send a message
write(udpSender, "Hello from MATLAB via udpport", "string", host, port);

% Cleanup
clear udpSender;
