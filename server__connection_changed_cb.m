function server__connection_changed_cb(src, evt)
%SERVER__CONNECTION_CHANGED_CB  Indicates that the connection was accepted.
if src.Connected
    fprintf(1, ...
        "\n\nAccepted connection from client at <strong>%s:%d</strong>\n\n", evt.ClientAddress, evt.ClientPort);
    src.UserData.k = 1;
    writeline(src, sprintf("CONNECT.%s", src.UserData.tag));
else
    disp("Client disconnected from server.");
    src.UserData.k = -1;
end
end