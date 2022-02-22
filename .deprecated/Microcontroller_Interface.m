classdef Microcontroller_Interface < handle
    %MICROCONTROLLER_INTERFACE  Run Serial COM interface from Ripple-controller PC to the microcontroller interfacing to TMSi acquisition.
    
    properties (GetAccess=public, SetAccess=protected)
        Name  % Name of the interface
        Type  % Either "TMSi" or "Ripple"
    end
    
    properties (Hidden, Access=public)
        s     % Contains the serialport MATLAB object
    end
    
    methods
        function obj = Microcontroller_Interface(type, com_port, name, varargin)
            %MICROCONTROLLER_INTERFACE  Run Serial COM interface from Ripple-controller PC to the microcontroller interfacing to TMSi acquisition.
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
            obj.s = serialport(com_port, 1200, "Timeout", 5, varargin{:});
            obj.s.UserData = Microcontroller_Interface.init_serial_data();
            try
                obj.s.flush();
            catch me
                disp(me);
                warning('Error while trying to flush %s port.', com_port);
            end
            switch obj.Type
                case "TMSi"
                    configureCallback(obj.s, "Terminator", @callback.awaitControllerWord);
                case "Ripple"
                    configureCallback(obj.s, "Terminator", @callback.awaitControllerWord);
                otherwise
                    error('Should not reach this point.');
            end
        end
        
        function begin(obj)
            %BEGIN  Begin the experiment session
            callback.setTransmittingState(obj.s); 
            obj.s.writeline('start'); 
            while awaiting_confirmation(obj)
                pause(0.5); % Wait for confirmation from other PC
            end
        end
        
        function next(obj)
            %NEXT  Advance experiment session to the NEXT parameter set and start recording
            switch obj.s.UserData.state
                case ExperimentState.AWAITING_COMPLETION
                    obj.s.writeline('stop');
                    while awaiting_confirmation(obj)
                        pause(0.5); % Wait for confirmation from other PC
                    end
                    obj.s.UserData.ts.start = [obj.s.UserData.ts.start; default.now()];
                otherwise
                    fprintf(1, "Cannot advance to NEXT recording (current state is <strong>%s</strong>)\n", ...
                        string(obj.s.UserData.state));
            end
        end
        
        function shutdown(obj)
            %SHUTDOWN  Finish the experiment session
            obj.s.writeline('end');
            while experiment_running(obj)
                pause(0.5); % Wait for a second, then check again.
            end
        end
        
        function delete(obj)
            % Try to indicate to serialport and any listening interface
            % that they should shut down.
            try 
                obj.s.writeline('end');
            catch me
                disp(me);
            end
            
            % Try to delete the serialport object.
            try
                delete(obj.s);
            catch me
                disp(me);
            end
        end
        
        function write(obj, word)
           %WRITE  Writes some control word to the interface
           if ~(obj.experiment_running)
               Microcontroller_Interface.logger("Session has ended. Reset interface to continue.");
               return;
           end
           word = char(word);
           obj.s.writeline(word);
        end
        
        function reset(obj)
            %RESET  Reset the interface
            try
                flush(obj.s);
            catch me
                disp(me);
                warning(1, 'Could not flush serialport data!\n');
                return;
            end
            obj.s.UserData = Microcontroller_Interface.init_serial_data();
            configureCallback(obj.s, "Terminator", @callback.awaitControllerWord);
        end
        
        function tf = experiment_running(obj)
            %EXPERIMENT_RUNNING  Return true if experiment in progress, false if ExperimentState.COMPLETE has been reached.

            tf = obj.s.UserData.state ~= ExperimentState.COMPLETE;
        end
        
        function tf = awaiting_confirmation(obj)
            %AWAITING_CONFIRMATION  Return true only if message has been received.
            tf = obj.s.UserData.state ~= ExperimentState.AWAITING_RESPONSE;          
        end
    end

    methods (Static, Access=protected)
        function userdata = init_serial_data()
            userdata = struct(...
                'state', ExperimentState.INITIALIZING, ...
                'triggers', struct( ...
                    'next', "start", ...
                    'bounce', "stop", ...
                    'received', "received", ...
                    'quit', "end" ...
                ), ...
                'messages', struct( ...
                    'on_bounce', "bounced:idle", ...
                    'on_success', "received" ...
                ), ...
                'db_messages', struct( ...
                    'on_success', "Received <strong>START</strong> recording signal.", ...
                    'on_quit', "Received <strong>END</strong> signal. Shutting down...", ...
                    'on_received', "Request <strong>RECEIVED</strong>.", ...
                    'on_bounce', "Received <strong>STOP</strong> signal before recording was started!" ...
                ), ...   
                'next', struct( ...
                    'on_success', @callback.setRunningState, ...
                    'on_quit', @callback.endSession, ...
                    'key', 0 ...
                ), ...
                'key', [], ...
                'ts', struct( ...
                    'begin', default.now(),...
                    'start', datetime.empty, ...
                    'stop', datetime.empty, ...
                    'finish', datetime.empty ...
                ), ...
                'data', [] ...
            ); 
        end
    end
    
    methods (Static)
        function logger(str)
            fprintf(1, '[%s]\t%s\n', default.now(), str); 
        end
    end
end

