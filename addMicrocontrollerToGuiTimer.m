function addMicrocontrollerToGuiTimer(timerObj, options)

arguments
    timerObj
    options.BaudRate (1,1) double {mustBeInteger, mustBePositive} = 115200;
    options.Port {mustBeTextScalar} = "COM3";
end

timerObj.UserData.Teensy = serialport(options.Port, options.BaudRate);

end