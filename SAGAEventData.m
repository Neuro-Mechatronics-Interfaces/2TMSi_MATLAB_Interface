classdef (ConstructOnLoad) SAGAEventData < event.EventData
    %SAGAEVENTDATA  Event data class for notifying about SAGA status using small text files and a worker pool monitoring them.
    properties
        ts                  % Timestamp (see Microcontroller.convert_to_Mats_ts_format)
        type                % Is this a "Connect" or "Disconnect" event?
    end
    
    methods
        function data = SAGAEventData(ts, type)
            %SAGAEVENTDATA  Event data class for notifying about SAGA status using small text files and a worker pool monitoring them.
            data.type = type;
            data.ts = ts;
        end
    end
end