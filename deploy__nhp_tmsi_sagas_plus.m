% DEPLOY__NHP_TMSI_SAGAS_PLUS - For use with windows batch script executable to deploy the TMSi SAGA device streams.
fprintf(1,"[DEPLOY]::[TMSi-Streams-Plus] Running deploy__tmsi_stream_service_plus_spike_detection_plus_gui.m...\n");
try
    deploy__tmsi_stream_service_plus_spike_detection_plus_gui;
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
            fprintf(1,"[DEPLOY]::[TMSi-Streams-Plus] Could not create tcpclient object!\n");  
			pause(10);
        otherwise
            disp(me.message);
            pause(2);
            fprintf(1,"[DEPLOY]::[TMSi-Streams-Plus] Waiting 10 seconds before shutdown...\n");
            pause(10);
    end
end
fprintf(1,"\n\n[DEPLOY]::[TMSi-Streams-Plus] Exiting TMSi stream service.\n");
