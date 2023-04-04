function handle_stream_connect_disconnect(self, src, ~)
%HANDLE_STREAM_CONNECT_DISCONNECT  Pushbutton callback for connections to Stream Server for SAGA-A or SAGA-B (TCP)

tag = src.UserData.tag;
if strcmpi(src.Text, "Connect")
    try
        self.Connection.Stream.(src.UserData.tag) = tcpclient(...
            self.In.StreamHost.Value, ...
            self.In.StreamPort.(tag).Value, ...
            'Timeout', 30);
        self.Connection.Stream.(tag).UserData = struct( ...
            'SAGA_Index', src.UserData.saga ); % Should be 1 (A) or 2 (B)
        self.Connection.Stream.(tag).configureCallback("terminator", ...
            @self.handle_acquisition_stream);
        src.Text = 'Disconnect';
        self.Lamp.Stream.(tag).Color = [0.1 0.9 0.1];
    catch me
        self.Lamp.Stream.(tag).Color = [0.9 0.1 0.1];
        disp(me);
        return;
    end
else
    try
        delete(self.Connection.Stream.(tag));
        src.Text = 'Connect';
        self.Lamp.Stream.(tag).Color = [0.9 0.9 0.9];
    catch me
        disp(me);
        return;
    end
end

end