function endSession(src)
%ENDSESSION  Callback to shut down serial interface

src.UserData.state = ExperimentState.COMPLETE;
src.UserData.ts.finish = default.now();
src.UserData.next.on_success = @(~)Microcontroller_Interface.logger("Session has ended.");
src.UserData.next.on_quit = @(~)Microcontroller_Interface.logger("Session has ended.");
configureCallback(src, "Terminator", @(~, ~)Microcontroller_Interface.logger("Session has ended."));
flush(src);
src.writeline('end');
Microcontroller_Interface.logger(sprintf('<strong>%s</strong> state set to <strong>COMPLETE</strong>.', src.Port));
end