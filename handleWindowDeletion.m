function handleWindowDeletion(figH,~)
%HANDLEWINDOWDELETION  Handles window deletion in Gestures prompting GUI.
if ~isempty(figH.UserData.Serial)
    delete(figH.UserData.Serial);
    serialExisted = true;
else
    serialExisted = false;
end
writeline(figH.UserData.UDP,"run", ...
    figH.UserData.Config.UDP.Socket.StreamService.Address, ...
    figH.UserData.Config.UDP.Socket.StreamService.Port.state);
packet = jsonencode(struct('type', 'name', 'value', 'new'));
writeline(figH.UserData.UDP, packet, ...
    figH.UserData.Config.UDP.Socket.RecordingControllerGUI.Address, ...
    figH.UserData.Config.UDP.Socket.RecordingControllerGUI.Port);
instructionList = figH.UserData.InstructionList;
if serialExisted
    save(figH.UserData.UDP.UserData.OutputName, 'instructionList', '-v7.3');
end
delete(figH.UserData.UDP);
if ~isempty(figH.UserData.LSL_Outlet)
    delete(figH.UserData.LSL_Outlet);
    delete(figH.UserData.LSL_StreamInfo);
    delete(figH.UserData.LSL_Lib);
end
end