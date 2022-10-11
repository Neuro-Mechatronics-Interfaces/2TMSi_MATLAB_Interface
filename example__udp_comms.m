%EXAMPLE__UDP_COMMS - Test UDP setup for online interaction with wrist task interface.

udp_state_receiver = udpport("byte", "LocalPort", UDP_STATE_BROADCAST_PORT, "EnablePortSharing", true);

% Create a udpport object udpportObj that uses IPV4 and communicates in byte mode. The
% object is bound to the local host assigned automatically and the local port 3030 with
% port sharing disabled.
udpportObj = udpport("LocalPort",3030);