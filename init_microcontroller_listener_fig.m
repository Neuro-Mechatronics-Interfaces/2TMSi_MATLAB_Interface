function [fig, teensy] = init_microcontroller_listener_fig(options)
%INIT_MICROCONTROLLER_LISTENER_FIG Initialize the listener fig for controlling microcontroller write to synchronization output bits.
%
% Syntax:
%   fig = init_microcontroller_listener_fig('Name',value,...);
arguments
    options.SerialDevice {mustBeTextScalar} = "";
    options.BaudRate (1,1) {mustBePositive, mustBeInteger} = 115200;
end

teensy = connect_teensy('SerialDevice', options.SerialDevice, ...
                        'BaudRate', options.BaudRate);
if isempty(teensy)
    error("Could not connect to Teensy device with PORT='%s' and BAUD=%d.", ...
        options.SerialDevice, options.BaudRate);
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