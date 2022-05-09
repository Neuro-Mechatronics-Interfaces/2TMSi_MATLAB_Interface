function server__CON_read_data_cb(src, ~)
%SERVER__CON_READ_DATA_CB  Read callback for CONTROLLER server.
%
% This callback function should handle routing of different string
% requests. The syntax for client methods should be:
%
%   value = string(sprintf("%s.%s", field, val));
%   writeline(client, value);
%
% Where client is a tcpclient object connected to this tcpserver.
%   -> field -- the UserData struct field of this server to write to
%   -> val   -- The value (string) to send to that field
%
% Note that all fields are auto lower-case so take that into consideration
% when setting up tcpserver object UserData. The value is not auto
% lower-case'd and just uses the string from readline. 
%
% Current fields:
%   -> 'state'  : "idle" (default) | "run" | "rec" | "quit"
%   -> 'datashare' : Should be wherever you want to save data when state is
%                   "rec". 
%   -> 'tank' : This is auto-parsed if you use
%               client__set_rec_name_metadata so please refer to that
%               function but basically it's the datashare subfolder that
%               recordings go into.
%   -> 'block' : Should be a string, but this is typically "0", "1", ... etc.
%               to key you into some metadata table where each row contains
%               various metadata entries on whatever is relevant to your
%               experiment...
%   -> 'file' : Should be whatever you want for the filename prefix when
%               state is "rec". The full filename will be:
%                   >> fname = sprintf("%s_%s",server.UserData.file,...
%                                                server.UserData.id);
%                   >> fullfile(server.UserData.folder, fname);
%   
% DISCLAIMER: 
%   -> I don't pretend to understand IT security etc. etc. -- use my shitty
%           code at your own risk! <-

data = readline(src);
info = strsplit(data, '.');
switch string(lower(info{1}))
    case "set"
        f = strtrim(string(lower(info{2})));
        if ismember(class(src.UserData.(f)), ["string", "char"])
            val = string(strtrim(info{3}));
            src.UserData.(f) = val;
            switch f
                case "state"  % Then broadcast the state change.
                    src.UserData.udp.write([char(src.UserData.state) 10], ...
                        "string", src.UserData.address, src.UserData.port.state);
                case "file"
                    src.UserData.udp.write([char(fullfile(src.UserData.datashare, src.UserData.file)) 10], ...
                        "string", src.UserData.address, src.UserData.port.name);
                otherwise
                    src.UserData.udp.write([char(sprintf("%s.%s", info{2}, info{3})) 10], ...
                        "string", src.UserData.address, src.UserData.port.extra); 
            end
            fprintf(1, "CONTROLLER::SET::%s=%s\n", f, val);
        else
            fprintf(1, "CONTROLLER::SET::INVALID=%s\n", data);
            return;
        end
    case "get"
        switch string(strtrim(lower(info{2})))
            case "prop"
                f = strtrim(string(lower(info{3})));
                if ismember(class(src.UserData.(f)), ["string", "char"])
                    writeline(src, src.UserData.(f));
                else
                    fprintf(1, "CONTROLLER::GET::INVALID=%s\n", data);
                    return;
                end
            case "recv"
                
            otherwise
                fprintf(1, "CONTROLLER::GET::INVALID=%s\n", data);
                return;
        end
    otherwise
        error("Bad syntax on server request.");
end
end