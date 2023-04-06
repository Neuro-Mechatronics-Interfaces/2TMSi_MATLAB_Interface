function handle_responses_connect_disconnect(self, src, ~)
%HANDLE_RESPONSES_CONNECT_DISCONNECT  Handle tcpclient connection changes on responses TCP server.

if src.Connected
    self.Lamp.Responses.Color = [0.1 0.9 0.1];
else
    self.Lamp.Responses.Color = [0.1 0.1 0.9];
end

end