function squiggles = init_squiggles_gui(squiggles, options)
%INIT_SQUIGGLES_GUI  Initialize GUI for stream "time line squiggles"
arguments
    squiggles
    options.FigurePosition (1,4) double = [137, 103, 710, 813];
end

if ~isempty(squiggles.fig)
    delete(squiggles.fig);
    squiggles.fig = [];
    squiggles.h = [];
end

if ~squiggles.enable
    return;
end

squiggles.fig = figure(...
    'Name', 'TMSi Squiggles', ...
    'Color', 'w', ...
    'Position', options.FigurePosition);

ax = axes(squiggles.fig,...
    'NextPlot','add','FontName','Tahoma', ...
    'XLim',[1, squiggles.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none');
squiggles.h = struct;
squiggles.h.xline = xline(ax, squiggles.n_samples/2, ...
    'k:', seconds_2_str(0.5));
squiggles.h.A = plot(ax, 1:squiggles.n_samples, nan(numel(squiggles.channels.A),squiggles.n_samples), 'Color', squiggles.color.A);
squiggles.h.B = plot(ax, 1:squiggles.n_samples, nan(numel(squiggles.channels.B),squiggles.n_samples), 'Color', squiggles.color.B);
title(ax, sprintf("A: %s | B: %s", squiggles.color.A, squiggles.color.B), ...
    'FontName', 'Tahoma', 'Color', 'k');

end