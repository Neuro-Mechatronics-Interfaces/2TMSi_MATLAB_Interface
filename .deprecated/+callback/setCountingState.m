function setCountingState(src)
%SETCOUNTINGSTATE  Update state to AWAITING_COMPLETION and corresponding fields

src.UserData.state = ExperimentState.AWAITING_COMPLETION;
src.UserData.triggers.next = "received";
src.UserData.triggers.bounce = "start";
src.UserData.messages.on_bounce = "bounced:running";
src.UserData.db_messages.on_success = "<strong>STOP</strong> request received successfully!";
src.UserData.db_messages.on_bounce = "Awaiting <strong>RECEIVED</strong> (stop request) confirmation!";
src.UserData.next.on_success = @callback.setTransmittingState;
src.UserData.ts.start = [src.UserData.ts.start; default.now()];
Microcontroller_Interface.logger(sprintf('Serial Interface at <strong>%s</strong> indicates that experiment is now <strong>IDLE</strong>.', src.Port));

end