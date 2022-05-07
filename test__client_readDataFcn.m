function test__client_readDataFcn(src, evt)
%TEST__CLIENT_READDATAFCN  Calls read to read BytesAvailableFcnCount number of bytes of data.
assignin('base', 'read_event__client', evt);
s = readline(src);
data = strsplit(s, ".");
switch data{1}
    case "CONNECT"
        src.UserData.tag = data{2};
    otherwise
        error("Unexpected route: <strong>%s</strong> (Full: %s)\n\n", data{1}, s);
end
fprintf(1, "%s::%s::%s\n", src.UserData.tag, string(evt.AbsoluteTime), data{1});

end