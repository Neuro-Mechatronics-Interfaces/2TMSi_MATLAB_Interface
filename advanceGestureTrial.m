function advanceGestureTrial(figH, index)
%ADVANCEGESTURETRIAL  Advances gesture trial in figure handle for gesture prompts GUI.
% if figH.UserData.Index == 0
%     writeline(figH.UserData.UDP,"run", ...
%         figH.UserData.Config.UDP.Socket.StreamService.Address, ...
%         figH.UserData.Config.UDP.Socket.StreamService.Port.state);
% end
if nargin < 2
    figH.UserData.Index = figH.UserData.Index + 1;
    index = figH.UserData.Index;
    figH.UserData.InTypeTransition = true;
else
    if index == 255
        index = numel(figH.UserData.InstructionList);
    end
    if strcmpi(figH.UserData.InstructionList(index), "REST")
        if index ~= figH.UserData.LastActiveIndex
            figH.UserData.LastActiveIndex = index;
            figH.UserData.InTypeTransition = true;
        else
            figH.UserData.InTypeTransition = false;
        end
    end
    figH.UserData.Index = index;
end
if index > numel(figH.UserData.InstructionList)
    if ~isempty(figH.UserData.Serial)
        write(figH.UserData.Serial,'0','c');
    end
    % delete(figH);
    return;
end
instruction = figH.UserData.InstructionList(index);
figH.UserData.Label.String = instruction;
drawnow();
if ~isempty(figH.UserData.Serial)
    if strcmpi(instruction,"REST")
        write(figH.UserData.Serial,'1','c');
    else
        write(figH.UserData.Serial,'0','c');
        if figH.UserData.PulseSecondary
            write(figH.UserData.Serial,char(num2str(index/2+1)),'c');
        end
    end
end

if ~isempty(figH.UserData.LSL_Outlet)
    gesture = {char(instruction)};
    figH.UserData.LSL_Outlet.push_sample(gesture);
end

soundsc(figH.UserData.Metronome.Y, figH.UserData.Metronome.fs);
if strcmpi(instruction,"REST")
    if index > 1
        if figH.UserData.InTypeTransition
            if index > 3
                k = (index-1)/2 - 1;
            else
                k = (index-1)/2;
            end
        else
            k = (index-1)/2;
        end
        fprintf(1,'Playing REST for %s\n',figH.UserData.GestureList{k});
        playRestAnimation(figH.UserData.Image, figH.UserData.Gesture{k});
        % playRestAnimation(figH.UserData.Image, figH.UserData.Gesture{(figH.UserData.Index)/2});
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