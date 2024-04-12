function squiggles = init_squiggles_gui(squiggles, options)
%INIT_SQUIGGLES_GUI  Initialize GUI for stream "time line squiggles"
arguments
    squiggles
    options.FigurePosition (1,4) double = [nan, nan, nan, nan];
end

if any(isnan(options.FigurePosition))
    switch getenv("COMPUTERNAME")
        case 'MAX_LENOVO'
            pos = [  50,  100, 1200,  700]; 
        otherwise
            pos = [  50,  100,  720,  800];
    end
else
    
end

if ~isempty(squiggles.fig)
    delete(squiggles.fig);
    squiggles.fig = [];
    squiggles.h = [];
end

if ~squiggles.enable
    return;
end

cA = validatecolor(squiggles.color.A) * 0.7 + ones(1,3).*0.1;
cB = validatecolor(squiggles.color.B) * 0.7 + ones(1,3).*0.1;
x_init = 1:squiggles.n_samples;
y_init = nan(1, squiggles.n_samples);
% n_tot = numel(squiggles.channels.A) + numel(squiggles.channels.B);
y_lim = [-squiggles.offset, 8*squiggles.offset];

squiggles.fig = figure(...
    'Name', 'TMSi Squiggles', ...
    'Color', 'w', ...
    'Position', pos);
squiggles.h = struct;

L = tiledlayout(squiggles.fig, 9, 1);
nRowsMain = 9 - double(squiggles.acc.enable) - double(squiggles.triggers.enable);
ax = nexttile(L, 1, [nRowsMain, 1]);
set(ax,...
    'NextPlot','add','FontName','Tahoma', ...
    'Clipping', 'off', ...
    'XLim',[0, 19*squiggles.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none', 'YLim', y_lim);
title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}%s \\color{black}  |   \\color[rgb]{%3.1f,%3.1f,%3.1f}%s", ...
    cA(1),cA(2),cA(3),squiggles.tag.A, cB(1),cB(2),cB(3), squiggles.tag.B), 'FontName', 'Tahoma');


% squiggles.h.xline = xline(ax, squiggles.n_samples/2, ...
%     'k:', seconds_2_str(0.5));
squiggles.h.A = gobjects(numel(squiggles.channels.A),1);
grid_channels = squiggles.channels.A(squiggles.channels.A <= 64);
for ii = 1:numel(grid_channels)
    squiggles.h.A(ii) = line(ax, x_init + floor((grid_channels(ii)-1)/8) * 1.1 * squiggles.n_samples, y_init, ...
        'LineWidth', 0.25, ...
        'Color', cA + ones(1,3).*(floor((grid_channels(ii)-1)/32)).*0.2);
end
squiggles.h.B = gobjects(numel(squiggles.channels.B),1);
grid_channels = squiggles.channels.B(squiggles.channels.B <= 64);
for ii = 1:numel(grid_channels)
    squiggles.h.B(ii) = line(ax, x_init + floor((grid_channels(ii)-1)/8) * 1.1 * squiggles.n_samples + 10*squiggles.n_samples, y_init, ...
        'LineWidth', 0.25, ...
        'Color', cB + ones(1,3).*(floor((grid_channels(ii)-1)/32)).*0.2);
end

% Add scalebar to plot
x0 = -squiggles.n_samples*0.5;
tx = sprintf('%d ms', round(-x0/4)); % time scalebar text
y0 = -squiggles.offset*0.4;
ty = sprintf('%d μV', round(y0)); % vertical scalebar text
line(ax, [x0, x0], [y0,  0], 'Color','k','LineWidth',1.25,'LineStyle','-');
line(ax, [x0,  0], [y0, y0], 'Color','k','LineWidth',1.25,'LineStyle','-');
text(ax, -0.6*squiggles.n_samples, -0.2*squiggles.offset, ty, 'FontName','Tahoma','HorizontalAlignment','right');
text(ax, -0.2*squiggles.n_samples, -0.45*squiggles.offset, tx, 'FontName','Tahoma','VerticalAlignment','top');

if squiggles.acc.enable
    ax = nexttile(L, nRowsMain+1, [1 1]);
    set(ax,...
        'NextPlot','add','FontName','Tahoma', ...
        'XLim',[1, squiggles.n_samples], 'XTick', [], ...
        'XColor','none','YColor','none', 'YLim', [-3.5, 17.5]);
    title(ax, "Acc: \color{black}Distal | \color[rgb]{0.33,0.33,0.33}Medial \color{black} | \color[rgb]{0.66,0.66,0.66}Superior ", 'FontName', 'Tahoma');
    squiggles.h.Pose = subtitle(ax, "Pose: Unknown", 'FontName', 'Tahoma', 'Color', [0.65 0.65 0.65]); % Can update using `updatePose(squiggles, "MID");` for example
    squiggles.h.Acc.Distal = line(ax, x_init, y_init, 'Color', 'k', 'LineWidth', 1.25);
    squiggles.h.Acc.Medial = line(ax, x_init, y_init, 'Color', [0.33, 0.33, 0.33], 'LineWidth', 1.25);
    squiggles.h.Acc.Superior = line(ax, x_init, y_init, 'Color', [0.66, 0.66, 0.66], 'LineWidth', 1.25);
else
    squiggles.h.Pose = [];
    squiggles.h.Acc = [];
end

if squiggles.triggers.enable
    ax = nexttile(L, nRowsMain+1+double(squiggles.acc.enable), [1 1]);
    set(ax,...
        'NextPlot','add','FontName','Tahoma', ...
        'XLim',[1, squiggles.n_samples], 'XTick', [], ...
        'XColor','none','YColor','none', ...
        'YLim', [0, squiggles.triggers.y_bound]);
    cLeft = cA;
    cRight = cB;
    title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}A Triggers \\color{black} | \\color[rgb]{%3.1f,%3.1f,%3.1f}B Triggers", ...
        cLeft(1),cLeft(2),cLeft(3),cRight(1),cRight(2),cRight(3)), 'FontName', 'Tahoma');

    squiggles.h.Triggers.A = line(ax, x_init, y_init, 'Color', cLeft, 'LineWidth', 1.0);
    squiggles.h.Triggers.B = line(ax, x_init, y_init, 'Color', cRight, 'LineWidth', 1.0);
else
    squiggles.h.Triggers.A = [];
    squiggles.h.Triggers.B = [];
end
% fprintf(1,'[TMSi]::[Squiggles] GUI initialized.\n');
end