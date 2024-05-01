function fig = init_instruction_gui(options)
%INIT_INSTRUCTION_GUI  Initialize GUI with instructions/microcontroller sync outputs
arguments
    options.Serial = [];
    options.InstructionList string = ["Index Flexion", "Ring Flexion", "Wrist Extension", "Index Flexion + Ring Flexion", "Wrist Extension + Ring Flexion", "Index Flexion + Wrist Extension"];
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
fig = figure('Name','Instructions GUI',...
    'Color', 'k', ...
    'WindowState', 'maximized', ...
    'MenuBar','none',...
    'ToolBar','none',...
    'WindowKeyReleaseFcn', @handleWindowKeyRelease);
L = tiledlayout(fig, 'flow');
title(L,"Multi-Gesture Task",'FontName','Consolas','Color','w','FontSize',32);
fig.UserData = struct;
fig.UserData.Axes = nexttile(L);
set(fig.UserData.Axes,'XLim',[-1, 1],'YLim',[-1, 1],'Color','k',...
    'XColor','none','YColor','none','FontName','Tahoma');
fig.UserData.Label = text(fig.UserData.Axes, 0, 0, "IDLE", ...
    'FontSize', 64, 'FontWeight','bold','Color','w', ...
    "HorizontalAlignment",'center','VerticalAlignment','middle');
fig.UserData.Serial = s;
instructionList = options.InstructionList;
if ~contains(upper(instructionList),"REST")
    nInstruct = numel(instructionList);
    instructionList = [repmat("REST",1,nInstruct); reshape(instructionList,1,nInstruct)];
    instructionList = instructionList(:);
else
    instructionList(1:2:end) = "REST";
end
if ~strcmpi(instructionList(end),"REST")
    instructionList(end+1) = "REST";
end
fig.UserData.InstructionList = instructionList;
fig.UserData.Index = 0;
if ~isempty(fig.UserData.Serial)
    fig.DeleteFcn = @(~,~)delete(fig.UserData.Serial);
end

    function handleWindowKeyRelease(src,evt)
        if strcmpi(evt.Key, 'rightarrow') || strcmpi(evt.Key, 'space')
            src.UserData.Index = src.UserData.Index + 1;
            if src.UserData.Index > numel(src.UserData.InstructionList)
                if ~isempty(src.UserData.Serial)
                    writeline(src.UserData.Serial,"0");
                end
                delete(src);
                return;
            end
            instruction = src.UserData.InstructionList(src.UserData.Index);
            src.UserData.Label.String = instruction;
            if ~isempty(src.UserData.Serial)
                if strcmpi(instruction,"REST")
                    writeline(src.UserData.Serial,"1");
                else
                    writeline(src.UserData.Serial,"0");
                    writeline(src.UserData.Serial,num2str(src.UserData.Index/2+1));
                end
            end
        end
    end

end