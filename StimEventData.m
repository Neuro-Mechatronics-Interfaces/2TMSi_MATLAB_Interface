classdef (ConstructOnLoad) StimEventData < event.EventData
    properties
        ts                % Serial event current timestamp
        n_stims           % Number of stimulus trains in this sequence so far
        key               % Parameter key index
    end
    
    methods
        function data = StimEventData(ts, n_stims, key)
            %SERIALEVENTDATA  Event data related to serial interface callbacks
            data.ts = ts;
            data.n_stims = n_stims;
            data.key = key;
        end
    end
end