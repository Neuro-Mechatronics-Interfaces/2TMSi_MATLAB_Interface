function advanceGestureTrial(figH, index)
%ADVANCEGESTURETRIAL  Advances gesture trial in figure handle for gesture prompts GUI.
% if figH.UserData.Index == 0
%     writeline(figH.UserData.UDP,"run", ...
%         figH.UserData.Config.UDP.Socket.StreamService.Address, ...
%         figH.UserData.Config.UDP.Socket.StreamService.Port.state);
% end
if nargin < 2
    figH.UserData.Index = figH.UserData.Index + 1;
else
    figH.UserData.Index = index;
end
if figH.UserData.Index > numel(figH.UserData.InstructionList)
    if ~isempty(figH.UserData.Serial)
        writeline(figH.UserData.Serial,"0");
    end
    delete(figH);
    return;
end
instruction = figH.UserData.InstructionList(figH.UserData.Index);
figH.UserData.Label.String = instruction;
drawnow();
if ~isempty(figH.UserData.Serial)
    if strcmpi(instruction,"REST")
        writeline(figH.UserData.Serial,"1");
    else
        writeline(figH.UserData.Serial,"0");
        if figH.UserData.PulseSecondary
            writeline(figH.UserData.Serial,num2str(figH.UserData.Index/2+1));
        end
    end
end

if ~isempty(figH.UserData.LSL_Outlet)
    gesture = {char(instruction)};
    figH.UserData.LSL_Outlet.push_sample(gesture);
end

soundsc(figH.UserData.Metronome.Y, figH.UserData.Metronome.fs);
if strcmpi(instruction,"REST")
    if figH.UserData.Index > 1
        playRestAnimation(figH.UserData.Image, figH.UserData.Gesture{(figH.UserData.Index-1)/2});
        % playRestAnimation(figH.UserData.Image, figH.UserData.Gesture);
        % figH.UserData.Gesture = imread(fullfile(figH.UserData.GesturesRoot,sprintf('%s.gif',figH.UserData.GestureList{(figH.UserData.Index-1)/2})),'Frames','all');
    end
    % figH.UserData.Label.String = "REST (Ready)";
    drawnow();
else
    playGoAnimation(figH.UserData.Image, figH.UserData.Gesture{figH.UserData.Index/2});
    % playGoAnimation(figH.UserData.Image, figH.UserData.Gesture);
end

    function playRestAnimation(imgH, gestureFrames)
        nFrames = size(gestureFrames,4);
        for iFrame = ceil(nFrames/2):nFrames
            imgH.CData = gestureFrames(:,:,:,iFrame);
            drawnow();
            pause(0.030);
        end
    end

    function playGoAnimation(imgH, gestureFrames)
        nFrames = size(gestureFrames,4);
        for iFrame = 1:floor(nFrames/2)
            imgH.CData = gestureFrames(:,:,:,iFrame);
            drawnow();
            pause(0.030);
        end
    end

end