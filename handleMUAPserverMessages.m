function handleMUAPserverMessages(src, ~)
msg = src.readline();
if strcmpi(msg,"Exit")
    writeline(src,"Exit");
end

end