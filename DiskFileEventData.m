classdef (ConstructOnLoad) DiskFileEventData < event.EventData
    properties
        ts                % Serial event current timestamp
        type              % Which recording event data type is this?
    end
    
    methods
        function data = DiskFileEventData(ts, type)
            %DISKFILEEVENTDATA  Event data related to serial interface callbacks
            data.ts = ts;
            data.type = type;
        end
    end
end