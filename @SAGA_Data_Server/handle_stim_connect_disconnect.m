function handle_stim_connect_disconnect(self, src, ~)
%HANDLE_STIM_CONNECT_DISCONNECT  Pushbutton callback for connections to Stim Server (TCP)
if strcmpi(src.Text, "Connect")
    try
        self.Connection.Stim = tcpclient(...
            self.In.StimServerHost.Value, ...
            self.In.StimServerPort.Value, ...
            'Timeout', 30);
        self.Connection.Stim.configureCallback("terminator", ...
            @self.handle_message_from_stim_controller);
        src.Text = 'Disconnect';
        self.Lamp.StimServer.Color = [0.1 0.9 0.1];
    catch me
        disp(me);
        return;
    end
else
    try
        delete(self.Connection.Stim);
        src.Text = 'Connect';
        self.Lamp.StimServer.Color = [0.9 0.9 0.9];
    catch me
        disp(me);
        return;
    end
end
end