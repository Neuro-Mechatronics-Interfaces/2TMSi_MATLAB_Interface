function setRunningState(src)
%SETRUNNINGSTATE  Update state to Running and set corresponding UserData fields

src.UserData.state = ExperimentState.RUNNING;
src.UserData.triggers.next = "stop";
src.UserData.triggers.bounce = "start";
src.UserData.messages.on_bounce = "bounced:running";
src.UserData.db_messages.on_success = "Received <strong>STOP</strong> recording signal.";
src.UserData.db_messages.on_bounce = "Received <strong>START</strong> signal, but recording was already running!";
src.UserData.next.on_success = @callback.setAwaitingState;
src.UserData.key = [src.UserData.key; src.UserData.next.key];
src.UserData.next.key = src.UserData.next.key + 1;
src.UserData.ts.start = [src.UserData.ts.start; default.now()];
Microcontroller_Interface.logger(sprintf('Serial Interface at <strong>%s</strong> indicates that experiment is now <strong>RUNNING</strong>.', src.Port));

end