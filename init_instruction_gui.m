function fig = init_instruction_gui(options)
%INIT_INSTRUCTION_GUI  Initialize GUI with instructions/microcontroller sync outputs
arguments
    options.Serial = [];
    options.InstructionList string = ["Index Extension", "Middle Extension", "Ring Extension"];
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
fig.UserData.Config = load_spike_server_config();
fig.UserData.UDP = udpport();
fig.UserData.UDP.UserData.OutputName = sprintf('instructions_%s.mat', string(datetime('now')));
configureCallback(fig.UserData.UDP,"terminator",@handleNamePingResponse);

instructions = options.InstructionList;
if ~contains(upper(instructions),"REST")
    nInstruct = numel(instructions);
    instructions = [repmat("REST",1,nInstruct); reshape(instructions,1,nInstruct)];
    instructions = instructions(:);
else
    instructions(1:2:end) = "REST";
end
if ~strcmpi(instructions(end),"REST")
    instructions(end+1) = "REST";
end
fig.UserData.InstructionList = instructions;
fig.UserData.Index = 0;
fig.DeleteFcn = @handleWindowDeletion;

    function handleNamePingResponse(src,~)
        msg = readline(src);
        res = jsondecode(msg);
        if ~strcmpi(res.type,'name')
            error("Expecting response type to be `name`, but received JSON message for `%s` instead.", res.type);
        end
        [p,expr,~] = fileparts(res.value);
        src.UserData.OuputName = fullfile(p, sprintf(expr, 'instructionList'));
    end

    function handleWindowDeletion(src,~)
        if ~isempty(src.UserData.Serial)
            delete(src.UserData.Serial);
        end
        writeline(src.UserData.UDP,"run", ...
            src.UserData.Config.UDP.Socket.StreamService.Address, ...
            src.UserData.Config.UDP.Socket.StreamService.Port.state);
        packet = jsonencode(struct('type', 'name', 'value', 'new'));
        writeline(src.UserData.UDP, packet, ...
            src.UserData.Config.UDP.Socket.RecordingController.Address, ...
            src.UserData.Config.UDP.Socket.RecordingController.Port);
        instructionList = src.UserData.InstructionList;
        save(src.UserData.UDP.OutputName, 'instructionList', '-v7.3');
        delete(src.UserData.UDP);
    end

    function handleWindowKeyRelease(src,evt)
        if strcmpi(evt.Key, 'rightarrow') || strcmpi(evt.Key, 'space')
            if src.UserData.Index == 0
                writeline(src.UserData.UDP,"rec", ...
                    src.UserData.Config.UDP.Socket.StreamService.Address, ...
                    src.UserData.Config.UDP.Socket.StreamService.Port.state);
            end
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