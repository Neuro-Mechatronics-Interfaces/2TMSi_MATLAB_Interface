function param = setup_or_teardown_triggers_socket_connection(param)
%SETUP_OR_TEARDOWN_TRIGGERS_SOCKET_CONNECTION  Sets up or tears down connection to websocket server.
try %#ok<*TRYNC>
    delete(param.mouse.client);
end
try
    delete(param.gamepad.client);
end
if param.enable_trigger_controller
    is_connected_yet = false;
    while (~is_connected_yet)
        if (param.emulate_mouse)
            try
                param.gamepad.client = tcpclient(param.gamepad.address, param.gamepad.port);
                param.mouse.client = tcpclient(param.mouse.address, param.mouse.port);
                is_connected_yet = true;
            catch
                fprintf(1,'[TMSi]::[InputUtilities]::Could not connect to server (%s, ports %d and %d). Waiting 15 seconds and retrying...\n', param.gamepad.address, config.TCP.InputUtilities.Port.Gamepad, param.mouse.port);
                fprintf(1,'[TMSi]::[InputUtilities]::     --> (You may need to run `xbox_emulator_server_with_mouse.exe --console` on host server device)\n');
                pause(15);
            end
        else
            try
                param.gamepad.client = tcpclient(param.gamepad.address, param.gamepad.port);
                param.mouse.client = [];
                is_connected_yet = true;
            catch
                fprintf(1,'[TMSi]::[InputUtilities]::Could not connect to server (%s, ports %d and %d). Waiting 15 seconds and retrying...\n', param.gamepad.address, param.gamepad.port, param.mouse.port);
                fprintf(1,'[TMSi]::[InputUtilities]::     --> (You may need to run controller_input_server.exe --console` on host server device)\n');
                pause(15);
            end
        end
    end
else
    param.gamepad.client = [];
    param.mouse.client = [];
end
end