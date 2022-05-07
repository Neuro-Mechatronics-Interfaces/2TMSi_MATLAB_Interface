classdef TMSiProvider < matlab.net.http.io.ContentProvider
    %TMSIPROVIDER  Basic content provider for TMSi streaming data.
    
    properties
        data double
    end
    
    methods
        function obj = TMSiProvider(dataBufferHandle)
            obj.data = dataBufferHandle;
        end
        
        function [data, stop] = getData(obj, length)
            [data, len] = fread(obj.FileID, length, '*uint8');
            stop = len < length;
            if (stop)
                fclose(obj.FileID);
                obj.FileID = [];
            end
        end
        
        function delete(obj)
            if ~isempty(obj.FileID)
                fclose(obj.FileID);
                obj.FileID = [];
            end
        end
    end
end