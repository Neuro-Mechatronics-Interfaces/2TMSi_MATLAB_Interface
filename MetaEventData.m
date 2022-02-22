classdef (ConstructOnLoad) MetaEventData < event.EventData
    properties
        ts                % Serial event current timestamp
        type              % Type of metadata event
        n_stims           % Number of stimulus trains in this sequence so far
        n_stims_per_train % Number of stimuli per train
        key               % Parameter key index
        interface         % "TMSi" or "Ripple"
    end
    
    methods
        function data = MetaEventData(ts, type, n_stims, n_stims_per_train, key, interface)
            %METAEVENTDATA  Event data related to serial interface callbacks
            data.ts = ts;
            data.type = type;
            data.n_stims = n_stims;
            data.n_stims_per_train = n_stims_per_train;
            data.key = key;
            data.interface = interface;
        end
    end
end