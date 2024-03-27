function handle1DTaskClientCallback(src, ~)
%HANDLE1DTASKCLIENTCALLBACK Callback for client listening to 1D control messages. 
data = jsondecode(readline(src));
src.UserData.Timer.UserData.Value(src.UserData.Timer.UserData.CurrentTime) = data.value(1);
end