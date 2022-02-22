function setTransmittingState(src)
%SETTRANSMITTING  Update state to AWAITING_RESPONSE and corresponding fields

src.UserData.state = ExperimentState.AWAITING_RESPONSE;
src.UserData.triggers.next = "received";
src.UserData.triggers.bounce = "start";
src.UserData.messages.on_bounce = "bounced:running";
src.UserData.db_messages.on_success = "<strong>START</strong> request received successfully!";
src.UserData.db_messages.on_bounce = "Awaiting <strong>RECEIVED</strong> (start request) confirmation!";
src.UserData.next.on_success = @callback.setCountingState;
src.UserData.key = [src.UserData.key; src.UserData.next.key];
src.UserData.next.key = src.UserData.next.key + 1;
Microcontroller_Interface.logger(...
    sprintf('Serial Interface at <strong>%s</strong> indicates that experiment is now <strong>RUNNING</strong>.', ...
        src.Port));

end