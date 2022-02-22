classdef (ConstructOnLoad) ParameterEventData < event.EventData
    %PARAMETEREVENTDATA  Event data class for handling parameters changes.
    properties
        ts                % Serial event current timestamp
        p                 % Current parameters struct
    end
    
    methods
        function data = ParameterEventData(ts, p)
            %PARAMETEREVENTDATA  Event data related to serial interface callbacks
            data.ts = ts;
            data.p = p;
        end
    end
end