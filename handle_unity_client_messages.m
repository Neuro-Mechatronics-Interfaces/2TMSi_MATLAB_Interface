function handle_unity_client_messages(src, ~)
msg = src.read(1,'char');
switch msg
    case '1'
        write(src.UserData.teensy, msg);
    case '2'
        write(src.UserData.teensy, msg);
    case '3'
        write(src.UserData.teensy, msg);
    case '4'
        src.UserData.n = src.UserData.n + 1;
        disp(src.UserData.n);
    case 'N'
        src.UserData.n = src.UserData.n + 1;
        disp(src.UserData.n);
    % otherwise
    %     disp(msg);
end
end