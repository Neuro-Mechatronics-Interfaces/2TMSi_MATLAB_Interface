function neo = init_neo_gui(neo, threshold, options)
%INIT_NEO_GUI  Initialize GUI for nonlinear energy operator timeline streams
arguments
    neo
    threshold (1,1) double
    options.FigurePosition (1,4) double = [1051, 123, 710, 813];
end

if ~isempty(neo.fig)
    delete(neo.fig);
    neo.fig = [];
    neo.h = [];
end

if ~neo.enable
    return;
end

neo.fig = figure(...
    'Name', 'TMSi Squiggles', ...
    'Color', 'w', ...
    'Position', options.FigurePosition);

ax = axes(neo.fig,'NextPlot','add','FontName','Tahoma', ...
    'XLim',[1, neo.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none');
neo.h = struct;
neo.h.xline = xline(ax, neo.n_samples/2, ...
    'k:', seconds_2_str(0.5));
if isinf(threshold)
    threshold = 0;
end
neo.h.yline = yline(ax, threshold, 'm--', "Threshold", 'LineWidth', 1.5);
neo.h.data = plot(ax, ...
    1:neo.n_samples, ...
    nan(1, neo.n_samples), ...
    'Color', neo.color.(neo.saga));
neo.h.title = title(ax, ...
    sprintf("NEO Stream %s-%02d", neo.saga, neo.channel), ...
    'FontName', 'Tahoma', 'Color', neo.color.(neo.saga));
neo.h.subtitle = subtitle(ax, ...
    sprintf("Calibration: %s", neo.state), 'FontName','Tahoma', ...
    'Color', [0.65 0.65 0.65]);

end