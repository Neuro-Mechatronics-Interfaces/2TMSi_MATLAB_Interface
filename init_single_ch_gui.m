function sch = init_single_ch_gui(sch, threshold, options)
%INIT_SINGLE_CH_GUI  Initialize GUI for single-channel timeline streams
arguments
    sch
    threshold (1,1) double
    options.FigurePosition (1,4) double = [800, 300, 720, 500];
end

if ~isempty(sch.fig)
    delete(sch.fig);
    sch.fig = [];
    sch.h = [];
end

if ~sch.enable
    return;
end

sch.fig = figure(...
    'Name', 'TMSi Single-Channel', ...
    'Color', 'w', ...
    'Position', options.FigurePosition);

ax = axes(sch.fig,'NextPlot','add','FontName','Tahoma', ...
    'XLim',[1, sch.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none');
sch.h = struct;
sch.h.xline = xline(ax, sch.n_samples/2, ...
    'k:', seconds_2_str(0.5));
if isinf(threshold) || isnan(threshold)
    threshold = 0;
elseif abs(threshold) > eps
    ylim(ax, [-1.5*threshold, 1.5*threshold]);
end
sch.h.yline = yline(ax, threshold, 'm--', "Threshold", 'LineWidth', 1.5);
cdata = validatecolor(sch.color.(sch.saga));
cdata = cdata * 0.6 + [0.35 0.35 0.35];
sch.h.data = plot(ax, ...
    1:sch.n_samples, ...
    nan(1, sch.n_samples), ...
    'Color', cdata);
sch.h.title = title(ax, ...
    sprintf("Stream %s-%02d", sch.tag.(sch.saga), sch.channel), ...
    'FontName', 'Tahoma', 'Color', cdata);
sch.h.subtitle = subtitle(ax, ...
    sprintf("Calibration: %s", strrep(sch.state,"_","\_")), 'FontName','Tahoma', ...
    'Color', [0.65 0.65 0.65]);

end