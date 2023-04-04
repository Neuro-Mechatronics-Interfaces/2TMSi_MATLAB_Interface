classdef SubjectMetadata < handle
    %SUBJECTMETADATA  Simple handle class that can be used to notify of subject record metadata changes.

    properties
        SUBJ  (1,1) string      % Subject name
        YYYY  (1,1) double      % Year (scalar numeric)
        MM    (1,1) double      % Month (scalar numeric)
        DD    (1,1) double      % Day (scalar numeric)
        Date  (1,1) datetime    % Date (scalar datetime 'uuuu_MM_dd' format)
        BLOCK (1,1) double      % Block key/index (scalar integer)
    end

    events
        MetaEvent   % Issued any time the tank_2_meta_and_event method is invoked.
    end

    methods
        function obj = SubjectMetadata(config, varargin)
            %SUBJECTMETADATA Construct an instance of this class
            if nargin < 1
                config_file = parameters('config');
                config = parse_main_config(config_file);
            end
            p = inputParser();
            p.addParameter('SUBJ', string(config.Default.Subject), @(in)(ischar(in)||isstring(in)));
            p.addParameter('YYYY', year(today()), @(in)(isscalar(in) && isnumeric(in)));
            p.addParameter('MM', year(today()), @(in)(isscalar(in) && isnumeric(in)));
            p.addParameter('DD', year(today()), @(in)(isscalar(in) && isnumeric(in)));
            p.addParameter('Date', datetime('now', 'Format', 'uuuu_MM_dd'), @(in)(isscalar(in) && isdatetime(in)));
            p.addParameter('BLOCK', 0, @(in)(isscalar(in) && isnumeric(in)));
            p.parse(varargin{:});

            f = fieldnames(p.Results);
            for iF = 1:numel(f)
                obj.(f{iF}) = p.Results.(f{iF});
            end
        end

        function tank_2_meta_and_event(obj, tank)
            %TANK_2_META_AND_EVENT  Convert tank name into metadata and notify of event. Invokes the "MetaEvent" event.
            %
            % Syntax:
            %   subjMetadataObj.tank_2_meta_and_event(tank);
            %
            % Inputs:
            %   tank - The folder that recording "block" files go into
            %           -> e.g. 'Forrest_2023_03_06'
            tank_info = strsplit(tank, '_');
            obj.SUBJ = tank_info{1};
            obj.YYYY = str2double(tank_info{2});
            obj.MM = str2double(tank_info{3});
            obj.DD = str2double(tank_info{4});
            obj.Date = datetime(obj.YYYY, obj.MM, obj.DD, 'Format', 'uuuu_MM_dd');
            notify(obj, "MetaEvent");
        end
    end
end