classdef (ConstructOnLoad) SAGA_EventData < event.EventData
    %SAGA_EVENTDATA  Event data class for notifying about SAGA status using small text files and a worker pool monitoring them.
    properties
        ts                  % Timestamp (see Microcontroller.convert_to_Mats_ts_format)
        type                % Is this a "Connect" or "Disconnect" event?
    end
    
    methods
        function data = SAGA_EventData(ts, type)
            %SAGA_EVENTDATA  Event data class for notifying about SAGA status using small text files and a worker pool monitoring them.
            data.type = type;
            data.ts = ts;
        end
    end
end