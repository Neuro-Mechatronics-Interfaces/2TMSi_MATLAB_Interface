% DEPLOY__NHP_TMSI_TCP_SERVERS - For use with windows batch script executable.
disp("Running deploy__tmsi_tcp_servers...");
deploy__tmsi_tcp_servers;
disp("...deployment completed; running in background until all data figures are closed.");
for ii = 1:numel(my_tags)
    waitfor(fig.(my_tags{ii}));
end