function run_test_controller_client(client, options)
%RUN_TEST_CONTROLLER_CLIENT  Issue sequence of test commands to NES/SNES emulator interface. 
arguments
    client
    options.N = 100;
    options.PauseDuration = 1.5;
end

for ii = 1:options.N
    writeline(client, 'y0');
    writeline(client, '60');
    pause(options.PauseDuration);
    writeline(client, '61');
    writeline(client, '40');
    pause(options.PauseDuration);
    writeline(client, '41');
    writeline(client, 'Y1');
end

end