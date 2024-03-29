function server__DEV_read_data_cb(src, evt)
%SERVER__DEV_READ_DATA_CB  Read callback for DEVICE server.
assignin('base', 'read_event', evt);
fprintf(1, "%s::%s::READ::%d\n", src.UserData.tag, string(evt.AbsoluteTime), src.UserData.k);
src.UserData.index = rem(src.UserData.index, 12)+1;
src.UserData.k = rem(src.UserData.k, 32768)+1;
src.UserData.samples = membrane(src.UserData.index) + reshape(read(src,src.BytesAvailableFcnCount/8,"double"), 31, 31);
try
    set(src.UserData.surface, 'ZData', src.UserData.samples, 'CData', src.UserData.samples);
catch
    disp("Figure closed manually.");
end
    
end