classdef (ConstructOnLoad) SampleEventData < event.EventData
    %SAMPLEEVENTDATA  Issued when the data frame fills up.
    
    properties
        data    StreamBuffer
        array   string        % "A" | "B" depending on which SAGA device it is
    end
    
    methods
        function evt = SampleEventData(data, array)
            %SAMPLEEVENTDATA  Issued when the data frame fills up.
            evt.data = data;          
            evt.array = array;
        end
    end
end