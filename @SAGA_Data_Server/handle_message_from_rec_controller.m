function handle_message_from_rec_controller(self, src, ~)
%HANDLE_MESSAGE_FROM_REC_CONTROLLER  Handles incoming message from RECORDING server (TCP), received by the connected client (Connection.Rec)
message = src.readline();
data = jsondecode(message);
switch data.type
    case 'state.tmsi'
        if ismember(data.state, ["run", "rec"])
            self.Stimulus = self.Stimulus + 1;
            
            self.update_experiment_text('block', data.block);
            [x,y,focus] = self.parse_queued_pattern();
            
            new_data = msg.json_stim_response(self.Stimulus, data.state, data.block, x, y, focus);
            new_message = jsonencode(new_data);
            if ~isempty(self.Connection.Stim) && isvalid(self.Connection.Stim)
                self.pattern_logger.info(new_message);
                self.Connection.Stim.writeline(new_message);
            else
                self.pattern_logger.info(message);
            end
        else
            self.pattern_logger.info(message);
            if ~isempty(self.Connection.Stim) && isvalid(self.Connection.Stim)
                new_data = msg.json_stim_response(self.Stimulus, data.state, data.block, nan, nan, nan);
                new_message = jsonencode(new_data);
                self.Connection.Stim.writeline(new_message);
            end
        end

end
end