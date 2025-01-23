function updateGestureState(fig, asserting, config, loopTic)
%UPDATEGESTURESTATE Updates Gesture GUI (see: init_instruction_gui2)
global SELECTED_CHANNEL
% time_since_last_assertion_change = toc(fig.UserData.LastAssertionChange);
% if time_since_last_assertion_change >= config.Debounce_Duration
%     if fig.UserData.Asserted ~= asserting
%         fig.UserData.LastAssertionChange = loopTic;
%         fig.UserData.Asserted = asserting;
%         fig.UserData.Debounce = true;
%     else  % This is included so that other processes, such as keyboard callbacks, can use Debounce State of figure.
%         fig.UserData.Debounce = false;
%     end
% else
%     asserting = fig.UserData.Asserted;
% end

newSequence = false;
nFramesAnimation = numel(fig.UserData.FrameSequence);
switch fig.UserData.State
    case -3 % PAUSE
        return;
    case -2 % UNPAUSE
        fig.UserData.LastStateChange = tic(); % RESET
        fig.UserData.State = fig.UserData.PreviousState;
        return;
    case -1 % NEW-GESTURE INSTRUCTION HOLD
        hold_time = toc(fig.UserData.LastStateChange);
        fig.UserData.Label.Gesture.String = fig.UserData.Gesture{fig.UserData.CurrentGesture};
        if hold_time >= config.Instruction_Duration
            fig.UserData.State = 0;
        end
        return; % Cannot "interact" during INSTRUCTION state.
    case 0 % RESTING -> READY
        newSequence = true;
        fig.UserData.Label.State.String = "GO!";
        fig.UserData.Active = true;
        fig.UserData.Serial.write(48+fig.UserData.CurrentGesture,'c');
        fig.UserData.State = fig.UserData.State + 1;
    case 1 % READY -> ACTIVE
        if (fig.UserData.InstructionFrame == nFramesAnimation)
            fig.UserData.State = fig.UserData.State + 1;
            fig.UserData.Label.State.String = "HOLD";
            fig.UserData.LastStateChange = loopTic;
        end
    case 2 % ACTIVE -> ACTIVE-HOLD        
        hold_time = toc(fig.UserData.LastStateChange);
        if hold_time >= config.Gesture_Duration
            fig.UserData.Serial.write(48,'c'); % Want falling edge to happen as animation for falling edge begins.
            fig.UserData.Label.State.String = "REST";
            fig.UserData.State = fig.UserData.State + 1;
        end
    case 3 % ACTIVE-HOLD -> RESTING
        if (fig.UserData.InstructionFrame == 1)
            fig.UserData.State = fig.UserData.State + 1;
            fig.UserData.LastStateChange = loopTic;
            fig.UserData.Active = false;
        end
    case 4 % RESTING-HOLD -> (NEW INSTRUCTION | READY | EXIT )
        hold_time = toc(fig.UserData.LastStateChange);
        if hold_time >= config.Rest_Duration
            fig.UserData.State = 0; % READY (default)
            fig.UserData.InstructionFrame = 1;
            fig.UserData.AssertedFrame = 1;
            fig.UserData.GestureReps = fig.UserData.GestureReps + 1;
            fig.UserData.LastStateChange = tic();
            if fig.UserData.GestureReps == config.Repetitions % GOTO NEW GESTURE
                fig.UserData.GestureReps = 0;
                fig.UserData.State = -1; % INSTRUCTION
                fig.UserData.CurrentGesture = fig.UserData.CurrentGesture + 1;
                if fig.UserData.CurrentGesture > numel(fig.UserData.Animation) % IF OUT OF GESTURE INDEX RANGE, GOTO EXIT
                    fig.UserData.State = 5;
                    return;
                else
                    SELECTED_CHANNEL = fig.UserData.Channel(fig.UserData.CurrentGesture);
                end
            end
        end
    case 5 % EXIT
        disp("Task complete!");
        close(fig);
        return;
end

if newSequence
    nFramesAnimation = round(size(fig.UserData.Animation{fig.UserData.CurrentGesture},4)/2);
    nTransitionFrames = round(config.Transition_Duration / config.Frame_Period);
    fig.UserData.FrameSequence = round(linspace(1, nFramesAnimation, nTransitionFrames));
end

time_since_last_frame = toc(fig.UserData.LastFrame);
if time_since_last_frame >= config.Frame_Period
    % Update to the next frame in sequence, if needed.
    
    switch fig.UserData.State
        case 1
            fig.UserData.InstructionFrame = min(nFramesAnimation, fig.UserData.InstructionFrame+1);
        case 3
            fig.UserData.InstructionFrame = max(1, fig.UserData.InstructionFrame-1);
    end
    if asserting > 0
        fig.UserData.AssertedFrame = min(nFramesAnimation, fig.UserData.AssertedFrame+1);
        if islogical(asserting)
            assertedGesture = fig.UserData.CurrentGesture;
        else
            assertedGesture = asserting;
        end
    else
        fig.UserData.AssertedFrame = max(1, fig.UserData.AssertedFrame-1);
        assertedGesture = fig.UserData.CurrentGesture;
    end
    fig.UserData.Image.CData = ...
        round(0.35 * fig.UserData.Animation{fig.UserData.CurrentGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.InstructionFrame))) + ...
        round(0.65 * fig.UserData.Animation{assertedGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.AssertedFrame)));
    
    % % For RGB image updates: % %
    % fig.UserData.Image.CData(:,:,1,:) = ...
    %     round(0.15 * fig.UserData.Animation{fig.UserData.CurrentGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.InstructionFrame))) + ...
    %     round(0.25 * fig.UserData.Animation{fig.UserData.CurrentGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.AssertedFrame)));
    % fig.UserData.Image.CData(:,:,2,:) = ... % Blend the instructed and asserted gestures into one image
    %     round(0.35 * fig.UserData.Animation{fig.UserData.CurrentGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.InstructionFrame)));
    % fig.UserData.Image.CData(:,:,3,:) = ...
    %     round(0.65 * fig.UserData.Animation{fig.UserData.CurrentGesture}(:,:,:,fig.UserData.FrameSequence(fig.UserData.AssertedFrame)));
    
    % Update the frame-timer
    fig.UserData.LastFrame = loopTic;
end

end