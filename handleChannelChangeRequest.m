function handleChannelChangeRequest(src,~)
% new_channel = str2double(readline(src));
msg = readline(src);
if startsWith(msg, '{')
    data = jsondecode(msg);
else
    if strcmpi(msg,"Exit")
        writeline(src,"Exit");
    end
    return;
end
if (data.Channel > 0) && (data.Channel <= 64)
    src.UserData.current_channel = data.Channel;
    src.UserData.has_new_channel = true;
end

end