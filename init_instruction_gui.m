function fig = init_instruction_gui(options)
%INIT_INSTRUCTION_GUI  Initialize GUI with instructions/microcontroller sync outputs
arguments
    options.Serial = [];
    options.PulseSecondary (1,1) logical = true;
    options.GesturesRoot {mustBeFolder} = fullfile(pwd,'configurations/gifs/pro/gray');
    options.InstructionList (1,:) string {mustBeMember(options.InstructionList,["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"])} = ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"]; % ["Index Extension", "Middle Extension", "Ring Extension"];
    options.SkinColor {mustBeMember(options.SkinColor,["White","Tan","Brown","Black","Grey"])} = "Grey";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger, mustBeMember(options.BaudRate,[9600, 115200])} = 115200;
end
if isempty(options.Serial)
    ports_available = serialportlist();
    if isempty(ports_available)
        s = [];
    else
        s = serialport(ports_available{1},options.BaudRate);
    end
else
    s = options.Serial;
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
fig.UserData.UDP = udpport();
fig.UserData.UDP.UserData.OutputName = sprintf('instructions_%s.mat', string(datetime('now')));
fig.UserData.UDP.UserData.Parent = fig;
configureCallback(fig.UserData.UDP,"terminator",@handleNamePingResponse);
fig.UserData.InstructionList = instructions;
fig.UserData.GesturesRoot = options.GesturesRoot;
fig.UserData.GestureList = options.InstructionList;
fig.UserData.Index = 0;
fig.DeleteFcn = @handleWindowDeletion;
fig.WindowKeyReleaseFcn = @handleWindowKeyRelease;

    function handleNamePingResponse(src,~)
        msg = readline(src);
        res = jsondecode(msg);
        switch res.type
            case 'name'
                [p,expr,~] = fileparts(res.value);
                src.UserData.OuputName = fullfile(p, sprintf(expr, 'instructionList'));
            case 'control'
                advanceGestureTrial(src.UserData.Parent);
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