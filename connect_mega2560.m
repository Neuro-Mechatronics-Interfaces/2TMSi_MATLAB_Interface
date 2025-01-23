function mega = connect_mega2560(config,options)
%CONNECT_MEGA2560 Returns serial connection to MEGA2560 device based on config struct.
%
% Syntax:
%   mega = connect_mega2560(config);
%   mega = connect_mega2560(...,'Name',value,..);
%
% Example 1:
%   config = load_gestures_config();
%   mega = connect_mega2560(config.Gestures.Serial);
%
% Example 2:
%   mega = connect_mega2560('SerialDevice',"COM7",'BaudRate',250000);
%
% See also: load_gestures_config, deploy__gestures2_gui

arguments
    config struct = struct.empty;
    options.SerialDevice {mustBeTextScalar} = "";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger} = 250000;
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
                mega = serialport(sList{ii}, baud, 'Tag', "MEGA2560");
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
        mega = [];
        warning("No serial devices detected! Sync signal will not be sent on Recording start/stop.");
    else
        mega = serialport(sList, baud, 'Tag', 'MEGA2560');
    end
else
    mega = serialport(port, baud, 'Tag', 'MEGA2560');
end

end