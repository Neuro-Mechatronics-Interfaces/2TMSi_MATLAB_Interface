function squiggles = init_squiggles_gui(squiggles, options)
%INIT_SQUIGGLES_GUI  Initialize GUI for stream "time line squiggles"
arguments
    squiggles
    options.FigurePosition (1,4) double = [50, 100, 720, 800];
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
n_tot = numel(squiggles.channels.A) + numel(squiggles.channels.B);
y_lim = [-squiggles.offset/2, (n_tot-0.5)*squiggles.offset];

squiggles.fig = figure(...
    'Name', 'TMSi Squiggles', ...
    'Color', 'w', ...
    'Position', options.FigurePosition);
squiggles.h = struct;

L = tiledlayout(squiggles.fig, 9, 1);
nRowsMain = 9 - double(squiggles.acc.enable) - double(squiggles.thumb.enable) - double(squiggles.triggers.enable);
ax = nexttile(L, 1, [nRowsMain, 1]);
set(ax,...
    'NextPlot','add','FontName','Tahoma', ...
    'Clipping', 'off', ...
    'XLim',[1, squiggles.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none', 'YLim', y_lim);
title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}A \\color{black}  |   \\color[rgb]{%3.1f,%3.1f,%3.1f}B", ...
    cA(1),cA(2),cA(3),cB(1),cB(2),cB(3)), 'FontName', 'Tahoma');


squiggles.h.xline = xline(ax, squiggles.n_samples/2, ...
    'k:', seconds_2_str(0.5));
squiggles.h.A = gobjects(numel(squiggles.channels.A),1);
tmp_offset = 0;
for ii = 1:numel(squiggles.channels.A)
    squiggles.h.A(ii) = line(ax, x_init, y_init, ...
        'LineWidth', 0.25, ...
        'Color', cA + ones(1,3).*(floor((squiggles.channels.A(ii)-2)/32)).*0.2);
    text(ax, -10, tmp_offset, num2str(squiggles.channels.A(ii)), 'HorizontalAlignment', 'right', ...
        'FontSize', 5, 'FontName','Tahoma','Color', cA + ones(1,3).*(floor((squiggles.channels.A(ii)-2)/32)).*0.2)
    tmp_offset = tmp_offset + squiggles.offset;
end
squiggles.h.B = gobjects(numel(squiggles.channels.B),1);
for ii = 1:numel(squiggles.channels.B)
    squiggles.h.B(ii) = line(ax, x_init, y_init, ...
        'LineWidth', 0.25, ...
        'Color', cB + ones(1,3).*(floor((squiggles.channels.B(ii)-2)/32)).*0.2);
    text(ax, -10, tmp_offset, num2str(squiggles.channels.B(ii)), 'HorizontalAlignment', 'right', ...
        'FontSize', 5, 'FontName','Tahoma','Color', cB + ones(1,3).*(floor((squiggles.channels.B(ii)-2)/32)).*0.2)
    tmp_offset = tmp_offset + squiggles.offset;
end

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

if squiggles.thumb.enable
    ax = nexttile(L, nRowsMain+1+double(squiggles.acc.enable), [1 1]);
    set(ax,...
        'NextPlot','add','FontName','Tahoma', ...
        'XLim',[1, squiggles.n_samples], 'XTick', [], ...
        'XColor','none','YColor','none', ...
        'YLim', [-squiggles.offset, squiggles.offset*3]);
    cLeft = cA + ones(1,3).*0.2;
    cRight = cB + ones(1,3).*0.2;
    title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}Left Thumb \\color{black} | \\color[rgb]{%3.1f,%3.1f,%3.1f}Right Thumb", ...
        cLeft(1),cLeft(2),cLeft(3),cRight(1),cRight(2),cRight(3)), 'FontName', 'Tahoma');

    squiggles.h.LeftThumb = line(ax, x_init, y_init, 'Color', cLeft, 'LineWidth', 1.0);
    squiggles.h.RightThumb = line(ax, x_init, y_init, 'Color', cRight, 'LineWidth', 1.0);
else
    squiggles.h.LeftThumb = [];
    squiggles.h.RightThumb = [];
end

if squiggles.triggers.enable
        ax = nexttile(L, nRowsMain+1+double(squiggles.acc.enable)+double(squiggles.thumb.enable), [1 1]);
    set(ax,...
        'NextPlot','add','FontName','Tahoma', ...
        'XLim',[1, squiggles.n_samples], 'XTick', [], ...
        'XColor','none','YColor','none', ...
        'YLim', [0, 64]);
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