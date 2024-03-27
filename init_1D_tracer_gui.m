function guiTimer = init_1D_tracer_gui(options)
%INIT_1D_TRACER_GUI  Initializes 1D tracer GUI figure and handles

arguments
    options.SaveFolder = 'C:/Data/TrackerLogs/1D';
    options.LogIdentifier = '1D';
    options.Block = 100;
    options.FileString = 'C:/Users/Daily/TempData/%s/%s_%04d_%04d_%02d_%%s_%d';
    options.Subject = 'MCP01';
    options.RefreshRate = 30; % (frames per second)
    options.Duration = 30; % Seconds
    options.Frequency = 0.5;  % Hz (for sine signal type)
    options.AxesWidth = 1; % Second
    options.ErrorTolerance = 0.25; % a.u.
    options.TMSiAddress = "192.168.88.100";
    options.Signal = [];
    options.SignalType {mustBeMember(options.SignalType, {'sine', 'interp'})} = 'sine';
end
guiTimer = timer(...
    'Name', '1D-Tracer-Timer', ...
    'Period', round(1/options.RefreshRate,3), ...
    'ExecutionMode', 'fixedRate', ...
    'TimerFcn', @gui_1d_timer_callback, ...
    'StartFcn', @startMicrocontrollerIfPresent, ...
    'StopFcn', @stopMicrocontrollerAndSave);
guiTimer.UserData = struct;
guiTimer.UserData.Figure = figure('Color','w','Name','1D Tracer GUI', ...
    'Position',[500, 100, 560, 650]);
guiTimer.UserData.Teensy = [];
guiTimer.UserData.Axes = axes(guiTimer.UserData.Figure,'NextPlot','add','YLim',[-1-(1.5*options.ErrorTolerance), 1+(1.5*options.ErrorTolerance)],'FontName','Tahoma','XColor','none','YColor','none');
guiTimer.UserData.Text = title(guiTimer.UserData.Axes, "Follow the Line", 'FontName','Tahoma','Color','k');
t = 0:(1/options.RefreshRate):options.Duration;

switch options.SignalType
    case 'sine'
        sig = sin(2*pi*options.Frequency.*t);
    case 'interp'
        if isempty(options.Signal)
            error("No signal to interpolate!");
        end
        t_sig = linspace(0,options.Duration,numel(options.Signal));
        sig = interp1(t_sig, options.Signal, t, 'pchip');
        sig = sig ./ max(abs(sig));
end

t_interp = linspace(0,options.Duration,10*numel(t));
sig_interp = interp1(t, sig, t_interp, "pchip");
patch(guiTimer.UserData.Axes, 'Faces', [1:(2*numel(t_interp)),1], ...
    'Vertices', [[t_interp, fliplr(t_interp)]', [sig_interp-options.ErrorTolerance, fliplr(sig_interp+options.ErrorTolerance)]'], ...
    'EdgeColor','none','FaceColor',[0.9 0.9 0.9]);
guiTimer.UserData.Target = line(guiTimer.UserData.Axes, t_interp, sig_interp, 'LineWidth', 10, 'Color', 'b');
guiTimer.UserData.Cursor = scatter(guiTimer.UserData.Axes, 0, 0, 'Marker', 'o', 'MarkerEdgeColor', 'k', 'LineWidth', 2,'SizeData',64);
guiTimer.UserData.AxesWidth = options.AxesWidth;
guiTimer.UserData.CurrentTimeIndex = 1;
guiTimer.UserData.Signal = sig;
guiTimer.UserData.Time = t;
guiTimer.UserData.Value = zeros(size(t));
guiTimer.UserData.ErrorTolerance = options.ErrorTolerance;
guiTimer.UserData.SaveFolder = options.SaveFolder;
guiTimer.UserData.LogIdentifier = options.LogIdentifier;
guiTimer.UserData.Notes = "";
guiTimer.UserData.UDP = udpport("byte");
guiTimer.UserData.FileString = options.FileString;
guiTimer.UserData.Subject = options.Subject;
guiTimer.UserData.Block = options.Block;
guiTimer.UserData.TMSiAddress = options.TMSiAddress;
xlim(guiTimer.UserData.Axes,[-options.AxesWidth/2, options.AxesWidth/2]);

end