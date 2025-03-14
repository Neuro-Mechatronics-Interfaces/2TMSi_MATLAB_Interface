function squiggles = init_squiggles_gui(squiggles, options)
%INIT_SQUIGGLES_GUI  Initialize GUI for stream "time line squiggles"
arguments
    squiggles
    options.FigurePosition (1,4) double = [nan, nan, nan, nan];
    options.AuxChannel (1,1) double {mustBeInteger} = 0;
    options.AuxSAGA {mustBeMember(options.AuxSAGA,{'A','B'})} = 'A';
    options.AuxSamples (1,1) double {mustBeInteger, mustBePositive} = 20000;
    options.AuxTarget double = []; % Set "target line" samples
    options.TopoLayoutFile (1,1) string = "EEGChannels64TMSi.mat";
    options.Topoplot (1,1) struct = struct('A', false, 'B', false);
    options.TopoMarkerSize (1,1) double = 256;
end

if any(isnan(options.FigurePosition))
    switch getenv("COMPUTERNAME")
        case 'MAX_LENOVO'
            pos = [  50,  100, 1200,  700]; 
        otherwise
            pos = [  50,  100,  720,  800];
    end
else
    pos = [  50,  100,  720,  800];
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
y_lim = [-squiggles.offset, (8 + double(options.AuxChannel > 0))*squiggles.offset ];

squiggles.fig = figure(...
    'Name', 'TMSi Squiggles', ...
    'Color', 'w', ...
    'Position', pos);
squiggles.h = struct;

L = tiledlayout(squiggles.fig, 9, 1);
nRowsMain = 9 - double(squiggles.triggers.enable);
ax = nexttile(L, 1, [nRowsMain, 1]);
set(ax,...
    'NextPlot','add','FontName','Tahoma', ...
    'Clipping', 'off', ...
    'XLim',[0, 19*squiggles.n_samples], 'XTick', [], ...
    'XColor','none','YColor','none', 'YLim', y_lim, ...
    'CLim', [0, 1.5*squiggles.offset], ...
    'Colormap', turbo(256));
if squiggles.whiten.A
    a_tag = sprintf('%s_{Whitened}',strrep(squiggles.tag.A,"_","\_"));
else
    a_tag = strrep(squiggles.tag.A,"_","\_");
end
if squiggles.whiten.B
    b_tag = sprintf('%s_{Whitened}',strrep(squiggles.tag.B,"_","\_"));
else
    b_tag = strrep(squiggles.tag.B,"_","\_");
end
title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}%s \\color{black}  |   \\color[rgb]{%3.1f,%3.1f,%3.1f}%s", ...
    cA(1),cA(2),cA(3),a_tag, cB(1),cB(2),cB(3), b_tag), 'FontName', 'Tahoma');


% squiggles.h.xline = xline(ax, squiggles.n_samples/2, ...
%     'k:', seconds_2_str(0.5));
if options.Topoplot.A
    ChanLocs = getfield(load(options.TopoLayoutFile,'ChanLocs'),'ChanLocs');
    squiggles.h.A = scatter(ax, ([ChanLocs.X])*squiggles.n_samples*3.5 + 4*squiggles.n_samples, ([ChanLocs.Y])*(3.5*squiggles.offset)+4*squiggles.offset, ...
        'Marker', 'o', 'SizeData', ones(1,64).*options.TopoMarkerSize, ...
        'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'k', ...
        'CData', zeros(1,64));
    for ii = 1:64
        text(ax, ChanLocs(ii).X*squiggles.n_samples*3.5 + 4*squiggles.n_samples, ChanLocs(ii).Y*3.5*squiggles.offset + 4*squiggles.offset, ChanLocs(ii).labels, ...
            'FontSize', 12, 'FontName', 'Consolas', ...
            'HorizontalAlignment', 'center', 'Color', 'w', ...
            'FontWeight', 'bold');
    end
else
    squiggles.h.A = gobjects(numel(squiggles.channels.A),1);
    grid_channels = squiggles.channels.A(squiggles.channels.A <= 64);
    for ii = 1:numel(grid_channels)
        x_offset = floor((grid_channels(ii)-1)/8) * 1.1 * squiggles.n_samples;
        cur_cdata = cA + ones(1,3).*(floor((grid_channels(ii)-1)/32)).*0.2;
        squiggles.h.A(ii) = line(ax, x_init + x_offset, y_init, ...
            'LineWidth', 0.25, ...
            'Color', cur_cdata);
        cur_ch = squiggles.channels.A(ii);
        yText = (8.5-rem((cur_ch-1),8))*squiggles.offset;
        xText = x_offset + 0.5*squiggles.n_samples;
        text(ax, xText, yText, sprintf("A-%02d", cur_ch), ...
            'FontSize', 6, 'FontName', 'Consolas', ...
            'HorizontalAlignment', 'center', 'Color', cur_cdata);
    
    end
end

if options.Topoplot.B
    ChanLocs = getfield(load(options.TopoLayoutFile,'ChanLocs'),'ChanLocs');
    squiggles.h.B = scatter(ax, ([ChanLocs.X])*squiggles.n_samples*3.5 + 12*squiggles.n_samples, ([ChanLocs.Y])*(3.5*squiggles.offset)+4*squiggles.offset, ...
        'Marker', 'o', 'SizeData', ones(1,64).*options.TopoMarkerSize, ...
        'MarkerFaceColor', 'flat', 'MarkerEdgeColor', 'k', ...
        'CData', zeros(1,64));
    for ii = 1:64
        text(ax, ChanLocs(ii).X*squiggles.n_samples*3.5 + 12*squiggles.n_samples, ChanLocs(ii).Y*3.5*squiggles.offset + 4*squiggles.offset, ChanLocs(ii).labels, ...
            'FontSize', 12, 'FontName', 'Consolas', ...
            'HorizontalAlignment', 'center', 'Color', 'w', ...
            'FontWeight', 'bold');
    end
else
    squiggles.h.B = gobjects(numel(squiggles.channels.B),1);
    grid_channels = squiggles.channels.B(squiggles.channels.B <= 64);
    for ii = 1:numel(grid_channels)
        x_offset = floor((grid_channels(ii)-1)/8) * 1.1 * squiggles.n_samples + 10*squiggles.n_samples;
        cur_cdata =  cB + ones(1,3).*(floor((grid_channels(ii)-1)/32)).*0.2;
        squiggles.h.B(ii) = line(ax, x_init + x_offset, y_init, ...
            'LineWidth', 0.25, ...
            'Color', cur_cdata);
        cur_ch = squiggles.channels.B(ii);
        yText = (8.5-rem((cur_ch-1),8))*squiggles.offset;
        xText = x_offset + 0.5*squiggles.n_samples;
        text(ax, xText, yText, sprintf("B-%02d", cur_ch), ...
            'FontSize', 6, 'FontName', 'Consolas', ...
            'HorizontalAlignment', 'center', 'Color', cur_cdata);
    end
end

if options.AuxChannel > 0
    x_aux = linspace(1,18.8 * squiggles.n_samples, options.AuxSamples);
    text(ax, 0, 9.1*squiggles.offset, ...
        sprintf("AUX (%s-%02d):", strrep(squiggles.tag.(options.AuxSAGA),'_','\_'), options.AuxChannel), ...
        'Color', 'k', 'FontSize', 12, 'FontName', 'Consolas','VerticalAlignment','bottom');
    if ~isempty(options.AuxTarget)
        if numel(options.AuxTarget) < options.AuxSamples
            warning("Fewer Target samples than Aux Line length! Target must be greater than or exceed that length! No Target line will be shown.");
            squiggles.h.AuxTarget = [];
        else
            squiggles.h.AuxTarget = line(ax, x_aux, options.AuxTarget(1:options.AuxSamples).*squiggles.offset + ones(1,options.AuxSamples) .* 8 .* squiggles.offset, ...
                'LineWidth', 3.5, 'Color', 'r', 'LineStyle', '-');
            text(ax, 18.8*squiggles.n_samples, 9.1*squiggles.offset, ...
                 "TARGET", 'HorizontalAlignment','right','VerticalAlignment','bottom',...
                'Color', 'r', 'FontSize', 12, 'FontName', 'Consolas');
            squiggles.aux_target_index = options.AuxSamples;
            squiggles.aux_target_count = numel(options.AuxTarget);
        end
    else
        squiggles.h.AuxTarget = [];
    end
    squiggles.h.Aux = line(ax, x_aux, ones(1,options.AuxSamples) .* 8 .* squiggles.offset, ...
        'LineWidth', 2.5, 'Color', 'k');
else
    squiggles.h.Aux = [];
    squiggles.h.AuxTarget = [];
end

% Add scalebar to plot
x0 = -squiggles.n_samples*0.5;
tx = sprintf('%d ms', round(-x0/4)); % time scalebar text
y0 = -squiggles.offset*0.4;
ty = sprintf('%d μV', round(abs(y0))); % vertical scalebar text
line(ax, [x0, x0], [y0,  0], 'Color','k','LineWidth',1.25,'LineStyle','-');
line(ax, [x0,  0], [y0, y0], 'Color','k','LineWidth',1.25,'LineStyle','-');
text(ax, -0.6*squiggles.n_samples, -0.2*squiggles.offset, ty, 'FontName','Tahoma','HorizontalAlignment','right');
text(ax, -0.2*squiggles.n_samples, -0.45*squiggles.offset, tx, 'FontName','Tahoma','VerticalAlignment','top');

if squiggles.triggers.enable
    ax = nexttile(L, nRowsMain+1, [1 1]);
    set(ax,...
        'NextPlot','add','FontName','Tahoma', ...
        'XLim',[1, squiggles.n_samples], 'XTick', [], ...
        'XColor','none','YColor','none');
    cLeft = cA;
    cRight = cB;
    title(ax, sprintf("\\color[rgb]{%3.1f,%3.1f,%3.1f}A Triggers \\color{black} | \\color[rgb]{%3.1f,%3.1f,%3.1f}B Triggers", ...
        cLeft(1),cLeft(2),cLeft(3),cRight(1),cRight(2),cRight(3)), 'FontName', 'Tahoma');

    squiggles.h.Triggers.A = line(ax, x_init, y_init, 'Color', cLeft, 'LineWidth', 1.0,'LineStyle','--');
    squiggles.h.Triggers.B = line(ax, x_init, y_init, 'Color', cRight, 'LineWidth', 1.0,'LineStyle',':');
else
    squiggles.h.Triggers.A = [];
    squiggles.h.Triggers.B = [];
end
% fprintf(1,'[TMSi]::[Squiggles] GUI initialized.\n');
end