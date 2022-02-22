classdef (ConstructOnLoad) RecordingEventData < event.EventData
    properties
        ts                % Serial event current timestamp
        n_stims_per_train % Number of stimuli per train
        key               % Parameter key index
        type              % Which recording event data type is this?
    end
    
    methods
        function data = RecordingEventData(ts, type, key, n_stims_per_train)
            %RECORDINGEVENTDATA  Event data related to serial interface callbacks
            data.ts = ts;
            data.type = type;
            data.key = key;
            data.n_stims_per_train = n_stims_per_train;
        end
    end
end