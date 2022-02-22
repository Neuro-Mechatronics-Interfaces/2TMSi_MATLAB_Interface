function setAwaitingState(src)
%SETAWAITINGSTATE  Update state to "Selecting_Parameters" and set corresponding UserData fields

src.UserData.state = ExperimentState.SELECTING_PARAMETERS;
src.UserData.triggers.next = "start";
src.UserData.triggers.bounce = "stop";
src.UserData.messages.on_bounce = "bounced:idle";
src.UserData.db_messages.on_success = "Received <strong>START</strong> recording signal.";
src.UserData.db_messages.on_bounce = "Received <strong>STOP</strong> signal before recording was started!";
src.UserData.next.on_success = @callback.setRunningState;
src.UserData.ts.stop = [src.UserData.ts.stop; default.now()];
Microcontroller_Interface.logger(sprintf('Serial Interface at <strong>%s</strong> indicates that experiment is now <strong>SELECTING_PARAMETERS</strong>.', src.Port));

end