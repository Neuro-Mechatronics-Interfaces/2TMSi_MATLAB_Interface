% DEPLOY__NHP_TMSI_SAGAS - For use with windows batch script executable to deploy the TMSi SAGA device streams.
fprintf(1,"[DEPLOY]::[TMSi-Streams] Running deploy__tmsi_stream_service...\n");
try
    deploy__tmsi_stream_service;
catch me
    try %#ok<TRYNC> 
        disconnect(device);
        lib.cleanUp();
    end
    switch me.identifier
        case 'MATLAB:networklib:tcpclient:cannotCreateObject'
            disp(me.message);
            pause(2);
            for ii = 1:numel(me.stack)
                disp(me.stack(ii));
                pause(1);
            end
            pause(2);
            fprintf(1,"[DEPLOY]::[TMSi-Streams] Could not create tcpclient object!\n");            
        otherwise
            disp(me.message);
            pause(2);
            fprintf(1,"[DEPLOY]::[TMSi-Streams] Waiting 60 seconds before shutdown...\n");
            pause(60);
    end
end
fprintf(1,"\n\n[DEPLOY]::[TMSi-Streams] Exiting TMSi stream service.\n");
