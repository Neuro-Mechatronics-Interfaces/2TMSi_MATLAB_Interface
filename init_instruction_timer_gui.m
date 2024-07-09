function fig = init_instruction_timer_gui(options)
arguments
    options.GestureList (1,:) string {mustBeMember(options.GestureList,["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"])}= ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"]; % ["Index Extension", "Middle Extension", "Ring Extension"];
    options.GesturesGUIAddress = [];
end
fig = uifigure(...
    'Name', 'Instructions Timer', ...
    'Color', 'k', ...
    'Units', 'inches', ...
    'MenuBar','none', ...
    'ToolBar','none', ...
    'Position', [1 1 4 6]);
L = uigridlayout(fig, [10, 3],'BackgroundColor','k');
lab = uilabel(L,"Text", "Rest (sec)", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 1;
lab.Layout.Column = 1;
fig.UserData.RestEditField = uieditfield(L, 'numeric', ...
    "FontName", "Consolas", ...
    "AllowEmpty", false, ...
    "Value", 5, ...
    "RoundFractionalValues", false);
fig.UserData.RestEditField.Layout.Row = 1;
fig.UserData.RestEditField.Layout.Column = [2 3];

lab = uilabel(L,"Text", "Gesture (sec)", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 2;
lab.Layout.Column = 1;
fig.UserData.GestureEditField = uieditfield(L, 'numeric', ...
    "FontName", "Consolas", ...
    "AllowEmpty", false, ...
    "Value", 5, ...
    "RoundFractionalValues", false);
fig.UserData.GestureEditField.Layout.Row = 2;
fig.UserData.GestureEditField.Layout.Column = [2 3];

lab = uilabel(L,"Text", "Reps", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 3;
lab.Layout.Column = 1;
fig.UserData.RepsEditField = uieditfield(L, 'numeric', ...
    "FontName", "Consolas", ...
    "AllowEmpty", false, ...
    "Value", 10, ...
    "RoundFractionalValues", false);
fig.UserData.RepsEditField.Layout.Row = 3;
fig.UserData.RepsEditField.Layout.Column = [2 3];

lab = uilabel(L,"Text", "Gestures", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 1;
fig.UserData.Gestures = uilistbox(L, ...
    'Items', options.GestureList, ...
    'ItemsData', 1:numel(options.GestureList), ...
    'Multiselect', 'on', ...
    'Value', 1:numel(options.GestureList), ...
    "FontName", "Consolas");
fig.UserData.Gestures.Layout.Row = [4 8];
fig.UserData.Gestures.Layout.Column = [2 3];

lab = uilabel(L,"Text", "Remaining", ...
    'FontName', 'Tahoma', ...
    'FontColor', 'w', ...
    'HorizontalAlignment','right');
lab.Layout.Row = 9;
lab.Layout.Column = 1;
fig.UserData.Remaining = uilabel(L,...
    "Text",num2str(fig.UserData.RepsEditField.Value * numel(fig.UserData.Gestures.Value)),...
    'FontName','Tahoma','FontColor','w','FontWeight','bold');
fig.UserData.Remaining.Layout.Row = 9;
fig.UserData.Remaining.Layout.Column = [2 3];

config = load_spike_server_config();
if ~isempty(options.GesturesGUIAddress)
    config.UDP.Socket.GesturesGUI.Address = options.GesturesGUIAddress;
end
fig.UserData.Timer = timer('Name','GesturesTimer-0','ExecutionMode','fixedRate','Period',0.100,'TimerFcn',@runGesturesList);
fig.UserData.Timer.UserData = struct(...
    'UDP',udpport("LocalPort", config.UDP.Socket.TimerGUI.Port),... 
    'Target',config.UDP.Socket.GesturesGUI, ...
    'CurrentRep',1,'CurrentGesture',1, ...
    'RestDuration',5,'GestureDuration',5,...
    'Reps',10,'Gestures',numel(options.GestureList),'GestureList',1:numel(options.GestureList), ...
    'tCur', [], 'State', 0);
fig.UserData.StartButton = uibutton(L, "Text", "START", "BackgroundColor",'b',"FontColor",'w','FontWeight','bold', 'ButtonPushedFcn', @startButtonPushed,'FontName','Tahoma', 'Enable', 'on');
fig.UserData.StartButton.Layout.Row = 10;
fig.UserData.StartButton.Layout.Column = 1;
fig.UserData.StopButton = uibutton(L, "Text", "STOP", "BackgroundColor",'r',"FontColor",'w','FontWeight','bold','ButtonPushedFcn', @stopButtonPushed,'FontName','Tahoma', 'Enable', 'off');
fig.UserData.StopButton.Layout.Row = 10;
fig.UserData.StopButton.Layout.Column = 3;
fig.UserData.PauseButton = uibutton(L, "Text", "PAUSE", "FontWeight",'bold','ButtonPushedFcn',@pauseButtonPushed, ...
    'UserData',struct('tPause',[]));
fig.UserData.PauseButton.Layout.Row = 10;
fig.UserData.PauseButton.Layout.Column = 2;
fig.UserData.Timer.UserData.Button = struct('Start',fig.UserData.StartButton,'Stop',fig.UserData.StopButton, 'Pause', fig.UserData.PauseButton);
fig.UserData.Timer.UserData.Remaining = fig.UserData.Remaining;
fig.DeleteFcn = @handleInstructionTimerGUIClosing;

    function pauseButtonPushed(src,~)
        t = src.Parent.Parent.UserData.Timer;
        if strcmpi(src.Text,"PAUSE")
            src.UserData.tPause = tic;
            stop(t);
            src.Text = "RESUME";
        else
            tResume = toc(src.UserData.tPause);
            t.UserData.tCur = t.UserData.tCur + (uint64(round(tResume * 1e7)));
            start(t);
            src.Text = "PAUSE";
        end
    end

    function startButtonPushed(src,~)
        f = src.Parent.Parent;
        t = f.UserData.Timer;
        t.UserData.CurrentRep = 1;
        t.UserData.CurrentGesture = 1;
        t.UserData.Reps = f.UserData.RepsEditField.Value;
        t.UserData.RestDuration = f.UserData.RestEditField.Value;
        t.UserData.GestureDuration = f.UserData.GestureEditField.Value;
        t.UserData.Gestures = numel(f.UserData.Gestures.Value);
        t.UserData.GestureList = f.UserData.Gestures.Value;
        t.UserData.State = -1;
        t.UserData.Remaining.Text = num2str(t.UserData.Reps * t.UserData.Gestures);
        t.UserData.tCur = tic;
        start(t);
        t.UserData.Button.Stop.Enable = 'on';
        t.UserData.Button.Pause.Text = "PAUSE";
        t.UserData.Button.Pause.Enable = 'on';
        src.Enable = 'off';
    end
    function stopButtonPushed(src,~)
        t = src.Parent.Parent.UserData.Timer;
        stop(t);
        t.UserData.Button.Start.Enable = 'on';
        t.UserData.Button.Pause.Text = "PAUSE";
        t.UserData.Button.Pause.Enable = 'off';
        t.UserData.Remaining.Text = num2str(t.UserData.Reps * t.UserData.Gestures);
        src.Enable = 'off';
    end
    function runGesturesList(src,~)
        transitionToRest = false;
        transitionToNextGesture = false;
        switch src.UserData.State
            case -1
                transitionToRest = true;
            case 0
                tElapsed = toc(src.UserData.tCur);
                if tElapsed >= src.UserData.RestDuration
                    transitionToNextGesture = true;
                end
            case 1
                tElapsed = toc(src.UserData.tCur);
                if tElapsed >= src.UserData.GestureDuration
                    transitionToRest = true;
                    src.UserData.CurrentRep = src.UserData.CurrentRep + 1;
                    src.UserData.Remaining.Text = num2str(str2double(src.UserData.Remaining.Text) - 1);
                    if src.UserData.CurrentRep > src.UserData.Reps
                        src.UserData.CurrentRep = 1;
                        src.UserData.CurrentGesture = src.UserData.CurrentGesture + 1;
                        if src.UserData.CurrentGesture > numel(src.UserData.GestureList)
                            packet = jsonencode(struct('type','control','value',255));
                            writeline(src.UserData.UDP,packet,src.UserData.Target.Address,src.UserData.Target.Port);
                            stop(src);
                            src.UserData.Button.Start.Enable = 'on';
                            src.UserData.Button.Stop.Enable = 'off';
                            return;
                        end
                    end
                end
        end
        if transitionToRest
            packet = jsonencode(struct('type','control','value',src.UserData.GestureList(src.UserData.CurrentGesture)*2+1));
            writeline(src.UserData.UDP,packet,src.UserData.Target.Address,src.UserData.Target.Port);
            readline(src.UserData.UDP); % for ack
            src.UserData.State = 0;
            src.UserData.tCur = tic;
        elseif transitionToNextGesture
            
            packet = jsonencode(struct('type','control','value',src.UserData.GestureList(src.UserData.CurrentGesture)*2));
            disp(packet);
            writeline(src.UserData.UDP,packet,src.UserData.Target.Address,src.UserData.Target.Port);
            readline(src.UserData.UDP);
            src.UserData.State = 1;
            src.UserData.tCur = tic;
        end
    end
    function handleInstructionTimerGUIClosing(src,~)
        try %#ok<TRYNC>
            stop(src.UserData.Timer);
        end
        try %#ok<TRYNC>
            delete(src.UserData.Timer.UserData.UDP);
        end
        try %#ok<TRYNC>
            delete(src.UserData.Timer);
        end
    end
end