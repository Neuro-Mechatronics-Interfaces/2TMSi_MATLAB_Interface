function example__udp_comms()
%EXAMPLE__UDP_COMMS - Test UDP setup for online interaction with wrist task interface.

UDP_STATE_BROADCAST_PORT = 3030;

udp_state_receiver = udpport("byte", ...
    "LocalPort", UDP_STATE_BROADCAST_PORT, ...
    "EnablePortSharing", true);

fprintf(1, "Opened UDP port %s:%d\n", ...
    udp_state_receiver.LocalHost, udp_state_receiver.LocalPort);
flag = false;
try
    while true
        while udp_state_receiver.NumBytesAvailable > 0
            state = readline(udp_state_receiver);
            fprintf(1,'%s -> %s\n', string(datetime('now')), state);
            flag = strcmpi(state, 'quit') || flag;
        end
        if flag
            fprintf(1, '\n\n\t->QUIT keyword received. Exiting.<-\n\n');
            break;
        end
        pause(0.5);
    end
catch
    fprintf(1,'\n\n\t->Script stopped by user.<-\n\n');
end

end