function collectAndForwardStream(src, evt)
msg = jsondecode(readline(src));
src.UserData.HasData.(msg.SAGA) = 1;
src.UserData.Message.Time = posixtime(datetime(evt.AbsoluteTime));
src.UserData.Samples.(msg.SAGA) = msg.data;
if (src.UserData.HasData.A + src.UserData.HasData.B) == 2
    tmp = [src.UserData.Samples.A; src.UserData.Samples.B];
    tmp(isnan(tmp)) = 0;
    if isfield(src.UserData,'Bar')
        src.UserData.Bar.YData = tmp';
    end
    src.UserData.Message.Data = [src.UserData.X * tmp; src.UserData.Y * tmp];
    if src.UserData.Unity.ControllerServer.Connected
        writeline(src.UserData.Unity.ControllerServer, jsonencode(src.UserData.Message));
    end
    src.UserData.HasData.A = 0;
    src.UserData.HasData.B = 0;
end
end