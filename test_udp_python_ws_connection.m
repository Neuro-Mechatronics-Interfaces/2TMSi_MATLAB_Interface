%TEST_UDP_PYTHON_WS_CONNECTION

% Create UDP socket
udpObj = udpport("IPv4"); % Local port (can be any free port)

% Define server IP & UDP port (MUST match Python's udp_port)
serverIP = "127.0.0.1";
serverPort = 9000;

% Send a test "start recording" message to UDP Python server for MindRove
message = jsonencode(struct('name','start','value','C:/Data/TMSi/Max/Max_2025_03_08_%s_0.tsv')); 
write(udpObj, uint8(message), serverIP, serverPort);
disp("📡 Sent UDP 'start rec' message to Python WebSocket bridge.");

% Send a test "state/value" message to UDP Python server for MindRove
message = jsonencode(struct('name','state','value',num2str(enum.TMSiState.RUNNING))); 
write(udpObj, uint8(message), serverIP, serverPort);
disp("📡 Sent UDP state/value message to Python WebSocket bridge.");

% Send a test "stop recording" message to UDP Python server for MindRove
message = jsonencode(struct('name','stop','value','unused')); 
write(udpObj, uint8(message), serverIP, serverPort);
disp("📡 Sent UDP 'stop' message to Python WebSocket bridge.");

% Close the UDP socket (optional, only if not sending more messages)
clear udpObj;
