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
src.UserData.(lower(info{1})) = info{2};

end