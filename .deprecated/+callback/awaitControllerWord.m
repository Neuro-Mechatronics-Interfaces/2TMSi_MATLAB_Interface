function awaitControllerWord(src, ~)

% Read the ASCII data from the serialport object.
word = readline(src);
if strcmpi(word, src.UserData.triggers.next)
    Microcontroller_Interface.logger(src.UserData.db_messages.on_success);
    src.UserData.next.on_success(src);
    src.writeline(src.UserData.messages.on_success);
elseif strcmpi(word, src.UserData.triggers.quit)
    Microcontroller_Interface.logger(src.UserData.db_messages.on_quit);
    src.UserData.next.on_quit(src);
elseif strcmpi(word, src.UserData.triggers.bounce)
    Microcontroller_Interface.logger(src.UserData.db_messages.on_bounce);
    src.writeline(src.UserData.messages.on_bounce);
elseif strcmpi(word, src.UserData.triggers.received)
    Microcontroller_Interface.logger(src.UserData.db_messages.on_received);
    src.flush();
else
    Microcontroller_Interface.logger(sprintf('Received Message: {%s}', word));
    % Do not send anything back, to avoid a perpetual "acknowledged ...
    % acknowledged acknowledged ... " etc. loop.
end

end