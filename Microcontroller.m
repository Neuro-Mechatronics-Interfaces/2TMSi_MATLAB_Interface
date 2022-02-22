classdef Microcontroller < handle
    %MICROCONTROLLER  Run Serial COM interface from Ripple-controller PC to the microcontroller interfacing to TMSi acquisition.
    %
    % Syntax:
    %   obj = Microcontroller(type);
    %   obj = Microcontroller(type, com_port, name);
    %   obj = Microcontroller(__, 'Name', value);
    %
    % Inputs:
    %   type     - String that is either "TMSi" or "Ripple"
    %   com_port - (Recommended) String that is the known COM port
    %               to connect (e.g. "COM7").
    %                   Note: If this is not provided, we try
    %                         to connect to the last device in the
    %                         list of COM ports output by
    %                         `serialportlist`. Since that is not
    %                         guaranteed to find the correct
    %                         device, it is recommended to specify
    %                         this value manually (I am too lazy to
    %                         write a proper "handshake" for the
    %                         device code).
    %   name     - (Optional) Name of your microcontroller
    %               interface. This is totally useless currently.
    %   varargin - (Optional) 'Name', value
    
    properties (GetAccess=public, SetAccess=protected)
        Name             % Name of the interface (default: "Microcontroller Interface")
        Type             % Either "TMSi" or "Ripple"
        running = false  % Is a stimulus train/recording running? (default: false)
        parameters = struct('Key', 0, 'Progress', 0, 'PatternName', "Stim", 'Current', 0, 'NumberTrials', 20, 'PulseWidth', 0, 'PulseRepetitionTime', inf, 'TrainFrequency', 0, 'TrainPulseNumber', 0, 'PulseBiphasic', 0); % Current parameter set (empty array or table)
    end
    
    properties (Hidden, Access=public)
        s         % Contains the serialport MATLAB object
        fid = []  % ID to log file created when this object is created
        tic       % Start "tic" for "toc" references
        flags = struct('init', false) % Flags struct
    end
    
    events
        StimEvent           % Events associated to each stimulus pulse train
        RecordingEvent      % Events associated with recording onset/end/pause etc.
        MetaEvent           % Other experiment-related metadata
        ParameterEvent      % Events associated with parameter changes
    end
    
    methods
        function obj = Microcontroller(type, com_port, name, varargin)
            %MICROCONTROLLER  Run Serial COM interface from Ripple-controller PC to the microcontroller interfacing to TMSi acquisition.
            %
            % Syntax:
            %   obj = Microcontroller(type);
            %   obj = Microcontroller(type, com_port, name);
            %   obj = Microcontroller(__, 'Name', value);
            %
            % Inputs:
            %   type     - String that is either "TMSi" or "Ripple"
            %   com_port - (Recommended) String that is the known COM port
            %               to connect (e.g. "COM7").
            %                   Note: If this is not provided, we try
            %                         to connect to the last device in the
            %                         list of COM ports output by
            %                         `serialportlist`. Since that is not
            %                         guaranteed to find the correct
            %                         device, it is recommended to specify
            %                         this value manually (I am too lazy to
            %                         write a proper "handshake" for the
            %                         device code).
            %   name     - (Optional) Name of your microcontroller
            %               interface. This is totally useless currently.
            %   varargin - (Optional) 'Name', value
            if nargin < 2
                com_port = serialportlist;
                com_port = com_port(end);
            end
            if nargin < 3
                name = "Microcontroller Interface";
            end
            type = string(type);
            if ~ismember(type, ["TMSi", "Ripple"])
                error('First input must be "TMSi" or "Ripple".');
            end
            obj.Type = type;
            obj.Name = name;
            obj.s = serialport(com_port, 115200, "Timeout", 60, varargin{:});
            obj.tic = tic;
            try
                obj.s.writeline('init');
                word = obj.s.readline();
            catch me
                db.print_error_message(me);
                delete(obj.s);
                fprintf(1,'Handshake unsuccessful.\n');
                return;
            end
            if contains(word, type)
                obj.flags.init = true;
            else
                delete(obj.s);
                fprintf(1,'Handshake keyword was incorrect (was "%s"; should be "%s")\n', word, type);
                return;
            end
            
            switch obj.Type
                case "TMSi"
                    configureCallback(obj.s, "Terminator", @obj.awaitWord_TMSiSide);
                case "Ripple"
                    configureCallback(obj.s, "Terminator", @obj.awaitWord_RippleSide);
                otherwise
                    error('Should not reach this point.');
            end
            obj.fid = fopen(sprintf('logs/%s_%s_Logs.txt', obj.Type, ...
                string(datetime('now', 'Format', 'yyyy_MM_dd_HH-mm-ss'))), 'w');
        end
        
        function delete(obj)
            %DELETE  Overloaded delete method that closes serial port.
            
            % Try to delete the serialport object.
            try
                delete(obj.s);
            catch me
                disp('Could not delete serialport object!');
                disp(me);
            end
            
            % Try to close the log file
            try
                if ~isempty(obj.fid)
                    fclose(obj.fid);
                end
            catch me
                disp('Could not close log file!');
                disp(me);
            end
        end
        
        function note(obj, str)
            %NOTE  Make a note in the logs that is sync'd to other system.
            obj.write(sprintf('notify:%s', str));
            obj.log(str);
        end
        
        function reset(obj)
            %RESET  Reset the current experiment tracker.
            obj.write('reset');
        end
        
        function readyForStims(obj)
            %READYFORSTIMS  Method to indicate software is ready for stim train
            %
            % Syntax:
            %   obj.readyForStims();
            %   --> Should produce 'rs' over Serial, which turns into
            %       "ReadyForStims" `type` RecordingEventData event.
            obj.write('rs');
        end
        
        function readyForParams(obj)
            %READYFORPARAMS  Method to indicate software is ready for new parameter string
            %
            % Syntax:
            %   obj.readyForParams();
            %   --> Should produce 'rp' over Serial, which turns into
            %       "ReadyForParams" `type` RecordingEventData event.
            obj.write('rp');
        end
        
        function setStimCount(obj, n)
            %SETSTIMCOUNT  Override the current number of stims counted.
            %
            % Syntax:
            %    obj.setStimCount(n);
            %
            % Inputs:
            %    n: Number of trains per block.
            obj.parameters.Progress = n;
            obj.setParams();
        end
        
        function setParameterKey(obj, key)
            %SETPARAMETERKEY  Set the current parameter key "index"
            %
            % Syntax:
            %    obj.setParameterKey(key);
            %
            % Inputs:
            %    key - Integer value of the desired parameter key
            obj.parameters.Key = key;
            obj.setParams();
        end
        
        function setParams(obj, key, nStims, patternName, current, numberTrials, pulseWidth, pulseRepetitionTime, trainFrequency, trainPulseNumber, pulseBiphasic)
            %SETPARAMS  Notifies other devices of new stim parameter values associated with current key.
            %
            % Syntax:
            %   obj.setParams( ...
            %       key, ...                 % Integer
            %       nStims, ...              % Integer | "Progress" (number of stims so far)
            %       patternName, ...         % STRING
            %       current, ...             % Float
            %       numberTrials, ...        % Integer
            %       pulseWidth, ...          % Float
            %       pulseRepetitionTime, ... % Float
            %       trainFrequency, ...      % Float
            %       trainPulseNumber, ...    % Integer
            %       pulseBiphasic);          % Integer
            if nargin > 1
                obj.parameters = struct( ...
                    'Key', key, ...
                    'Progress', nStims, ...
                    'PatternName', patternName, ...
                    'Current', current, ...
                    'NumberTrials', numberTrials, ...
                    'PulseWidth', pulseWidth, ...
                    'PulseRepetitionTime', pulseRepetitionTime, ...
                    'TrainFrequency', trainFrequency, ...
                    'TrainPulseNumber', trainPulseNumber, ...
                    'PulseBiphasic', pulseBiphasic);
            end
            obj.write(sprintf('stimconfig:Key=%d;Progress=%d;PatternName=%s;Current=%.2f;NumberTrials=%d;PulseWidth=%.3f;PulseRepetitionTime=%.2f;TrainFrequency=%.2f;TrainPulseNumber=%d;PulseBiphasic=%d', ...
                obj.parameters.Key, ...
                obj.parameters.Progress, ...
                obj.parameters.PatternName, ...
                obj.parameters.Current, ...
                obj.parameters.NumberTrials, ...
                obj.parameters.PulseWidth, ...
                obj.parameters.PulseRepetitionTime, ...
                obj.parameters.TrainFrequency, ...
                obj.parameters.TrainPulseNumber, ...
                obj.parameters.PulseBiphasic));
        end
        
        function updateLocalParams(obj, key, nStims, patternName, current, numberTrials, pulseWidth, pulseRepetitionTime, trainFrequency, trainPulseNumber, pulseBiphasic)
            %UPDATELOCALPARAMS  Updates parameters on local object instance (only).
            %
            % Syntax:
            %   obj.updateLocalParams( ...
            %       key, ...                 % Integer
            %       nStims, ...              % Integer | "Progress" (number of stims so far)
            %       patternName, ...         % STRING
            %       current, ...             % Float
            %       numberTrials, ...        % Integer
            %       pulseWidth, ...          % Float
            %       pulseRepetitionTime, ... % Float
            %       trainFrequency, ...      % Float
            %       trainPulseNumber, ...    % Integer
            %       pulseBiphasic);          % Integer
            %
            % This is useful only the case of initializing local device
            % with some arbitrary parameter set, which will be passed in a
            % subsequent interaction via `setParams`, for example.
            
            obj.parameters = struct( ...
                'Key', key, ...
                'Progress', nStims, ...
                'PatternName', patternName, ...
                'Current', current, ...
                'NumberTrials', numberTrials, ...
                'PulseWidth', pulseWidth, ...
                'PulseRepetitionTime', pulseRepetitionTime, ...
                'TrainFrequency', trainFrequency, ...
                'TrainPulseNumber', trainPulseNumber, ...
                'PulseBiphasic', pulseBiphasic);

        end
    end
    
    methods (Access=protected)
        function awaitWord(obj, word)
            %AWAITWORD  Shared part of callback for TMSi/Ripple controller
            
            if strncmpi(word, 'reset', 5)
                obj.parameters.Progress = 0;
                ts = obj.log(word);
                data = MetaEventData(ts, "Reset", obj.parameters.Progress, obj.parameters.NumberTrials, obj.parameters.Key, obj.Type);
                notify(obj, "MetaEvent", data);
            elseif strncmpi(word, 'n:', 2)
                [~, obj.parameters.NumberTrials] = Microcontroller.parse_integer(word);
                ts = obj.log(word);
                data = MetaEventData(ts, "Train", obj.parameters.Progress, obj.parameters.NumberTrials, obj.parameters.Key, obj.Type);
                notify(obj, "MetaEvent", data);
            elseif strncmpi(word, 'key:', 4)
                [~, obj.parameters.Key] = Microcontroller.parse_integer(word);
                ts = obj.log(word);
                data = MetaEventData(ts, "Key", obj.parameters.Progress, obj.parameters.NumberTrials, obj.parameters.Key, obj.Type);
                notify(obj, "MetaEvent", data);
            elseif strncmpi(word, 'stim', 4) && (numel(char(word)) < 7)
                obj.parameters.Progress = obj.parameters.Progress + 1;
                ts = obj.log(word);
                data = StimEventData(ts, obj.parameters.Progress, obj.parameters.Key);
                notify(obj, "StimEvent", data);
            elseif strncmpi(word, 'start', 5)
                obj.parameters.Progress = 0;
                obj.running = true;
                ts = obj.log(word);
                data = RecordingEventData(ts, "Start", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            elseif strncmpi(word, 'stop', 4)
                ts = obj.log(word);
                obj.running = false;
                obj.parameters.Key = obj.parameters.Key + 1;
                data = RecordingEventData(ts, "Stop", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            elseif strncmpi(word, 'pause', 5)
                ts = obj.log(word);
                obj.running = false;
                data = RecordingEventData(ts, "Pause", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            elseif strncmpi(word, 'resume', 6)
                ts = obj.log(word);
                obj.running = true;
                data = RecordingEventData(ts, "Resume", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            elseif strncmpi(word, 'stimconfig:', 11)
                ts = obj.log(word);
                word = char(word);
                params = obj.parseParameterString(word(12:end));
                data = ParameterEventData(ts, params);
                assignin('base', 'db_params', params);
                notify(obj, "ParameterEvent", data);
            elseif strncmpi(word, 'rs', 2)
                ts = obj.log(word);
                data = RecordingEventData(ts, "ReadyForStim", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            elseif strncmpi(word, 'rp', 2)
                ts = obj.log(word);
                data = RecordingEventData(ts, "ReadyForParams", obj.parameters.Key, obj.parameters.NumberTrials);
                notify(obj, "RecordingEvent", data);
            else
                ts = obj.log(word);
                data = MetaEventData(ts, "Note", obj.parameters.Progress, obj.parameters.NumberTrials, obj.parameters.Key, obj.Type);
                notify(obj, "MetaEvent", data);
            end
            
        end
        
        function awaitWord_TMSiSide(obj, src, ~)
            %AWAITWORD_TMSISIDE  Callback for TMSi controller interface
            %
            %  Attach this to the Microcontroller object on the TMSi
            %  computer side. This gets added in the constructor by
            %  default, based on the "type" input argument.
            
            word = readline(src);
            obj.awaitWord(word);
        end
        
        function awaitWord_RippleSide(obj, src, ~)
            %AWAITWORD_RIPPLESIDE  Callback for Ripple controller interface
            %
            %  Attach this to the Microcontroller object on the Ripple
            %  computer side. This gets added in the constructor by
            %  default, based on the "type" input argument.
            
            word = readline(src);
            obj.awaitWord(word);
        end
        
        function currentParams = parseParameterString(obj, str)
            %PARSEPARAMETERSTRING  Parses parameters from input string
            %
            % Syntax:
            %    currentParams = obj.parseParameterString(str);
            %
            % Inputs:
            %    str  - String that is a 'param1=value1;param2=value2' ...
            %            syntax char array that indicates different
            %            parameters used during stimulation.
            %
            % Output:
            %    currentParams - Struct that is of same format as the
            %                        `parameters` property of this object.
            currentParams = obj.parameters;
            tmp = strsplit(str, ';');
            for iParam = 1:numel(tmp)
                key_value_pair = strsplit(tmp{iParam}, '=');
                if strcmpi(key_value_pair{1}, 'patternname')
                    currentParams.(key_value_pair{1}) = string(key_value_pair{2});
                else
                    currentParams.(key_value_pair{1}) = str2double(key_value_pair{2});
                end
            end
            obj.parameters = currentParams;
        end
        
        function ts = log(obj, str)
            %LOG  Logs the value to some logging file (with timestamp).
            ts = Microcontroller.convert_to_Mats_ts_format(default.now());
            fprintf(1, '[ts:%s]\t[key:%d]\t[stim:%d]\t%s\n', ts, obj.parameters.Key, obj.parameters.Progress, str);
            fprintf(obj.fid, '[ts:%s]\t[key:%d]\t[stim:%d]\t%s\n', ts, obj.parameters.Key, obj.parameters.Progress,  str);
        end
        
        function write(obj, word)
            %WRITE  Send a message to the Serial Microcontroller interface.
            %
            % Syntax:
            %    obj.write(word);
            %
            % Inputs:
            %    word - String or char array
            obj.s.writeline(char(word));
        end
    end
    
    methods (Static, Access=public)
        function ts = convert_to_Mats_ts_format(ts)
            %CONVERT_TO_MATS_TS_FORMAT  Convert to Mats preferred timestring
            ts = strrep(strrep(strrep(string(ts), '-', ''),' ','T'), ':', '');
        end
        
        function [key, value] = parse_integer(word)
            %PARSE_INTEGER  Parse integer from serial keyword pair
            %
            % Syntax:
            %   N = Microcontroller.parse_integer(word);
            %
            % Inputs:
            %   word - Char array that is some 'key:[integer]' text value.
            %
            % Output:
            %   key   - Key word (string).
            %   value - Value associated to the key (numeric scalar).
            tmp = strsplit(word, ':');
            try
                key = string(tmp{1});
            catch me
                db.print_error_message(me);
                key = "missing";
            end
            try
                value = floor(str2double(tmp{2}));
            catch me
                db.print_error_message(me);
                value = 0;
            end
        end
    end
end

