% DEPLOY__NHP_TMSI_SAGAS - For use with windows batch script executable to deploy the TMSi SAGA device streams.
disp("Running deploy__tmsi_stream_service...");
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
            disp("Could not create tcpclient object!");            
        otherwise
            disp(me.message);
            pause(2);
            disp("Waiting 15 seconds before shutdown...");
            pause(15);
    end
end
disp("Exiting TMSi stream service.");
