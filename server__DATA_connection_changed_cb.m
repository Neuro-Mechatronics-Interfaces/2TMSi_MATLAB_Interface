function server__DATA_connection_changed_cb(src, ~)
%SERVER__DATA_CONNECTION_CHANGED_CB  For handling connection changes (DATA server).

if src.Connected
    if isstruct(src.UserData)
        if isfield(src.UserData, 'app')
            if ~isempty(src.UserData.app)
                if isvalid(src.UserData.app)
                    src.UserData.app.DataConnectionStatusLamp.Color = [0.39,0.83,0.07];
                end
            end
        end
    end            
else
    if isstruct(src.UserData)
        if isfield(src.UserData, 'app')
            if ~isempty(src.UserData.app)
                if isvalid(src.UserData.app)
                    src.UserData.app.DataConnectionStatusLamp.Color = [0.65,0.65,0.65];
                end
            end
        end
    end  
end
end