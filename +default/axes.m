function [ax,x_txt_obj,y_txt_obj,title_txt_obj] = axes(fig,varargin)
%AXES Return default axes object handle
%
%  ax = default.axes(); % -> Sets ax using fig = default.fig()
%  ax = default.axes(fig);
%  [ax,x_txt_obj,y_txt_obj,title_txt_obj] = default.axes(__,'Name',value,...);
%
% Inputs
%  name     - Name of figure ('Name' figure property)
%  varargin - 'Name',value keyword argument pairs for Matlab axes builtin
%
% Output
%  ax       - Formatted Matlab axes handle
%
% See also: Contents, matlab.graphics.axis.Axes

if nargin < 1
    fig = default.figure();
    ax = axes(fig);
elseif isa(fig, 'matlab.graphics.axis.Axes')
    ax = fig;
elseif ~isa(fig,'matlab.ui.Figure')
    varargin = [fig, varargin];
    fig = gcf;
    ax = axes(fig, 'NextPlot', 'add', 'LineWidth', 1.5, ...
        'XColor', 'k', 'YColor', 'k');
else
    ax = axes(fig, 'NextPlot', 'add', 'LineWidth', 1.5, ...
        'XColor', 'k', 'YColor', 'k');
end

pars = struct;
pars.XLabel = 'Untitled-X';
pars.YLabel = 'Untitled-Y';
pars.Title  = 'Untitled';
fn = fieldnames(pars);
rmVec = [];
for iV = 1:2:numel(varargin)
    idx = strcmpi(fn,varargin{iV});
    if sum(idx) == 1
        pars.(fn{idx}) = varargin{iV+1};
        rmVec = [rmVec, iV, iV+1]; %#ok<AGROW>
    end
end
varargin(rmVec) = [];
set(ax, ...
    'NextPlot','add',...
    'Units','Normalized',...
    'Position',[ 0.20  0.20  0.75  0.70],...
    'XColor','k',...
    'YColor','k',...
    'XLim',[0 1],...
    'XLimMode','auto',...
    'YLim',[0 1],...
    'YLimMode','auto',...
    'TickDir','both',...
    'LineWidth',1.5,...
    'FontName','Arial',...
    'FontSize',13,...
    varargin{:});
x_txt_obj = ax.XLabel;
y_txt_obj = ax.YLabel;
title_txt_obj = ax.Title;

set(x_txt_obj,'String',pars.XLabel,'FontName','Arial','FontSize',15,...
    'Color','k','FontWeight','bold',...
    'BackgroundColor',get(gcf,'Color'));
set(y_txt_obj,'String',pars.YLabel,'FontName','Arial','FontSize',15,...
    'Color','k','FontWeight','bold',...
    'BackgroundColor',get(gcf,'Color'));
set(title_txt_obj,'String',pars.Title,'FontName','Arial','FontSize',18,...
    'Color','k','FontWeight','bold',...
    'BackgroundColor',get(gcf,'Color'));

end