classdef (ConstructOnLoad) ConnectionEventData < event.EventData
    %CONNECTIONEVENTDATA  Event data class for notifying about new connections.
    properties
        type                % Is this a "Connect" or "Disconnect" event?
        port                % Which COM port are we on
    end
    
    methods
        function data = ConnectionEventData(type, port)
            %CONNECTIONEVENTDATA  Event data class for notifying about new connections.  
            data.type = type;
            data.port = port;
        end
    end
end