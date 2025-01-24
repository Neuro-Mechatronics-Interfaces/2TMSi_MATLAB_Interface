function fig = init_instruction_gui2(options)
%INIT_INSTRUCTION_GUI2  Initialize GUI with instructions/microcontroller sync outputs
arguments
    options.MEGA2560 = [];
    options.DefaultSerialDevice = "COM7";
    options.DefaultTeensyDevice = "COM6";
    options.GesturesRoot {mustBeFolder} = fullfile(pwd,'configurations/gifs/pro/gray');
    options.InstructionList (1,:) string {mustBeMember(options.InstructionList, ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"])} = ["Wrist Extension", "Wrist Flexion", "Radial Deviation", "Ulnar Deviation"]; % ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"]; % ["Index Extension", "Middle Extension", "Ring Extension"];
    options.ChannelList (1,:) double {mustBePositive, mustBeInteger} = [1,1,1,1];
    options.GestureImages cell = cell.empty;
    options.Mirror (1,1) logical = false;
    options.SkinColor {mustBeMember(options.SkinColor,["White","Tan","Brown","Black","Grey"])} = "Grey";
    options.UseMicros (1,1) logical = true;
end
if numel(options.ChannelList) ~= numel(options.InstructionList)
    error("Must have one channel per instructed gesture.");
end
if options.UseMicros
    if isempty(options.MEGA2560)
        mega = connect_mega2560('SerialDevice',options.DefaultSerialDevice);
    else
        mega = options.MEGA2560;
    end
else
    mega = [];
end
cdata = getSkinColormap(options.SkinColor);
fig = figure(...
    'Name','Gestures GUI v2',...
    'Color', 'k', ...
    'WindowState', 'maximized', ...
    'MenuBar','none',...
    'ToolBar','none',...
    'UserData', struct);
if isempty(options.GestureImages)
    fig.UserData.Animation = loadGestureImages( ...
        'Folder', options.GesturesRoot, ...
        'Gestures', options.InstructionList, ...
        'Mirror', options.Mirror);
else
    fig.UserData.Animation = options.GestureImages; % Allows to preload gesture images elsewhere in case we open/close this figure a bunch.
end

L = tiledlayout(fig, 5, 1);
fig.UserData.Label.Gesture = title(L,options.InstructionList{1},'FontName','Consolas','Color','w','FontSize',64,'FontWeight','bold');
fig.UserData.Axes = nexttile(L,1,[1 1]);
set(fig.UserData.Axes,'XLim',[-1, 1],'YLim',[-1, 1],'Color','k',...
    'XColor','none','YColor','none','FontName','Tahoma');
fig.UserData.Label.State = text(fig.UserData.Axes, 0, 0, "PAUSED", ...
    'FontSize', 32, 'FontWeight','normal','Color','w', ...
    "HorizontalAlignment",'center','VerticalAlignment','middle');

ax = nexttile(L,2,[4 1]); % For the image gestures
set(ax,'NextPlot','add','Colormap',cdata,...
    'XColor','none','YColor','none', 'YDir', 'normal','Color','none', ...
    'XLim',[0 1],'YLim',[0 1],'CLim',[0, 255]);
% fig.UserData.Image = image(ax,[0 1],[1 0],repmat(fig.UserData.Animation{1}(:,:,:,1),1,1,3,1));

fig.UserData.Image = image(ax,[0 1],[1 0],fig.UserData.Animation{1}(:,:,:,1));
fig.UserData.Serial = mega;
fig.UserData.Teensy = [];

fig.UserData.Gesture = options.InstructionList;
fig.UserData.Metronome = struct;
[fig.UserData.Metronome.Y, fig.UserData.Metronome.fs] = audioread('Metronome.wav');
fig.UserData.Channel = options.ChannelList;
fig.UserData.CurrentGesture = 1;
fig.UserData.InstructionFrame = 1;
fig.UserData.AssertedFrame = 1;
fig.UserData.GestureReps = 0;
fig.UserData.FrameSequence = [];
fig.UserData.State = -3; % PAUSED
fig.UserData.PreviousState = -1; % INSTRUCT
fig.UserData.PreviousLabel = "REST";
fig.UserData.Active = false;
fig.UserData.Asserted = false;
fig.UserData.Debounce = false;
fig.UserData.UseMicros = options.UseMicros;
fig.UserData.Paused = true; % Starts with game paused
fig.UserData.AnimationRisingEdge = true;
fig.UserData.LastAssertionChange = tic();
fig.UserData.LastStateChange = tic();
fig.UserData.LastFrame = tic();
fig.WindowKeyPressFcn = @handleWindowKeyPress;

    function handleWindowKeyPress(figH,evt)
        % disp(evt);
        switch evt.Key
            case {'space'}
                if figH.UserData.Paused % Then exit paused state
                    figH.UserData.Label.State.String = fig.UserData.PreviousLabel;
                    figH.UserData.State = -2; % UNPAUSE state
                else
                    figH.UserData.PreviousLabel = figH.UserData.Label.State.String;
                    figH.UserData.PreviousState = figH.UserData.State;
                    figH.UserData.State = -3; % PAUSE state
                    figH.UserData.Label.State.String = "PAUSED";
                end
                disp(figH.UserData.State);
                figH.UserData.Paused = ~figH.UserData.Paused;
            case {'1','2','3','4','5','6','7'}
                figH.UserData.State = evt.Key-50; % First state is '1', which is mapped to value -1 so we subtract 50 so the character is -1
            case {'rightarrow', 'leftarrow', 'd', 'a'}
                figH.UserData.Active = ~figH.UserData.Active;
                figH.UserData.Debounce = true;
            case {'uparrow', 'w'}
                if ~figH.UserData.Active
                    figH.UserData.Active = false;
                    figH.UserData.ReturnToRestIndex = figH.UserData.ActiveIndex;
                end
                figH.UserData.ActiveIndex = min(numel(figH.UserData.Gesture),figH.UserData.ActiveIndex+1);
                figH.UserData.Debounce = true;
            case {'downarrow', 's'}
                if ~figH.UserData.Active
                    figH.UserData.Active = false;
                    figH.UserData.ReturnToRestIndex = figH.UserData.ActiveIndex;
                end
                figH.UserData.ActiveIndex = max(1,figH.UserData.ActiveIndex-1);
                figH.UserData.Debounce = true;
            case {'q', 'escape'}
                close(figH);
        end
        
    end

end