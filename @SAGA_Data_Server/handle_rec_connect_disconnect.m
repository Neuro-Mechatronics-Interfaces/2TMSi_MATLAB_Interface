function handle_rec_connect_disconnect(self, src, ~)
%HANDLE_REC_CONNECT_DISCONNECT  Pushbutton callback for connections with RECORDING server (TCP).
if strcmpi(src.Text, "Connect")
    try
        self.Connection.Rec = tcpclient(...
            self.In.TMSiServerHost.Value, ...
            self.In.TMSiServerPort.Value, ...
            'Timeout', 30);
        self.Connection.Rec.configureCallback("terminator", ...
            @self.handle_message_from_rec_controller);
        src.Text = 'Disconnect';
        self.Lamp.TMSiServer.Color = [0.1 0.9 0.1];
    catch me
        disp(me);
        return;
    end
else
    try
        delete(self.Connection.Rec);
        src.Text = 'Connect';
        self.Lamp.TMSiServer.Color = [0.9 0.9 0.9];
    catch me
        disp(me);
        return;
    end
end
end