function [fig,snipdata] = plot_templates(snips, options)
arguments
    snips
    options.Color (1,3) double {mustBeInRange(options.Color,0,1)} = [0 0 0];
    options.FigurePosition = [20   50   720   750];
    options.TemplateXSpacing = 2;
    options.TemplateYScale = 25;
    options.NumChannels (1,1) double {mustBeInteger} = 64;
    options.Vector (1,:) {mustBeInteger} = -10:10;
    options.Save (1,1) logical = false;
    options.SampleRate (1,1) double = 4000;
    options.SpatialReferenceMode {mustBeMember(options.SpatialReferenceMode, ["Monopolar", "DifferentialX", "DifferentialY", "Laplacian"])} = "Laplacian";
    options.SaveFolder {mustBeTextScalar} = 'figures';
    options.SaveID {mustBeTextScalar} = sprintf('Default_%04d_%02d_%02d', year(datetime('today')), month(datetime('today')), day(datetime('today')));
end
nts = numel(options.Vector);
snipdata = reshape(snips',nts,options.NumChannels,size(snips,1));

fig = figure('Color','w','Position',options.FigurePosition,'Name', 'MUAPs Templates');
L = tiledlayout(fig, 1, 1);

xdata = options.Vector - options.Vector(1);
h_spacing = options.TemplateXSpacing;
h_scale = numel(xdata);
yoffset = options.TemplateYScale;

n = size(snipdata,3);
ax = nexttile(L);
set(ax, ...
    'NextPlot', 'add', ...
    'FontName', 'Tahoma', ...
    'YLim',[-0.5*yoffset, 8.5*yoffset], ...
    'XColor','none','YColor','none', ...
    'XLim',[-1.1*(h_scale+h_spacing), 8.1*(h_scale+h_spacing)], ...
    'Clipping', 'off');
switch options.SpatialReferenceMode
    case "DifferentialX"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        snipdata = gradient(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
    case "DifferentialY"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        [~,snipdata] = gradient(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
    case "Laplacian"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        snipdata = del2(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
end
mu = mean(snipdata,3);
for iCh = 1:64
    plot(ax,...
        xdata+floor((iCh-1)/8)*(h_scale+h_spacing), ...
        mu(:,iCh)+rem(iCh-1,8)*yoffset, ...
        'Color',options.Color);
end
title(ax,sprintf('N = %d',n),'FontName','Tahoma','Color','k');

line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], ...
    [-0.4*yoffset, 0.6*yoffset], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -(h_scale+h_spacing), 0.65*yoffset, sprintf('%4.1f\\muV', yoffset), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right', 'VerticalAlignment','bottom');

line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*yoffset,-0.4*yoffset], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -h_spacing, -0.45*yoffset, sprintf('%4.1fms', round(h_scale/(options.SampleRate*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left','VerticalAlignment','top');

if options.Save
    utils.save_figure(fig, options.SaveFolder, strcat(string(options.SaveID), "_Templates"), ...
        'ExportAs', {'.png', '.svg'});
end
end