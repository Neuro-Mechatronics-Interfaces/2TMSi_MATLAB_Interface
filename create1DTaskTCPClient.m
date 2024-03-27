function client = create1DTaskTCPClient(timerObj, options)
arguments
    timerObj
    options.Address = "192.168.88.101";
    options.Port = 6054;
end

client = tcpclient(options.Address, options.Port);
client.UserData = struct;
client.UserData.Timer = timerObj;
configureCallback(timerObj.UserData.Client, 'terminator', @handle1DTaskClientCallback);
end