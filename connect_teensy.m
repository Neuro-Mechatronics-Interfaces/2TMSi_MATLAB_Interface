function teensy = connect_teensy(config,options)
%CONNECT_TEENSY Connects to Teensy microcontroller to write sync bits.
%
% Syntax:
%   teensy = connect_teensy(config);
%   teensy = connect_teensy(...,'Name',value,...);
%
% Inputs:
%   config - (Optional) struct with fields 'Port' and 'Baud'
%
% Output:
%   teensy - Microcontroller serialport object.

arguments
    config struct = struct.empty;
    options.SerialDevice {mustBeTextScalar} = "";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger} = 115200;
end

if isempty(config)
    port = options.SerialDevice;
    baud = options.BaudRate;
else
    port = config.Port;
    baud = config.Baud;
end

if strlength(port) < 1
    sList = serialportlist();
    if numel(sList) > 1
        for ii = 1:numel(sList)
            try
                teensy = serialport(sList{ii}, baud, 'Tag', "TEENSY");
                fprintf(1,"Detected multiple serial devices. Connected to device on PORT: '%s' with compatible BAUD=%d\n", ...
                    sList{ii}, baud);
                return;
            catch 
                fprintf(1,"Detected multiple serial devices. Failed connection with device on PORT: '%s' (incompatible BAUD=%d)\n", ...
                    sList{ii}, baud);
            end
        end
        error("Multiple serial devices detected (but no compatible BAUD!): ['%s']\n\t->\tSpecify correct device using SerialDevice option.", strjoin(sList,"'; '"));
    elseif numel(sList) < 1
        teensy = [];
        warning("No serial devices detected! Sync signal will not be sent on Recording start/stop.");
    else
        teensy = serialport(sList, baud, 'Tag', 'TEENSY');
    end
else
    teensy = serialport(port, baud, 'Tag', 'TEENSY');
end

end