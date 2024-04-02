function fig = plot_spatial_weights(W,dim,options)
%PLOT_SPATIAL_WEIGHTS  Plot spatial weighting vectors assuming a gridded layout.
%
% Syntax:
%   fig = plot_spatial_weights(W);
%   fig = plot_spatial_weights(W, dim, 'Name', value, ...);
%
% Inputs:
%     W  -- Weights array. If each column is a vector of spatial weights, 
%                          then dim should be 2 (default value).
%     dim (1,1) double {mustBeMember(dim,[1,2])} = 2;
%     options.ColorbarTitle {mustBeTextScalar} = "";
%     options.FigurePosition (1,4) double = [400   100   720   750];
%     options.QueryPoints (1,1) double {mustBePositive,mustBeInteger} = 128;
%     options.Montage {mustBeTextScalar, mustBeMember(options.Montage,["8x8 Grid","4x8 Grid"])} = "8x8 Grid";
%     options.InterpolationMethod {mustBeMember(options.InterpolationMethod,["makima","linear","pchip","spline"])} = "makima";
%
% Output
%   fig - Figure handle
%
% See also: Contents

arguments
    W
    dim (1,1) double {mustBeMember(dim,[1,2])} = 2;
    options.Colormap {mustBeTextScalar} = "bluered";
    options.ColorbarTitle {mustBeTextScalar} = "";
    options.CLim = [];
    options.AxesTitle = [];
    options.FigurePosition (1,4) double = [400   100   720   750];
    options.QueryPoints (1,1) double {mustBePositive,mustBeInteger} = 128;
    options.Montage {mustBeTextScalar, mustBeMember(options.Montage,["8x8 Grid","4x8 Grid"])} = "8x8 Grid";
    options.Subtitle {mustBeTextScalar} = "";
    options.InterpolationMethod {mustBeMember(options.InterpolationMethod,["makima","linear","pchip","spline"])} = "makima";
end

cmdata = cm.map(options.Colormap);

N = size(W,dim);
nRows = ceil(sqrt(N));
nCols = ceil(N/nRows);

fig = figure('Color','w',...
    'Name','Spatial Weights',...
    'Position',options.FigurePosition);
L = tiledlayout(fig, nRows, nCols);
switch options.Montage
    case "8x8 Grid"
        nRowsGrid = 8;
        nColsGrid = 8;
    case "4x8 Grid"
        nRowsGrid = 4;
        nColsGrid = 8;
    otherwise
        error("Montage option: %s is not supported.", options.Montage);
end
[X,Y] = meshgrid(1:nColsGrid, 1:nRowsGrid);
[Xq,Yq] = meshgrid(linspace(1,nColsGrid,options.QueryPoints), linspace(1,nRowsGrid,options.QueryPoints));
axq = linspace(0.5,nColsGrid+0.5,options.QueryPoints);
ayq = linspace(0.5,nRowsGrid+0.5,options.QueryPoints);
cl = [inf, -inf];

if ~isempty(options.AxesTitle)
    if numel(options.AxesTitle) < N
        error("Must have an AxesTitle for each plot (here: %d) if supplying that option.", N);
    end
end

for ii = 1:N
    ax = nexttile(L);
    set(ax,'NextPlot','add','FontName','Tahoma','YDir','normal',...
        'XLim',[0.5,nColsGrid+0.5],'YLim',[0.5,nRowsGrid+0.5], ...
        'XColor','none','YColor','none');
    if ~isempty(options.CLim)
        set(ax,'CLim',options.CLim);
    end
    colormap(ax, cmdata);
    if dim == 1
        w = reshape(W(ii,:),nRowsGrid,nColsGrid);
    else
        w = reshape(W(:,ii),nRowsGrid,nColsGrid);
    end
    ww = interp2(X,Y,w,Xq,Yq,options.InterpolationMethod);
    imagesc(ax,axq,ayq,ww);
    c = colorbar(ax);
    if strlength(options.ColorbarTitle)>0
        title(c,options.ColorbarTitle,'FontName','Tahoma');
    end
    cl = [min(cl(1),ax.CLim(1)), max(cl(2),ax.CLim(2))];
    if ~isempty(options.AxesTitle)
        title(ax, options.AxesTitle{ii}, 'FontName','Tahoma','Color','k');
    end
end
set(findobj(L.Children,'Type','axes'),'CLim',cl);
title(L, sprintf('%s Spatial Weights (%s)', options.Montage, inputname(1)), ...
    'FontName','Tahoma','Color','k');
if strlength(options.Subtitle) > 0
    subtitle(L, options.Subtitle, 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end

end