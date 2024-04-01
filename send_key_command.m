function send_key_command(srv, btn)
%SEND_KEY_COMMAND  Sends command to server
arguments
    srv
    btn {mustBeMember(btn, {'up', 'down', 'left', 'right', 'a', 'b', 'x', 'y', 'l', 'r'})}
end

% cmd = 'up:0.0,down:0.0,left:0.0,right:0.0,a:0.0,b:0.0,x:0.0,y:0.0,l:0.0,r:0.0';
% cmd = strrep(cmd, sprintf('%s:0.0',btn), sprintf('%s:1.0',btn));

disp(cmd);
if srv.Connected
    writeline(srv, cmd);
end

end