% MATLAB UDP Data Outlet
% This script sends synthetic sinusoid data to 127.0.0.1:10101 continuously.

% Configuration
udpOutlet = udpport("IPv4", "LocalPort", 10101);
destinationAddress = "127.0.0.1";
destinationPort = 10101;
fs = 2000; % Sampling rate in Hz
% t = 0:1/fs:1; % Time vector (1-second window for example)
freq = 10; % Frequency of sinusoid
amplitude = 1;
fig = figure('Name','Keep Alive Synth Sinusoid','Color','k'); % Control figure for stopping the loop

tPrev = 0;
synthTic = tic();
disp("Starting UDP data stream...");
pause(0.1);
while isvalid(fig) % Keep running while figure is valid
    tCur = toc(synthTic);
    t = tPrev : (1/fs) : tCur;
    tPrev = tCur;
    % Generate synthetic sinusoid chunk
    % signalChunk = amplitude * sin(2 * pi * freq * t);
    signalChunk = abs(randn(1,numel(t)).*5);
    
    % Convert to bytes and send via UDP
    dataBytes = typecast(single(signalChunk), 'uint8'); % Convert float32 to byte array
    write(udpOutlet, dataBytes, "uint8", destinationAddress, destinationPort);
    
    % Sleep to simulate real-time streaming
    pause(0.1);
end

disp("Stopping UDP data stream...");
clear udpOutlet; % Clean up the UDP port
