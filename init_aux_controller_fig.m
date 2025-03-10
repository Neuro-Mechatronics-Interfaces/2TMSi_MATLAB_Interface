function fig = init_aux_controller_fig()
%INIT_AUX_CONTROLLER_FIG Initializes UDP parameter interface for controlling aux squiggles plotter (target, offset, scale, channel).
%
% Syntax:
%   fig = init_aux_controller_fig();

host_pc = getenv("COMPUTERNAME");
switch host_pc
    case "MAX_LENOVO" % Max Workstation Laptop (Lenovo ThinkPad D16)
        POSITION_PIX = [300 620 900 230];
    case "NMLVR"
        POSITION_PIX = [500 400 900 230];
    otherwise
        POSITION_PIX = [300 620 900 230];
end
fig = uifigure('Color','w',...
    'MenuBar','none','ToolBar','none',...
    'Name','TMSi AUX Controller',...
    'Position',POSITION_PIX,'Icon',"redlogo.jpg");
L = uigridlayout(fig, [9, 6],'BackgroundColor','k');
L.RowHeight = {'1x', '1x', '1x', '1x', '1x', '1x'};
L.ColumnWidth = {'1x', '1x', '1x', '1x', '1x', '1x'};

config = load_spike_server_config();
fs = config.Default.Sample_Rate / 2^config.Default.Sample_Rate_Divider;
fig.UserData = struct('ReturnAddress', config.UDP.Socket.AuxController.Address, ...
                      'ReturnPort', config.UDP.Socket.AuxController.Port);


fig.UserData.Address = config.UDP.Socket.StreamService.Address;
fig.UserData.StatePort = config.UDP.Socket.StreamService.Port.state;
fig.UserData.NamePort = config.UDP.Socket.StreamService.Port.name;
fig.UserData.ParameterPort = config.UDP.Socket.StreamService.Port.params;

fig.UserData.UDP = udpport("byte",...
    "LocalHost", "0.0.0.0", ...
    'EnablePortSharing', true, ...
    'LocalPort', config.UDP.Socket.AuxController.Port);

% % AUX Channel Widgets % %
lab = uilabel(L,"Text", "AUX SAGA", ...
    'FontName', 'Tahoma','FontColor', 'w', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');
lab.Layout.Row = 1;
lab.Layout.Column = 1;
fig.UserData.AuxSagaDropDown = uidropdown(L, ...
    "Value",config.GUI.Aux_SAGA,...
    "Items",["A","B"],....
    "FontName","Tahoma",...
    "ValueChangedFcn",@handleAuxSagaChange);
fig.UserData.AuxSagaDropDown.Layout.Row = 2;
fig.UserData.AuxSagaDropDown.Layout.Column = 1;

lab = uilabel(L,"Text", "AUX Channel", ...
    'FontName', 'Tahoma','FontColor', 'w', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');
lab.Layout.Row = 1;
lab.Layout.Column = 2;
fig.UserData.AuxSagaChannelEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.Aux_Channel, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxChannelChange);
fig.UserData.AuxSagaChannelEditField.Layout.Row = 2;
fig.UserData.AuxSagaChannelEditField.Layout.Column = 2;

lab = uilabel(L,"Text", "AUX Offset", ...
    'FontName', 'Tahoma','FontColor', 'w', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');
lab.Layout.Row = 3;
lab.Layout.Column = 1;
fig.UserData.AuxOffsetEditField = uieditfield(L, 'numeric', ...
    "Value", 0, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxOffsetChange);
fig.UserData.AuxOffsetEditField.Layout.Row = 4;
fig.UserData.AuxOffsetEditField.Layout.Column = 1;

lab = uilabel(L,"Text", "AUX Scale", ...
    'FontName', 'Tahoma','FontColor', 'w', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');
lab.Layout.Row = 3;
lab.Layout.Column = 2;
fig.UserData.AuxScaleEditField = uieditfield(L, 'numeric', ...
    "Value", 1, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxScaleChange);
fig.UserData.AuxScaleEditField.Layout.Row = 4;
fig.UserData.AuxScaleEditField.Layout.Column = 2;

lab = uilabel(L,"Text", "AUX Error Tol", ...
    'FontName', 'Tahoma','FontColor', 'w', ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','bottom');
lab.Layout.Row = 5;
lab.Layout.Column = 1;
fig.UserData.AuxErrorTolEditField = uieditfield(L, 'numeric', ...
    "Value", 0.1, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxErrorTolChange);
fig.UserData.AuxErrorTolEditField.Layout.Row = 6;
fig.UserData.AuxErrorTolEditField.Layout.Column = 1;

% % "GET" Request Buttons % %
fig.UserData.GetOffsetButton = uibutton(L, ...
    "Text", "Get Baseline", ...
    "FontName", "Tahoma", ...
    "BackgroundColor", [0.1 0.1 0.8], ...
    'FontColor', 'w', ...
    'FontWeight', 'bold', ...
    'ButtonPushedFcn',@handleOffsetRequest);
fig.UserData.GetOffsetButton.Layout.Row = 4;
fig.UserData.GetOffsetButton.Layout.Column = 3;
fig.UserData.GetScaleButton = uibutton(L, ...
    "Text", "Get Scale", ...
    "FontName", "Tahoma", ...
    "BackgroundColor", [0.1 0.1 0.8], ...
    'FontColor', 'w', ...
    'FontWeight', 'bold', ...
    'ButtonPushedFcn',@handleScaleRequest);
fig.UserData.GetScaleButton.Layout.Row = 4;
fig.UserData.GetScaleButton.Layout.Column = 4;

lab = uilabel(L,"Text", "AUX α", ...
    'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 4;
lab.Layout.Column = 5;
fig.UserData.AuxAlphaEditField = uieditfield(L, 'numeric', ...
    "Value", 0.1, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxAlphaChange);
fig.UserData.AuxAlphaEditField.Layout.Row = 4;
fig.UserData.AuxAlphaEditField.Layout.Column = 6;

lab = uilabel(L,"Text", "AUX View Duration (s)", ...
    'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 1;
lab.Layout.Column = 3;
fig.UserData.AuxSamplesEditField = uieditfield(L, 'numeric', ...
    "Value", config.GUI.Aux_Samples/fs, ... % With defaults in TargetX, TargetY, we have 30s for the sombrero.
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxSamplesChange);
fig.UserData.AuxSamplesEditField.Layout.Row = 2;
fig.UserData.AuxSamplesEditField.Layout.Column = 3;

% % AUX TARGET Widgets % %
fig.UserData.EnableAuxTarget = uicheckbox(L, ...
    "Text", "Enable TARGET", ...
    "Value", false, ...
    "FontColor", 'w', ...
    "FontSize", 10, ... 
    "FontName", 'Consolas', ...
    "ValueChangedFcn", @handleAuxTargetEnable);
fig.UserData.EnableAuxTarget.Layout.Row = 1;
fig.UserData.EnableAuxTarget.Layout.Column = 6;

lab = uilabel(L,"Text", "AUX Target X (0 - T, sec)", ...
    'FontName', 'Tahoma','FontColor', 'w','FontSize',10,...
    'HorizontalAlignment','right');
lab.Layout.Row = 2;
lab.Layout.Column = 4;
fig.UserData.AuxTargetXEditField = uieditfield(L, 'text', ...
    "Value", "[2.0, 7.0, 9.0, 14.0, 16.0, 21.0, 23.0, 28.0, 30.0]", ...
    "FontName", 'Consolas', ...
    "FontSize", 8, ... 
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxTargetChange);
fig.UserData.AuxTargetXEditField.Layout.Row = 2;
fig.UserData.AuxTargetXEditField.Layout.Column = [5 6];

lab = uilabel(L,"Text", "AUX Target Y (0 - 1, ratio)", ...
    'FontName', 'Tahoma','FontColor', 'w','FontSize',10,...
    'HorizontalAlignment','right');
lab.Layout.Row = 3;
lab.Layout.Column = 4;
fig.UserData.AuxTargetYEditField = uieditfield(L, 'text', ...
    "Value", "@(x)[0.00, 0.25, 0.25, 0.50, 0.50, 0.25, 0.25, 0.00, 0.00]", ...
    "FontName", 'Consolas', ...
    "FontSize", 8, ... 
    'HorizontalAlignment', 'center', ...
    "ValueChangedFcn",@handleAuxTargetChange);
fig.UserData.AuxTargetYEditField.Layout.Row = 3;
fig.UserData.AuxTargetYEditField.Layout.Column = [5 6];


% SAGA-A Filters %
fig.UserData.TopoplotA = uicheckbox(L, "Value", 0, ...
    "Text", "Topo-A", ...
    "FontColor", "w", ...
    "FontName", "Tahom", ...
    "ValueChangedFcn", @handleTopoplotChange);
fig.UserData.TopoplotA.Layout.Row = 5;
fig.UserData.TopoplotA.Layout.Column = 2;
lab = uilabel(L,"Text", "A Cutoffs (Hz):", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 5;
lab.Layout.Column = 3;
fig.UserData.HPFFilterCutoffEditFieldA = uieditfield(L, 'numeric', ...
    "Value", 13, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.HPFFilterCutoffEditFieldA.Layout.Row = 5;
fig.UserData.HPFFilterCutoffEditFieldA.Layout.Column = 4;
fig.UserData.LPFFilterCutoffEditFieldA = uieditfield(L, 'numeric', ...
    "Value", 30, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.LPFFilterCutoffEditFieldA.Layout.Row = 5;
fig.UserData.LPFFilterCutoffEditFieldA.Layout.Column = 5;

fig.UserData.ToggleSquigglesModeButtonA = uibutton(L, "Text", "BPF Mode", ...
    'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma', ...
    'BackgroundColor',[0.7 0.3 0.7],'FontColor','w', 'FontWeight','bold', ...
    'UserData', struct("Mode","BPF","SAGA","A"));
fig.UserData.ToggleSquigglesModeButtonA.Layout.Row = 5;
fig.UserData.ToggleSquigglesModeButtonA.Layout.Column = 6;

% SAGA-B Filters % 
fig.UserData.TopoplotB = uicheckbox(L, "Value", 0, ...
    "Text", "Topo-B", ...
    "FontColor", "w", ...
    "FontName", "Tahom", ...
    "ValueChangedFcn", @handleTopoplotChange);
fig.UserData.TopoplotB.Layout.Row = 6;
fig.UserData.TopoplotB.Layout.Column = 2;
lab = uilabel(L,"Text", "B Cutoffs (Hz):", 'FontName', 'Tahoma','FontColor', 'w','HorizontalAlignment','right');
lab.Layout.Row = 6;
lab.Layout.Column = 3;
fig.UserData.HPFFilterCutoffEditFieldB = uieditfield(L, 'numeric', ...
    "Value", 100, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.HPFFilterCutoffEditFieldB.Layout.Row = 6;
fig.UserData.HPFFilterCutoffEditFieldB.Layout.Column = 4;
fig.UserData.LPFFilterCutoffEditFieldB = uieditfield(L, 'numeric', ...
    "Value", 500, ...
    "FontName", 'Consolas', ...
    'HorizontalAlignment', 'center', ...
    'ValueChangedFcn', @handleFilterCutoffChange);
fig.UserData.LPFFilterCutoffEditFieldB.Layout.Row = 6;
fig.UserData.LPFFilterCutoffEditFieldB.Layout.Column = 5;

fig.UserData.ToggleSquigglesModeButtonB = uibutton(L, "Text", "HPF Mode", ...
    'ButtonPushedFcn', @toggleSquigglesModeButtonPushed, 'FontName','Tahoma', ...
    'BackgroundColor',[0.7 0.7 0.3],'FontColor','k', 'FontWeight','bold', ...
    'UserData', struct("Mode","HPF","SAGA","B"));
fig.UserData.ToggleSquigglesModeButtonB.Layout.Row = 6;
fig.UserData.ToggleSquigglesModeButtonB.Layout.Column = 6;

fig.DeleteFcn = @handleFigureDeletion;

fig.UserData.UDP.UserData = struct(  ...
    'address', fig.UserData.Address, 'parameter_port', fig.UserData.ParameterPort, ...
    'n_hosts', config.Default.N_Host_Devices_Per_Controller,'n_acknowledged', 0, ...
    'button', struct('offset', fig.UserData.GetOffsetButton, 'scale', fig.UserData.GetScaleButton), ...
    'edit', struct('offset', fig.UserData.AuxOffsetEditField, 'scale', fig.UserData.AuxScaleEditField));
fig.UserData.UDP.configureCallback("terminator",@udpResponseHandler);

    function handleFilterCutoffChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf("n.%d:%d:%d:%d", ...
            src.Parent.Parent.UserData.HPFFilterCutoffEditFieldA.Value, ...
            src.Parent.Parent.UserData.LPFFilterCutoffEditFieldA.Value, ...
            src.Parent.Parent.UserData.HPFFilterCutoffEditFieldB.Value, ...
            src.Parent.Parent.UserData.LPFFilterCutoffEditFieldB.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent Filter Update: %s\n', cmd);
    end

    function toggleSquigglesModeButtonPushed(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        if src.UserData.Mode == "BPF"
            src.Text = "HPF Mode"; % Indicate we are now in HPF Mode
            src.BackgroundColor = [0.7 0.7 0.3];
            src.FontColor = 'k';
            src.UserData.Mode = "HPF";
            cmd = sprintf("w.%s.0",src.UserData.SAGA);
            writeline(udpSender,cmd,src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[AUX-CONTROLLER]::Sent request to toggle squiggles GUI to BPF mode.\n');
        else
            src.Text = "BPF Mode";
            src.BackgroundColor = [0.7 0.3 0.7];
            src.FontColor = 'w';
            src.UserData.Mode = "BPF";
            cmd = sprintf("w.%s.1",src.UserData.SAGA);
            writeline(udpSender,cmd,src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[AUX-CONTROLLER]::Sent request to toggle squiggles GUI to HPF mode.\n');
        end
    end

    function handleFigureDeletion(src,~)
        try
            delete(src.UserData.UDP);
        catch me
            disp(me.message);
            disp(me.stack(end));
        end

    end

    function handleAuxScaleChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_scale","value":%.3f,"extra":"refresh"}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for aux_scale change: %s\n', cmd);
    end

    function handleAuxOffsetChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_offset","value":%.3f,"extra":"refresh"}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for aux_offset change: %s\n', cmd);
    end

    function handleAuxSamplesChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_samples","value":%d,"extra":"convert"}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for aux_scale change: %s\n', cmd);
    end

    function handleAuxTargetEnable(src,~)
        if src.Value
            handleAuxTargetChange(src);
        else
            parsedData = struct('name', "aux_target", 'value', [], 'extra', "refresh");
            udpSender = src.Parent.Parent.UserData.UDP;
            jsonMessage = jsonencode(parsedData);
            cmd = sprintf('t.%s', jsonMessage);
            writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
            fprintf(1,'[AUX-CONTROLLER]::Sent JSON for aux_target change: %s\n', cmd);
        end
    end

    function handleAuxTargetChange(src,~)
        ys = src.Parent.Parent.UserData.AuxTargetYEditField.Value;
        xs = src.Parent.Parent.UserData.AuxTargetXEditField.Value;
        if ~startsWith(xs,"[")
            xs = strcat("[",xs,"];");
        elseif ~endsWith(xs,";")
            xs = strcat(xs,";");
        end
        xv = eval(xs);
        if startsWith(lower(ys),"@(x)")
            if ~endsWith(ys,";")
                ys = strcat(ys,";");
            end
            yf = eval(ys);
            yv = yf(xv);
        else
            if ~startsWith(ys,"[")
                ys = strcat("[",ys,"];");
            elseif ~endsWith(ys,";")
                ys = strcat(ys,";");
            end
            yv = eval(ys);
        end
        if numel(xv)~=numel(yv)
            warning("[AUX-CONTROLLER]::Number of X Targets (%d) does not equal number of Y Targets (%d).", numel(xv), numeL(yv));
            if numel(xv) < numel(yv)
                yv = yv(1:numel(xv));
                src.Parent.Parent.UserData.AuxTargetYEditField.Value = strcat("[",num2str(yv),"];");
                fprintf(1,'[AUX-CONTROLLER]::Reduced Y Targets but did not send parameter update.)\n')
            else
                xv = xv(1:numel(yv));
                src.Parent.Parent.UserData.AuxTargetXEditField.Value = strcat("[",num2str(xv),"];");
                fprintf(1,'[AUX-CONTROLLER]::Reduced X Targets but did not send parameter update.)\n')
            end
            return;
        end
            
        if ~src.Parent.Parent.UserData.EnableAuxTarget.Value
            return;
        end
        parsedData = struct('name', "aux_knots", 'value', [xv; yv], 'extra', "target");
        udpSender = src.Parent.Parent.UserData.UDP;
        jsonMessage = jsonencode(parsedData);
        cmd = sprintf('t.%s', jsonMessage);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for aux_target change: %s\n', cmd);
    end

    function handleAuxSagaChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_saga","value":"%s"}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for new aux_saga: %s\n', cmd);
    end

    function handleAuxChannelChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_channel","value":%d}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for new aux_channel: %s\n', cmd);
    end
    
    function handleTopoplotChange(src,~)
        udpSender = src.Parent.Parent.UserData.UDP;
        val = struct('A',src.Parent.Parent.UserData.TopoplotA.Value,'B',src.Parent.Parent.UserData.TopoplotB.Value);
        jsonMessage = jsonencode(val);
        cmd = sprintf('t.{"name":"topoplot","value":%s}', jsonMessage);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent topoplot change: %s\n', cmd);
    end

    function handleAuxAlphaChange(src, ~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_alpha","value":%d}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for new aux_alpha: %s\n', cmd);
    end

    function handleAuxErrorTolChange(src, ~)
        udpSender = src.Parent.Parent.UserData.UDP;
        cmd = sprintf('t.{"name":"aux_error_tol","value":%d}', src.Value);
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent JSON for new aux_error_tol: %s\n', cmd);
    end

    function handleOffsetRequest(src, ~)
        udpSender = src.Parent.Parent.UserData.UDP;
        data = struct('name', "get", 'value', "get_aux_offset", ...
            'address', src.Parent.Parent.UserData.ReturnAddress, ...
            'port', src.Parent.Parent.UserData.ReturnPort );
        cmd = sprintf("t.%s", jsonencode(data));
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent `get_aux_offset` request: %s\n', cmd);
    end
    function handleScaleRequest(src, ~)
        udpSender = src.Parent.Parent.UserData.UDP;
        data = struct('name', "get", 'value', "get_aux_scale", ...
            'address', src.Parent.Parent.UserData.ReturnAddress, ...
            'port', src.Parent.Parent.UserData.ReturnPort );
        cmd = sprintf("t.%s", jsonencode(data));
        writeline(udpSender, cmd, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.ParameterPort);
        fprintf(1,'[AUX-CONTROLLER]::Sent `get_aux_scale` request: %s\n', cmd);
    end
    function udpResponseHandler(src,~)
        msg = src.readline();
        data = jsondecode(msg);
        switch string(lower(data.name))
            case "aux_offset"
                src.UserData.edit.offset.Value = data.value;
                src.UserData.button.offset.BackgroundColor = [0.1 0.8 0.1];
                handleAuxOffsetChange(src.UserData.edit.offset);
            case "aux_scale"
                src.UserData.edit.scale.Value = data.value;
                src.UserData.button.scale.BackgroundColor = [0.1 0.8 0.1];
                handleAuxScaleChange(src.UserData.edit.scale);
            otherwise
                fprintf(1,'[AUX-CONTROLLER]::Received unhandled UDP `response`: %s\n', msg);
        end
    end

end