function [fig,snipdata] = plot_templates(snips, options)
arguments
    snips
    options.Color (:,3) double {mustBeInRange(options.Color,0,1)} = copper(64);
    options.FigurePosition = [20   50   720   350];
    options.TemplateXSpacing = 2;
    options.TemplateYScale = 100;
    options.MinChannelwiseRMS (1,1) double = 1;
    options.MinTemplateMaxRMS (1,1) double = 10; % microvolts
    options.NumChannels (1,1) double {mustBeInteger} = 64;
    options.NExamples (1,1) double {mustBeInteger} = 10;
    options.Vector (1,:) {mustBeInteger} = -20:15;
    options.Save (1,1) logical = false;
    options.SampleRate (1,1) double = 4000;
    options.SpatialReferenceMode {mustBeMember(options.SpatialReferenceMode, ["Monopolar", "DifferentialX", "DifferentialY", "Laplacian"])} = "Laplacian";
    options.SaveFolder {mustBeTextScalar} = 'figures';
    options.SaveID {mustBeTextScalar} = sprintf('Default_%04d_%02d_%02d', year(datetime('today')), month(datetime('today')), day(datetime('today')));
    options.Title {mustBeTextScalar} = "";
    options.XYFigure (1,2) double = [nan, nan]; % Figure XY coordinates
end
nts = numel(options.Vector);
snipdata = reshape(snips',nts,options.NumChannels,size(snips,1));

p = options.FigurePosition;
if ~isnan(options.XYFigure(1))
    p(1) = options.XYFigure(1);
end
if ~isnan(options.XYFigure(2))
    p(2) = options.XYFigure(2);
end

fig = figure('Color','w','Position',p,'Name', 'MUAPs Templates');
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
rdata = mean(squeeze(rms(snipdata,1)),2);
i_miss = rdata < options.MinChannelwiseRMS;
snipdata(:,i_miss,:) = missing;
switch options.SpatialReferenceMode
    case "DifferentialX"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        for ii = 1:n
            for ik = 1:nts
                snipdata(ik,:,:,ii) = fillmissing2(squeeze(snipdata(ik,:,:,ii)),"linear");
            end
        end
        snipdata = gradient(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
    case "DifferentialY"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        for ii = 1:n
            for ik = 1:nts
                snipdata(ik,:,:,ii) = fillmissing2(squeeze(snipdata(ik,:,:,ii)),"linear");
            end
        end
        [~,snipdata] = gradient(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
    case "Laplacian"
        snipdata = reshape(snipdata, nts, 8, 8, n);
        for ii = 1:n
            for ik = 1:nts
                snipdata(ik,:,:,ii) = fillmissing2(squeeze(snipdata(ik,:,:,ii)),"linear");
            end
        end
        snipdata = del2(snipdata);
        snipdata = reshape(snipdata, nts, 64, n);
end
mu = mean(snipdata,3);
if ~isnan(options.NExamples) && options.NExamples > 0
    plot_examples = true;
    i_example = randsample(n,min(options.NExamples,n),false);
else
    plot_examples = false;
end
cdata = options.Color;
if size(cdata,1) == 1
    cdata = cm.umap(cdata); 
end
r = rms(mu,1);
c_lim = [min(r), max(max(r),options.MinTemplateMaxRMS)];
cmobj = cm.cmap(c_lim, uint8(cdata.*255));
for iCh = 1:64
    width_offset = floor((iCh-1)/8)*(h_scale+h_spacing);
    height_offset = rem(iCh-1,8)*yoffset;
    if plot_examples
        plot(ax, ...
            xdata+width_offset, ...
            squeeze(snipdata(:,iCh,i_example)) + height_offset, ...
            'Color', [0.65 0.65 0.65], ...
            'LineWidth', 0.5);
    end
    plot(ax,...
        xdata+width_offset, ...
        mu(:,iCh)+height_offset, ...
        'Color',double(cmobj(r(iCh)))./255.0, ...
        'LineWidth', 2.5);
end
if strlength(options.Title) < 1
    title(ax,sprintf('N = %d',n),'FontName','Tahoma','Color','k');
else
    title(ax,sprintf('%s | N = %d', options.Title, n), 'FontName','Tahoma','Color','k');
end

line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], ...
    [-0.4*yoffset, 0.6*yoffset], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -(h_scale+h_spacing), 0.65*yoffset, sprintf('%4.1f\\muV', yoffset), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right', 'VerticalAlignment','bottom');

line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*yoffset,-0.4*yoffset], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -h_spacing, -0.45*yoffset, sprintf('%4.1fms', round(h_scale/(options.SampleRate*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left','VerticalAlignment','top');

subtitle(ax, sprintf('Peak Waveform RMS = %4.1f \\muV', max(r)), 'FontName','Tahoma','Color',[0.65 0.65 0.65]);

if options.Save
    utils.save_figure(fig, options.SaveFolder, strcat(string(options.SaveID), "_Templates"), ...
        'ExportAs', {'.png', '.svg'});
end
end