function transferBinaryToTeensy(serialPort, binaryFile)
arguments
    serialPort (1,1) string % COM port for Teensy
    binaryFile (1,1) string {mustBeFile} % Path to the binary file
end

% Open the serial port
s = serialport(serialPort, 115200);
configureTerminator(s, "LF");
pause(2); % Allow Teensy to initialize

% Read the binary file
fid = fopen(binaryFile, 'rb');
fileData = fread(fid, '*uint8');
fclose(fid);

% Display start message
fprintf('Sending %d bytes to Teensy...\n', numel(fileData));

% Send file data
write(s, fileData, "uint8");
pause(1); % Give Teensy time to write to SD card

% Read confirmation from Teensy
while s.NumBytesAvailable > 0
    msg = readline(s);
    disp(msg);
end

% Close the serial port
clear s;

disp('File transfer complete!');
end
