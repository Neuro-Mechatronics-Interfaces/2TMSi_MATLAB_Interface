function fig = init_microcontroller_listener_fig(options)

arguments
    options.SerialDevice {mustBeTextScalar} = "";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger} = 115200;
end

if strlength(options.SerialDevice) < 1
    sList = serialportlist();
    if numel(sList) > 1
        error("Multiple serial devices detected: ['%s']\n\t->\tSpecify correct device using SerialDevice option.", strjoin(s,"'; '"));
    elseif numel(sList) < 1
        teensy = [];
        warning("No serial devices detected! Sync signal will not be sent on Recording start/stop.");
    else
        teensy = serialport(sList, options.BaudRate);
    end
else
    teensy = serialport(options.SerialDevice, options.BaudRate);
end

fig = uifigure('Name','Microcontroller Listener','Color','k',...
    'WindowStyle','alwaysontop','Units','inches',...
    'Position',[1 1 5 0.75],'MenuBar','none','ToolBar','none','Icon','baseline_file_upload_black_24dp.png');
L = uigridlayout(fig,[1 1],'BackgroundColor','k');
uilabel(L,"Text", "spacebar (toggle) | 1/q | 2/w | 3/e | 4/r | escape (clear)", ...
    'HorizontalAlignment','center', ...
    'VerticalAlignment','center',...
    'FontName','Consolas',...
    'FontColor',[1 1 1], ...
    'FontWeight','bold',...
    'FontSize',16);

fig.UserData = teensy;
fig.DeleteFcn = @handleFigureClosing;
fig.WindowKeyPressFcn = @handleWindowKeypress;

    function handleWindowKeypress(src,evt)
        switch evt.Key
            case 'esc'
                write(src.UserData,'0','char');
            case 'space'
                write(src.UserData,'1','char');
            case {'q','1'}
                write(src.UserData,'2','char');
            case {'w','2'}
                write(src.UserData,'3','char');
            case {'e','3'}
                write(src.UserData,'4','char');
            case {'r','4'}
                write(src.UserData,'5','char');
            otherwise
                disp(evt);
        end
    end

    function handleFigureClosing(src,~)
        try %#ok<TRYNC>
            write(src.UserData,'0','char');
        end
        try %#ok<TRYNC>
            delete(src.UserData);
        end
    end

end