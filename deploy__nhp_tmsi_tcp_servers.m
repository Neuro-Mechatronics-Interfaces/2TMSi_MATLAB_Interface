% DEPLOY__NHP_TMSI_TCP_SERVERS - For use with windows batch script executable.
disp("Running deploy__tmsi_tcp_servers...");
deploy__tmsi_tcp_servers;
disp("...deployment completed; running in background until all data figures are closed.");
if numel(TAG) == 2
    while any([isvalid(serv__visualizer.A.UserData.app), isvalid(serv__visualizer.B.UserData.app)])
        if udp_extra_receiver.NumBytesAvailable > 0
            
        end
    end
else
    
end