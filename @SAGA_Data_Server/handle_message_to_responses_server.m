function handle_message_to_responses_server(self, src, ~)
%HANDLE_MESSAGE_TO_RESPONSES_SERVER  Handle incoming messages from tcpclient to Response Data tcpserver

message = src.readline();
in = jsondecode(message);

switch in.type
    case 'mep.request'
        k = double(strcmpi(in.tag, 'B'));
        ch = k*68 + in.channel;
        i_match = (self.meta_data(:,3)==in.focusing) & (self.meta_data(:,4)==in.amplitude);

        resp = msg.json_data_server_response(in.tag, in.channel, in.focusing, in.amplitude, ...
            self.t, ...
            squeeze(self.sample_data(ch, :, i_match)), ... % data samples (nSamples x nTrials)
            self.meta_data(i_match,1)', ... % x (mm)
            self.meta_data(i_match,2)');    % y (mm)
        resp_message = jsonencode(resp);
        src.writeline(resp_message);

end

end