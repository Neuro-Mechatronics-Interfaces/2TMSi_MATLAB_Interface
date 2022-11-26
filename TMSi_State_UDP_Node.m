classdef TMSi_State_UDP_Node < handle
    %TMSI_STATE_UDP_NODE Class with simple UDP interface to TMSis

    properties
        % block - Recording block index
        %   Numeric value, typically 0-indexed.
        %   Set by sending UDP messages with syntax block.(value)
        block  (1,1) double = 0;
        % flags - Logical flags struct
        %   Struct with logical fields: 'new_block', 'new_folder', 'new_state', 'new_subject'
        flags (1,1) struct = struct('new_block', false, 'new_folder', false, 'new_state', false, 'new_subject', false);
        % folder - The location containing the saved output "subject" folder.
        %   Set by sending UDP messages with syntax folder.(value)
        folder (1,1) string = "R:/NMLShare/raw_data/primate";
        % meta - Struct with miscellaneous metadata
        %   Set by sending UDP messages using syntax meta.(fieldname).(value)
        meta struct
        % state - State of the recording
        %   See enumerated possibilities in TMSiState enumeration class.
        %   Set by sending UDP messages with syntax state.(value)
        state  (1,1) TMSiState = TMSiState("IDLE");
        % subject - The subject being recorded
        %   E.g. "Spencer" or "Rupert"
        %   Set by sending UDP messages with syntax subject.(value)
        subject (1,1) string = "Default";
    end

    properties (Access = protected)
        logger (1,1) mlog.Logger = mlog.Logger('TMSi');
        udp_   (1,1) struct = struct('broadcaster', [], 'receiver', []);
    end

    methods
        function self = TMSi_State_UDP_Node(varargin)
            %TMSI_STATE_UDP_NODE Class with simple UDP interface to TMSis
            %
            % Syntax:
            %  obj = TMSi_State_UDP_Node();
            %  obj = TMSi_State_UDP_Node('Name', value, ...);
            %
            % Inputs:
            %   varargin - (Optional) 'Name',value pairs:
            %       - 'Broadcaster_Address': "128.2.245.255" (default CNBC)
            %          -- check netreg > 
            %               [your device] >> 
            %               'machine configuration information' >>>
            %               broadcast address
            %       - 'Broadcaster_Port': 3011   (default)
            %       - 'Receiver_Address': "0.0.0.0" (default)
            %       - 'Receiver_Port': 3010 (default)
            %   See: pars struct at top of constructor.

            pars = struct;
            pars.block = 0;
            pars.folder = "R:/NMLShare/raw_data/primate";
            pars.state = TMSiState("IDLE");
            pars.subject = "Default";
            pars.Broadcaster_Address = "128.2.245.255";
            pars.Broadcaster_Port = 3011;
            pars.Receiver_Address = "0.0.0.0"; % Set to "127.0.0.1" to only listen on local loopback; 0.0.0.0 listens to all incoming UDP messages to a specified port.
            pars.Receiver_Port = 3010;

            f = fieldnames(pars);
            for ii = 1:2:numel(varargin)
                idx = strcmpi(f, varargin{iV});
                if sum(idx) == 1
                    pars.(f{idx}) = varargin{iV+1};
                end
            end
            self.configure_udp_broadcaster(pars.Broadcaster_Address, pars.Broadcaster_Port);
            self.configure_udp_receiver(pars.Receiver_Address, pars.Receiver_Port);   
            
            self.block = pars.block;
            self.folder = pars.folder;
            self.state = pars.state;
            self.subject = pars.subject;
        end

        function delete(self)
            try %#ok<TRYNC> 
                delete(self.udp_.broadcaster);
            end
            try %#ok<TRYNC> 
                delete(self.udp_.receiver);
            end
        end
        
        function clear_flags(self)
            %CLEAR_FLAGS  Set all flags to false
            %
            % Syntax:
            %   self.clear_flags();
            self.flags = struct('new_block', false, 'new_folder', false, 'new_state', false, 'new_subject', false);
        end

        function configure_udp_broadcaster(self, address, port)
            %CONFIGURE_UDP_BROADCASTER  Configure UDP broadcaster port object
            %
            % The sender port will only be used to "forward" messages
            % depending on how the receiver callback is configured. If
            % using the default configuration
            % (TMSi_State_UDP_Node.default_udp_callback) then only "block",
            % "folder", "state", and "subject" setter messages are
            % forwarded on.
            %
            % Syntax:
            %   self.configure_udp_broadcaster(address, port);
            %
            % Inputs:
            %   address - IP, e.g. "128.2.245.255" (default CNBC)
            %               -- check netreg > 
            %                       [your device] >> 
            %                       'machine configuration information' >>>
            %                       broadcast address
            %   port    - Port for local receiver UDP port
            
            if ~isempty(self.udp_.broadcaster)
                try %#ok<TRYNC> 
                    delete(self.udp_.broadcaster);
                end
            end
            self.udp_.broadcaster = udpport('LocalPort', port, 'EnablePortSharing', true);
            self.udp_.broadcaster.UserData = address;
            self.udp_.broadcaster.EnableBroadcast = true;
        end

        function configure_udp_receiver(self, address, port, callback_fcn)
            %CONFIGURE_UDP_RECEIVER  Configure UDP receiver port/callback
            %
            % Use this to change what port/address you are listening on
            % and/or if you have a modified callback you'd like to use (see
            % `TMSi_State_UDP_Node.default_udp_callback` method for
            % callback structure).
            %
            % Syntax:
            %   self.configure_udp_receiver(address, port);
            %   self.configure_udp_receiver(address, port, callback_fcn);
            %
            % Inputs:
            %   address - IP address for local receiver UDP port
            %   port    - Port for local receiver UDP port
            
            if ~isempty(self.udp_.receiver)
                try %#ok<TRYNC> 
                    delete(self.udp_.receiver);
                end
            end
            if nargin < 4
                callback_fcn = @self.default_udp_callback;
            end
            self.udp_.receiver = udpport('LocalHost', address, 'LocalPort', port, 'EnablePortSharing', true);
            self.udp_.receiver.configureCallback("terminator", callback_fcn);
        end

    end

    methods (Hidden)
        function default_udp_callback(self, src, ~)
            %DEFAULT_UDP_CALLBACK  Handles "set" messages sent to TMSi controller server.
            while src.NumBytesAvailable > 0
                data = readline(src);
                self.logger.debug(sprintf("Received::%s", data));
                info = strsplit(string(data), '.');
                p = strtrim(info(1));
                v = strtrim(info(2));
                switch p
                    case "block"
                        b = str2double(v);
                        self.block = b;
                        self.flags.new_block = true;
                        self.logger.info(sprintf("Set::block=%d", b));
                    case "folder"
                        self.folder = v;
                        self.flags.new_folder = true;
                        self.logger.info(sprintf("Set::folder=%s", v));
                    case "meta"
                        m = strtrim(info(3));
                        self.meta.(v) = m;
                        self.logger.info(sprintf("Set::meta.%s=%s", v, m));
                    case "state"
                        s = upper(v);
                        self.state = TMSiState(s);
                        self.flags.new_state = true;
                        self.logger.info(sprintf("Set::state=TMSiState('%s')", s));
                    case "subject"
                        self.subject = v;
                        self.flags.new_subject = true;
                        self.logger.info(sprintf("Set::subject=%s", v));
                    otherwise
                        self.logger.error(sprintf("Unhandled::%s", data));
                        return;
                end
                self.udp_.broadcaster.writeline(data, self.udp_.broadcaster.UserData, self.udp_.broadcaster.LocalPort);
                self.logger.debug(sprintf("Broadcasted::%s", data));
            end
        end
    end
end