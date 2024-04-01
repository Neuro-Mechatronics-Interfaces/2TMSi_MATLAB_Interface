function [snips, idx, clus, nts, included_ch, isi_data, S, Y] = muap_templates(data, K, CH, options)
%MUAP_TEMPLATES  Returns snippets and basic EDA figures associated with MUAP snippet templates.
arguments
    data % TMSiSAGA.Data as returned by TMSiSAGA.Poly5.read() OR equivalent struct() -needs fields 'samples', 'num_samples', and 'sample_rate'.
    K           % Number of k-means clusters
    CH          % Channel index for threshold-crossings
    options.EdgesISI (1,:) double = 0:5:250; % milliseconds
    options.ExcludedChannels {mustBePositive, mustBeInteger} = [];
    options.FirstSampleForTemporalSort (1,1) double {mustBePositive, mustBeInteger} = 2e4;
    options.FigurePosition (1,4) double = [20   50   720   750];
    options.Vector (1,:) double {mustBeInteger} = -10:10;
    options.MinimumRequiredSamplesForTemporalSort (1,1) double {mustBePositive, mustBeInteger} = 20000; % samples -- default is 5 seconds at 4 kHz.
    options.MinimumCV (1,1) double = 0.6; % Minimum Coefficient of Variation in ISI to include in temporal plot
    options.MinimumN (1,1) double {mustBeInteger} = 0; % Minimum number of samples; by default it is zero (no requirement)
    options.CloseFigures (1,1) logical = false;
    options.PlotEmbeddings (1,1) logical = true;
    options.SaveEmbeddings (1,1) logical = false;
    options.PlotISI (1,1) logical = true;
    options.SaveISI (1,1) logical = false;
    options.PlotTemplates (1,1) logical = true;
    options.SaveTemplates (1,1) logical = false;
    options.PlotTemporal (1,1) logical = true;
    options.SaveTemporal (1,1) logical = false;
    options.TemplateYScale (1,1) double = 25.0;
    options.TemplateXSpacing (1,1) double {mustBePositive, mustBeInteger} = 2;
    options.TemporalRasterBaseHeight (1,1) double = 100;
    options.TemporalRasterYOffset (1,1) double = 10;
    options.TemporalReference double = [];
    options.TemporalReferenceTimes double = [];
    options.SaveFolder {mustBeTextScalar} = 'figures';
    options.SaveID {mustBeTextScalar} = sprintf('Default_%04d_%02d_%02d', year(datetime('today')), month(datetime('today')), day(datetime('today')));
end

[S,uni_d] = uni_2_pks(data.samples(2:65,:));
idx = find(S(CH,:));
[snips,idx] = uni_2_extended(data.samples(2:65,:), idx, ...
    'ExcludedChannels', options.ExcludedChannels, ...
    'Vector', options.Vector);
Y = tsne(snips);
clus = kmeans(Y,K);
nts = numel(options.Vector);
included_ch = setdiff(1:64,options.ExcludedChannels);
nRows = ceil(sqrt(K));
nCols = ceil(K/nRows);

iSort = nan(K,2);
snipdata = cell(K,1);
if options.FirstSampleForTemporalSort < (data.num_samples - options.MinimumRequiredSamplesForTemporalSort)
    firstSample = options.FirstSampleForTemporalSort;
else
    warning('Not enough samples in data for requested temporal sort start sample. Starting temporal sort from first sample in record.');
    firstSample = 1;
end
for ii = 1:K
    iclus = clus == ii;
    snipdata{ii} = reshape(snips(iclus,:)',nts,numel(included_ch),sum(iclus));

    iSort(ii,1) = ii;
    isub = idx(clus==ii);
    iSort(ii,2) = isub(find(isub>firstSample,1,'first'));
end
[~,iAscend] = sort(iSort(:,2),'ascend');

if options.PlotEmbeddings
    fig = figure('Color','w','Name','t-SNE MUAPs Embeddings','Position',[150   50   720   750]); 
    cols = copper(K+10);
    cols = cols(11:end,:);
    ax = axes(fig,'NextPlot','add','FontName','Tahoma');
    for ii = 1:K
        scatter(ax, Y(clus==iAscend(ii),1), Y(clus==iAscend(ii),2), ...
            'filled', 'MarkerFaceColor', cols(ii,:));
    end
    xlabel(ax, 't-SNE_1', 'FontName','Tahoma','Color','k');
    ylabel(ax, 't-SNE_2', 'FontName','Tahoma','Color','k');
    if options.SaveEmbeddings
        utils.save_figure(fig, options.SaveFolder, strcat(string(options.SaveID), "_Embeddings"), 'ExportAs', {'.png', '.svg'}, 'CloseFigure', options.CloseFigures);
    end
end

if options.PlotISI
    figPos = options.FigurePosition;
    figPos(3) = figPos(3)*2;
    fig = figure('Color', 'w','Position',figPos,'Name','MUAPs ISIs');
    L = tiledlayout(fig, nRows, nCols);
    yMax = 0;
    isi_data = struct('n',cell(K,1),'cv',cell(K,1));
    for ii = 1:K
        ax = nexttile(L);
        set(ax,'NextPlot','add','FontName','Tahoma','XLim',[options.EdgesISI(1), options.EdgesISI(end)]);
        deltas = diff(idx(clus==iAscend(ii))./(data.sample_rate*1e-3));
        histogram(ax,deltas, ...
            options.EdgesISI,'FaceColor',cols(ii,:),'EdgeColor','none');
        yMax = max(yMax,ax.YLim(2));
        isi_data(ii).n = numel(deltas);
        isi_data(ii).cv = median(abs(deltas - median(deltas)))/median(deltas);
        title(ax, sprintf('n = %d | CV = %04.2f', isi_data(ii).n, isi_data(ii).cv), ...
            'FontName','Tahoma','FontSize',8,'Color',cols(ii,:));
    end
    xlabel(L,'ISI (ms)','FontName','Tahoma','Color','k');
    ylabel(L,'Count','FontName','Tahoma','Color','k');
    title(L, sprintf('Duration = %7.1fs',data.num_samples/data.sample_rate), ...
        'FontName','Tahoma', ...
        'Color','k');
    set(findobj(L.Children,'Type','axes'),'YLim',[0, yMax]); % Set identical y-limits
    subfig = plot_isi_data(isi_data);
    if options.SaveISI
        utils.save_figure(fig, options.SaveFolder, strcat(string(options.SaveID), "_ISI"), 'ExportAs', {'.png', '.svg'}, 'CloseFigure', options.CloseFigures);
        utils.save_figure(subfig, options.SaveFolder, strcat(string(options.SaveID), "_ISI-stats"), 'ExportAs', {'.png', '.svg'}, 'CloseFigure', options.CloseFigures);
    end
else
    isi_data = [];
end


if options.PlotTemplates
    fig = figure('Color','w','Position',options.FigurePosition,'Name', 'MUAPs Templates');
    L = tiledlayout(fig, nRows, nCols);
    
    xdata = options.Vector - options.Vector(1);
    h_spacing = options.TemplateXSpacing;
    h_scale = numel(xdata);
    yoffset = options.TemplateYScale;
    for ii = 1:K
        ax = nexttile(L);
        set(ax, ...
            'NextPlot', 'add', ...
            'FontName', 'Tahoma', ...
            'YLim',[-0.5*yoffset, 8.5*yoffset], ...
            'XColor','none','YColor','none', ...
            'XLim',[-1.1*(h_scale+h_spacing), 8.1*(h_scale+h_spacing)], ...
            'Clipping', 'off');
        mu = mean(snipdata{iAscend(ii)},3);
        n = size(snipdata{iAscend(ii)},3);
        for iCh = 1:64
            plot(ax,...
                xdata+floor((iCh-1)/8)*(h_scale+h_spacing), ...
                mu(:,iCh)+rem(iCh-1,8)*yoffset, ...
                'Color',cols(ii,:));
        end
        title(ax,sprintf('N = %d',n),'FontName','Tahoma','Color','k');
        if ii == 1
            line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], ...
                [-0.4*yoffset, 0.6*yoffset], ...
                'Color', 'k', 'LineWidth', 1.5);
            text(ax, -(h_scale+h_spacing), 0.65*yoffset, sprintf('%4.1f\\muV', yoffset), ...
                'FontName','Tahoma','Color','k','HorizontalAlignment','right', 'VerticalAlignment','bottom');

            line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*yoffset,-0.4*yoffset], ...
                'Color', 'k', 'LineWidth', 1.5);
            text(ax, -h_spacing, -0.45*yoffset, sprintf('%4.1fms', round(h_scale/(data.sample_rate*1e-3),1)), ...
                'FontName','Tahoma','Color','k','HorizontalAlignment','left','VerticalAlignment','top');

        end
    end
    if options.SaveTemplates
        utils.save_figure(fig, options.SaveFolder, strcat(string(options.SaveID), "_Templates"), 'ExportAs', {'.png', '.svg'}, 'CloseFigure', options.CloseFigures);
    end
end

if options.PlotTemporal
    n = [isi_data(iAscend).n];
    cv = [isi_data(iAscend).cv];
    subset = find((n > options.MinimumN) & (cv > options.MinimumCV));
    iAscend_Subset = iAscend(subset); % After visual inspection of ISIs
    t_uni = (0:(size(uni_d,2)-1))/4000;
    figPos = options.FigurePosition;
    figPos(3) = figPos(3)*2;
    fig = figure('Color','w',...
        'Position',figPos, ...
        'Name','MUAPs Temporal Recruitment'); 
    ax = axes(fig,'NextPlot','add','FontName','Tahoma', ...
        'XColor','none','YColor','none','Clipping','off',...
        'XLim',[t_uni(1), t_uni(end)]);
    
    if ~isempty(options.TemporalReference)
        if isempty(options.TemporalReferenceTimes)
            t_ref = linspace(0,t_uni(end),numel(options.TemporalReference));
        else
            t_ref = options.TemporalReferenceTimes;
        end
        line(ax, t_ref, options.TemporalReference, ...
            'Color', [0.65 0.65 0.65], 'LineStyle','-', 'LineWidth', 1.5);
    end
    line(ax, t_uni, uni_d(CH,:), ...
        'Color','b','LineWidth',1.25,'LineStyle','-'); 
    h_scale = 0.05*t_uni(end);
    h_spacing = 0.001*t_uni(end);
    yoffset = options.TemporalRasterBaseHeight;
    
    line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], ...
                [-0.4*yoffset, 0.6*yoffset], ...
                'Color', 'k', 'LineWidth', 1.5);
    text(ax, -(h_scale+h_spacing), 0.65*yoffset, sprintf('%4.1f\\muV', yoffset), ...
        'FontName','Tahoma','Color','k','HorizontalAlignment','right', 'VerticalAlignment','bottom');

    line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*yoffset,-0.4*yoffset], ...
        'Color', 'k', 'LineWidth', 1.5);
    text(ax, -h_spacing, -0.45*yoffset, sprintf('%4.1fs', round(h_scale,1)), ...
        'FontName','Tahoma','Color','k','HorizontalAlignment','right','VerticalAlignment','top');
    for ii = 1:numel(iAscend_Subset)
        nx = sum(clus==iAscend_Subset(ii));
        x = reshape(idx(clus==iAscend_Subset(ii))./4000,1,nx);
        y = ones(size(x)).*(options.TemporalRasterBaseHeight+options.TemporalRasterYOffset*ii);
        xx = [x; x; nan(1,nx)];
        yy = [y-options.TemporalRasterYOffset*0.45; y+options.TemporalRasterYOffset*0.45; nan(1,nx)];
        line(ax, xx(:), yy(:), ...
            'LineWidth', 0.75, ...
            'LineStyle', '-', ...
            'Color', cols(subset(ii),:));
    end
    if options.SaveTemporal
        utils.save_figure(fig,options.SaveFolder,strcat(string(options.SaveID),"_Temporal-Recruitment"),'ExportAs',{'.png','.svg'},'CloseFigure',options.CloseFigures);
    end
end

end