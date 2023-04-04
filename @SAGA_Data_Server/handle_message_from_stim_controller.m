function handle_message_from_stim_controller(self, src, ~)
%HANDLE_MESSAGE_FROM_STIM_CONTROLLER  Handles incoming message from STIM server (TCP), received by the connected client (Connection.Stim)
message = src.readline();
data = jsondecode(message);
switch data.type
    case 'stim.pattern' % Relay the pattern to the Recording Controller
        self.Queued.Stim = data;
        if ~isempty(self.Connection.Rec) && isvalid(self.Connection.Rec)
            self.Connection.Rec.writeline(message);
        else
            error_data = msg.json_stim_response(self.Stimulus, "disconnected", -1);
            error_message = jsonencode(error_data);
            src.writeline(error_message);
        end
end
end