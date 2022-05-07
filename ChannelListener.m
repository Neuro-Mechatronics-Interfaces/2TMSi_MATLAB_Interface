classdef ChannelListener < handle
   
    properties (GetAccess = public, SetAccess = protected)
        array       string  % "A" or "B"
        channel     double  % Scalar channel index
        udp                 % udpport object
    end
    
    properties (Access = protected)
        port    double = 9090; 
    end
    
    methods
        function obj = ChannelListener(channel, array, port)
            obj.channel = channel;
            obj.array = array;
            if nargin > 2
                obj.port = port; 
            end
            obj.udp = udpport("LocalPort", port, "LocalHost", sprintf('TMSiSAGA.%s', array));
        end
    end
    
end