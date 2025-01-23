function handleWindowDeletion(figH,~)
%HANDLEWINDOWDELETION  Handles window deletion in Gestures prompting GUI.
serialExisted = false;
if isfield(figH.UserData,'Serial')
    if ~isempty(figH.UserData.Serial)
        write(figH.UserData.Serial,'0','c');
        delete(figH.UserData.Serial);
        serialExisted = true;
    end
end
udpExisted = false;
if isfield(figH.UserData,'UDP')
    if ~isempty(figH.UserData.UDP)
        udpExisted = true;
        writeline(figH.UserData.UDP,"run", ...
            figH.UserData.Config.UDP.Socket.StreamService.Address, ...
            figH.UserData.Config.UDP.Socket.StreamService.Port.state);
        packet = jsonencode(struct('type', 'name', 'value', 'new'));
        writeline(figH.UserData.UDP, packet, ...
            figH.UserData.Config.UDP.Socket.RecordingControllerGUI.Address, ...
            figH.UserData.Config.UDP.Socket.RecordingControllerGUI.Port);
        delete(figH.UserData.UDP);
    end
end
if isfield(figH.UserData,'InstructionList')
    instructionList = figH.UserData.InstructionList;
    if serialExisted && udpExisted
        save(figH.UserData.UDP.UserData.OutputName, 'instructionList', '-v7.3');
    end
end
if isfield(figH.UserData,'LSL_Outlet')
    if ~isempty(figH.UserData.LSL_Outlet)
        delete(figH.UserData.LSL_Outlet);
        delete(figH.UserData.LSL_StreamInfo);
    end
end
end