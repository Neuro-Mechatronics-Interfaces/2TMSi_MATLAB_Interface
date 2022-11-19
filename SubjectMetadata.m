classdef SubjectMetadata < handle
    %SUBJECTMETADATA  Simple handle class that can be used to notify of subject record metadata changes.

    properties
        SUBJ  (1,1) string = "Default";
        YYYY  (1,1) double = year(today());
        MM    (1,1) double = month(today());
        DD    (1,1) double = day(today());
        Date  (1,1) datetime = datetime("today");
        BLOCK (1,1) double = 0;
    end

    events
        MetaEvent
    end

    methods
        function obj = SubjectMetadata(varargin)
            %SUBJECTMETADATA Construct an instance of this class
            for iV = 1:2:numel(varargin)
                obj.(varargin{iV}) = varargin{iV+1};
            end
        end

        function tank_2_meta_and_event(obj, tank)
            %TANK_2_META_AND_EVENT  Convert tank name into metadata and notify of event.
            tank_info = strsplit(tank, '_');
            obj.SUBJ = tank_info{1};
            obj.YYYY = str2double(tank_info{2});
            obj.MM = str2double(tank_info{3});
            obj.DD = str2double(tank_info{4});
            obj.Date = datetime(obj.YYYY, obj.MM, obj.DD);
            notify(obj, "MetaEvent");
            fprintf(1,'\t\tSubjectMetadata object updated.\n\n');
        end
    end
end