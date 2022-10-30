classdef SAGA_State_Machine
    %SAGA_STATE_MACHINE Tracks the run/record/impedance/idle state of SAGA
    %   Detailed explanation goes here
    
    properties (Access = public)
        buffer
        buffer_listener
        n
        flag = struct('recording', false, 'running', false);
        port = struct('name', [], 'state', [], 'parameters', [], 'visualizer', [], 'worker', [])
        state = struct('packet', "US", 'device', "idle")
    end
    
    properties (Access = protected)
        config 
    end
    
    methods
        function self = SAGA_State_Machine(config, ch, tag)
            %SAGA_STATE_MACHINE Construct an instance of this class
            %   Detailed explanation goes here
            
            self.n = numel(tag);
            self.config = config;
            
            self.port.visualizer = cell(1, self.n);
            for ii = 1:self.n
                self.port.visualizer{ii} = tcpclient(config.Server.Address.TCP, config.Server.TCP.(device(ii).tag).Viewer);
            end
            self.port.visualizer = vertcat(self.port.visualizer{:});
            if config.FSM.Use_Worker_Port
                self.port.worker = cell(1, self.n);
                for ii = 1:self.n
                    self.port.worker{ii} = tcpclient(config.Server.Address.TCP, config.Server.TCP.(device(ii).tag).Worker);
                end
                self.port.worker = vertcat(self.port.worker{:});
            end
            
            self.port.state = udpport("byte", "LocalPort", config.Server.UDP.state, "EnablePortSharing", true);
            self.port.name = udpport("byte", "LocalPort", config.Server.UDP.name, "EnablePortSharing", true);
            if config.FSM.Use_Parameters_Port
                self.port.parameters = udpport("byte", "LocalPort", config.Server.UDP.extra, "EnablePortSharing", true);
            end
            
            channels = struct('A', config.SAGA.A.Channels, ...
                              'B', config.SAGA.B.Channels);
            self.buffer = cell(1, self.n); 
            for ii = 1:self.n
                self.buffer{ii} = StreamBuffer(ch{ii}, channels.(tag(ii)).self.n.samples, tag(ii), config.Default.Sample_Rate);
            end
            self.buffer = vertcat(self.buffer{:});

            self.buffer_listener = cell(1, self.n);
            for ii = 1:self.n
                self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, self.port.visualizer(ii), (1:64)'));
            end
            self.buffer_listener = vertcat(self.buffer_listener{:});
        end
        
        function delete(self)
            try %#ok<TRYNC>
                for ii = 1:numel(self.buffer_listener)
                    delete(self.buffer_listener(ii)); 
                end
            end
            
        end
        
        function fname = check_for_name_update(self)
            if self.port.name.NumBytesAvailable > 0
                tmp = self.port.name.readline();
                if startsWith(strrep(tmp, "\", "/"), self.config.Default.Folder)
                    fname = tmp;
                else
                    fname = strrep(fullfile(self.config.Default.Folder, tmp), "\", "/"); 
                end
                fprintf(1, "File name updated: <strong>%s</strong>\n", fname);
            end
        end
        
        function check_for_parameter_update(self)
            if self.config.FSM.Use_Parameters_Port
                if self.port.parameters.NumBytesAvailable > 0
                    tmp = self.port.parameters.readline();
                    info = strsplit(tmp, '.');
                    if ~strcmpi(info{1}, self.state.packet)
                        fprintf(1, "Detected switch in packet mode from '%s' to --> '%s' <--\n", packet_mode, tmp);
                        self.state.packet = info{1};
                        for ii = 1:self.n
                            delete(self.buffer_listener(ii)); 
                        end
                        self.buffer_listener = cell(1, self.n);
                        switch self.state.packet
                            case 'US'
                                i_subset = double(info{2}) - 96;
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer(ii), i_subset));
                                end
                                fprintf(1, "Configured for unipolar stream data.\n");
                            case 'BS'
                                i_subset = double(info{2}) - 96;
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer(ii), i_subset));
                                end
                                fprintf(1, "Configured for bipolar stream data.\n");
                            case 'UA'
                                i_subset = double(info{2}) - 96;
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer(ii), i_subset));                                end
                                fprintf(1, "Configured for unipolar averaging data.\n");
                            case 'BA'
                                i_subset = double(info{2}) - 96;
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer(ii), i_subset));
                                end
                                fprintf(1, "Configured for bipolar averaging data.\n");
                            case 'UR'
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer(ii)));
                                end
                                fprintf(1, "Configured for unipolar raster data.\n");
                            case 'IR'
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer(ii)));
                                end
                                fprintf(1, "Configured for ICA raster data.\n");
                            case 'RC'
                                for ii = 1:self.n
                                    self.buffer_listener{ii} = addlistener(self.buffer(ii), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer(ii)));
                                end
                                fprintf(1, "Configured for RMS contour data.\n");
                            otherwise
                                fprintf(1,"Unrecognized requested packet mode: %s", packet_mode);
                        end
                        self.buffer_listener{ii} = vertcat(self.buffer_listener{:});        

                    end
                end
            end
        end
    end
end

