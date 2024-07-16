function fig = init_instruction_gui(options)
%INIT_INSTRUCTION_GUI  Initialize GUI with instructions/microcontroller sync outputs
arguments
    options.Serial = [];
    options.LSLFolder {mustBeTextScalar} = "";
    options.UseLSL (1,1) logical = true;
    options.PulseSecondary (1,1) logical = true;
    options.GesturesRoot {mustBeFolder} = fullfile(pwd,'configurations/gifs/pro/gray');
    options.InstructionList (1,:) string {mustBeMember(options.InstructionList,["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"])} = ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"]; % ["Index Extension", "Middle Extension", "Ring Extension"];
    options.SkinColor {mustBeMember(options.SkinColor,["White","Tan","Brown","Black","Grey"])} = "Grey";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger, mustBeMember(options.BaudRate,[9600, 115200])} = 115200;
    options.TimerGUIAddress = [];
end
if isempty(options.Serial)
    ports_available = serialportlist();
    if isempty(ports_available)
        s = [];
        warning('No serial connection to microcontroller available.')
    else
        s = serialport(ports_available{1},options.BaudRate);
    end
else
    s = options.Serial;
    s.write('0','c');
end
switch options.SkinColor
    case "Grey"
        cdata = gray(256);
    case "White"
        cdata = double(cm.umap(validatecolor("#f7b08f")))./255.0;
        cdata = [interp1(1:64,cdata(1:64,:),linspace(1,64,3*64)); cdata(65:3:150,:); cdata(151:185,:)];
    case "Tan"
        cdata = double(cm.umap(validatecolor("#cf8d6d")))./255.0;
        cdata = [interp1(1:32,cdata(1:32,:),linspace(1,32,3*32)); interp1(33:128,cdata(33:128,:),linspace(33,128,256-3*32))];
    case "Brown"
        cdata = double(cm.umap(validatecolor("#4a2412")))./255.0;
        cdata = interp1(1:130,[0,0,0;cdata(1:128,:);1,1,1],linspace(1,130,256));
    case "Black"
        cdata = double(cm.umap(validatecolor("#4f362a")))./255.0;
        cdata = interp1(1:130,[0,0,0;cdata(1:128,:);1,1,1],linspace(1,130,256));
end

instructions = options.InstructionList;
nInstruct = numel(instructions);
if ~contains(upper(instructions),"REST")
    instructions = [repmat("REST",1,nInstruct); reshape(instructions,1,nInstruct)];
    instructions = instructions(:);
else
    instructions(1:2:end) = "REST";
end
if ~strcmpi(instructions(end),"REST")
    instructions(end+1) = "REST";
end


fig = figure('Name','Instructions GUI',...
    'Color', 'k', ...
    'WindowState', 'maximized', ...
    'MenuBar','none',...
    'ToolBar','none',...
    'UserData', struct);
fig.UserData.Gesture = cell(numel(options.InstructionList),1);
fprintf(1,'Loading Images...000%%\n');
for ii = 1:nInstruct
    switch options.InstructionList{ii}
        case 'Pronation'
            fig.UserData.Gesture{ii} = imread(fullfile(options.GesturesRoot,'Supination.gif'), 'Frames','all') + 60; % Lighten everything
            nFrameCur = size(fig.UserData.Gesture{ii},4);
            fig.UserData.Gesture{ii} = fig.UserData.Gesture{ii}(:,:,:,[ceil(nFrameCur/2):nFrameCur,1:floor(nFrameCur/2)]);
            fig.UserData.Gesture{ii}(fig.UserData.Gesture{ii} < 80) = 0;
            fig.UserData.Gesture{ii} = uint8(round(double(fig.UserData.Gesture{ii}).^1/8.*4));
            fig.UserData.Gesture{ii} = 4.*(fig.UserData.Gesture{ii} - 32);
            fig.UserData.Gesture{ii} = uint8(round(32.*log(double(fig.UserData.Gesture{ii})+1)));
        case 'Supination'
            fig.UserData.Gesture{ii} = imread(fullfile(options.GesturesRoot,'Supination.gif'),'Frames','all') + 60; % Lighten everything
            fig.UserData.Gesture{ii}(fig.UserData.Gesture{ii} < 80) = 0;
            fig.UserData.Gesture{ii} = uint8(round(double(fig.UserData.Gesture{ii}).^1/8.*4));
            fig.UserData.Gesture{ii} = 4.*(fig.UserData.Gesture{ii} - 32);
            fig.UserData.Gesture{ii} = uint8(round(32.*log(double(fig.UserData.Gesture{ii})+1)));
        otherwise
            fig.UserData.Gesture{ii} = imread(fullfile(options.GesturesRoot,sprintf('%s.gif',options.InstructionList{ii})), ...
                'Frames','all');
    end
    fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*ii/nInstruct));
end
% fig.UserData.Gesture = imread(fullfile(options.GesturesRoot,sprintf('%s.gif',options.InstructionList{1})),'Frames','all');
fig.UserData.PulseSecondary = options.PulseSecondary;

if options.UseLSL
    if strlength(options.LSLFolder) < 1
        lslFolder = parameters('liblsl_folder');
    else
        lslFolder = options.LSLFolder;
    end
    addpath(genpath(lslFolder));
    fig.UserData.LSL_Lib = lsl_loadlib();
    
    % make a new stream outlet
    % the name (here MyMarkerStream) is visible to the experimenter and should be chosen so that 
    % it is clearly recognizable as your MATLAB software's marker stream
    % The content-type should be Markers by convention, and the next three arguments indicate the 
    % data format (1 channel, irregular rate, string-formatted).
    % The so-called source id is an optional string that allows for uniquely identifying your 
    % marker stream across re-starts (or crashes) of your script (i.e., after a crash of your script 
    % other programs could continue to record from the stream with only a minor interruption).
    fig.UserData.LSL_StreamInfo = lsl_streaminfo(fig.UserData.LSL_Lib, ...
        'GestureInstructions', ...
        'Markers', ...
        1, ...
        0, ...
        'cf_string', ...
        sprintf('Gestures%06d',randi(999999,1,1)));
    chns = fig.UserData.LSL_StreamInfo.desc().append_child('channels');
    ch = chns.append_child('channel');
    ch.append_child_value('label','Instruction');
    ch.append_child_value('type','Marker');
    fig.UserData.LSL_Outlet = lsl_outlet(fig.UserData.LSL_StreamInfo);
else
    fig.UserData.LSL_Lib = [];
    fig.UserData.LSL_StreamInfo = [];
    fig.UserData.LSL_Outlet = [];
end

L = tiledlayout(fig, 5, 1);
title(L,"Multi-Gesture Task",'FontName','Consolas','Color','w','FontSize',32);
fig.UserData.Axes = nexttile(L,1,[1 1]);
set(fig.UserData.Axes,'XLim',[-1, 1],'YLim',[-1, 1],'Color','k',...
    'XColor','none','YColor','none','FontName','Tahoma');
fig.UserData.Label = text(fig.UserData.Axes, 0, 0, "IDLE", ...
    'FontSize', 64, 'FontWeight','bold','Color','w', ...
    "HorizontalAlignment",'center','VerticalAlignment','middle');

ax = nexttile(L,2,[4 1]); % For the image gestures
set(ax,'NextPlot','add','Colormap',cdata,...
    'XColor','none','YColor','none', 'YDir', 'normal','Color','none', ...
    'XLim',[0 1],'YLim',[0 1],'CLim',[0, 255]);
fig.UserData.Image = image(ax,[0 1],[1 0],fig.UserData.Gesture{1}(:,:,:,1));
% fig.UserData.Image = image(ax,[0 1],[1 0],fig.UserData.Gesture(:,:,:,1));
fig.UserData.Serial = s;
fig.UserData.Config = load_spike_server_config();
try
    u = udpportfind;
    udpAssign = [];
    for iUDP = 1:numel(u)
        if u(iUDP).LocalPort == fig.UserData.Config.UDP.Socket.GesturesGUI.Port
            udpAssign = u(iUDP);
            break;
        end
    end
end

if isempty(udpAssign)
    fig.UserData.UDP = udpport(...
        "LocalPort", fig.UserData.Config.UDP.Socket.GesturesGUI.Port, ...
        'EnablePortSharing', true);
else
    fig.UserData.UDP = udpAssign;
end
fig.UserData.UDP.UserData.OutputName = sprintf('instructions_%s.mat', string(utils.datetime_2_date(datetime('now'))));
fig.UserData.UDP.UserData.Parent = fig;
fig.UserData.UDP.UserData.Host = fig.UserData.Config.UDP.Socket.TimerGUI;
if ~isempty(options.TimerGUIAddress)
    fig.UserData.UDP.UserData.Host.Address = options.TimerGUIAddress;
end
configureCallback(fig.UserData.UDP,"terminator",@handleNamePingResponse);
fig.UserData.InstructionList = instructions;
fig.UserData.GesturesRoot = options.GesturesRoot;
fig.UserData.GestureList = options.InstructionList;
fig.UserData.LastActiveIndex = 0;
fig.UserData.InTypeTransition = false;
fig.UserData.Metronome = struct;
[fig.UserData.Metronome.Y, fig.UserData.Metronome.fs] = audioread('Metronome.wav');
fig.UserData.Index = 0;
fig.DeleteFcn = @handleWindowDeletion;
fig.WindowKeyReleaseFcn = @handleWindowKeyRelease;

    function handleNamePingResponse(src,~)
        msg = readline(src);
        res = jsondecode(msg);
        disp(msg);
        switch res.type
            case 'name'
                [p,expr,~] = fileparts(res.value);
                src.UserData.OuputName = fullfile(p, sprintf(expr, 'instructionList'));
            case 'control'
                advanceGestureTrial(src.UserData.Parent, res.value);
                writeline(src, "ack", src.UserData.Host.Address, src.UserData.Host.Port);
            otherwise
                error("Expecting response type to be `name` or `control`, but received JSON message for `%s` instead.", res.type);
        end
    end

    function handleWindowKeyRelease(figH,evt)
        if strcmpi(evt.Key, 'rightarrow') || strcmpi(evt.Key, 'space')
            advanceGestureTrial(figH);
        end
    end

end