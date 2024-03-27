function fig = init_controller_fig()

fig = uifigure('Color','w','MenuBar','none','ToolBar','none','Name','TMSi Recording Controller','Position',[138   760   560    87],'Icon',"TMSi.png");
L = uigridlayout(fig, [2, 5],'BackgroundColor','k');
L.RowHeight = {'1x', 'fit'};
L.ColumnWidth = {'1x', '1x', '1x', '1x', '1x'};

fig.UserData = struct;
fig.UserData.UDP = udpport("byte");
fig.UserData.Block = 0;

config = load_spike_server_config();
fig.UserData.Address = config.UDP.Socket.StreamService.Address;
fig.UserData.StatePort = config.UDP.Socket.StreamService.Port.state;
fig.UserData.NamePort = config.UDP.Socket.StreamService.Port.name;

dt = datetime('today','TimeZone','America/New_York');
tank = sprintf('%s_%04d_%02d_%02d', config.Default.Subject, year(dt), month(dt), day(dt));
nameEdit = uieditfield(L, "Value", sprintf('%s/%s/%s/%s_%%%%s_%%d.poly5', config.Default.Folder, config.Default.Subject, tank, tank), ...
    "ValueChangedFcn", @nameFieldValueChanged, "FontName", 'Consolas');
nameEdit.Layout.Row = 1;
nameEdit.Layout.Column = [1 5];

idleButton = uibutton(L, "Text", "IDLE", 'ButtonPushedFcn', @idleButtonPushed,'FontName','Tahoma');
idleButton.Layout.Row = 2;
idleButton.Layout.Column = 1;

runButton = uibutton(L, "Text", "RUN", 'ButtonPushedFcn', @runButtonPushed,'FontName','Tahoma');
runButton.Layout.Row = 2;
runButton.Layout.Column = 2;

recButton = uibutton(L, "Text", "REC", 'ButtonPushedFcn', @recButtonPushed,'FontName','Tahoma');
recButton.Layout.Row = 2;
recButton.Layout.Column = 3;

impButton = uibutton(L, "Text", "IMP", 'ButtonPushedFcn', @impButtonPushed,'FontName','Tahoma');
impButton.Layout.Row = 2;
impButton.Layout.Column = 4;

quitButton = uibutton(L, "Text", "QUIT", 'ButtonPushedFcn', @quitButtonPushed,'FontName','Tahoma');
quitButton.Layout.Row = 2;
quitButton.Layout.Column = 5;


end

function nameFieldValueChanged(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
fixedValue = string(src.Value);
if ~contains(fixedValue, ".poly5")
    fixedValue = strcat(fixedValue, ".poly5");
end
if ~contains(fixedValue, "%%s")
    fixedValue = strrep(fixedValue, ".poly5", "_%%s.poly5");
end
if ~contains(fixedValue, "%d")
    fixedValue = strrep(fixedValue, ".poly5", "_%d.poly5");
end
s = sprintf(fixedValue, src.Parent.Parent.UserData.Block);
writeline(udpSender, s, src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.NamePort)
fprintf(1,'[CONTROLLER]::Sent name: %s\n', s);

end

function recButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'rec', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
src.Parent.Parent.UserData.Block = src.Parent.Parent.UserData.Block + 1;
end

function runButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'run', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
end

function impButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'imp', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
end

function idleButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'idle', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
end

function quitButtonPushed(src, ~)
udpSender = src.Parent.Parent.UserData.UDP;
writeline(udpSender, 'quit', src.Parent.Parent.UserData.Address, src.Parent.Parent.UserData.StatePort);
end