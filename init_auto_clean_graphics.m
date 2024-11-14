function h = init_auto_clean_graphics(options)
%INIT_AUTO_CLEAN_GRAPHICS  Initialize graphic handles for autocleaner
%
% Syntax:
%   h = init_auto_clean_graphics('Name', value, ...);
%
% Inputs:
%   'FigurePosition' (1,4) = [100 100 600 400];
%   'SampleRate' (1,1) {mustBePositive} = 2000;
%   'HScale' (1,1) {mustBePositive} = 10; % Seconds
%   'ProgressBarColor' (1,3) {mustBeInRange(options.ProgresBarColor,0,1)} = [0.05 0.05 0.8];
%
% Output:
%   h - Struct with fields for graphic handles.

arguments
    options.FigurePosition (1,4) = [100 100 600 400];
    options.SampleRate (1,1) {mustBePositive} = 2000;
    options.HScale (1,1) {mustBePositive} = 10; % Seconds
    options.ProgressBarColor (1,3) {mustBeInRange(options.ProgressBarColor,0,1)} = [0.05 0.05 0.8];
end
h.Figure = figure(...
    'Name', 'Auto-Cleaning Progress', ...
    'Color', 'w',  ...
    'Position',options.FigurePosition);
h.Layout = tiledlayout(h.Figure, 5, 1);
h.ProgressAxes = nexttile(h.Layout, 1, [1 1]);
h.IPTAxes = nexttile(h.Layout,2,[4 1]);
set(h.ProgressAxes,'NextPlot','add','XLim',[0 100],'XTick',0:25:100, ...
    'YTick',[],'YColor','none','YLim',[0 1],'CLim',[0 1],'Colormap',[1 1 1; options.ProgressBarColor]);
xlabel(h.ProgressAxes,'Progress (%)','FontName','Tahoma','Color','k');
set(h.IPTAxes,'NextPlot','add','FontName','Tahoma','XColor','none','YColor','none','YLim',[-0.3 1.0]);
h.ProgressBar = imagesc(h.ProgressAxes,[0,100],[0 1],zeros(1,100));
h.IPTs = line(h.IPTAxes,nan,nan,'LineWidth',0.5,'Color','k','LineStyle','-','DisplayName','IPT');
h.IPTPulses = line(h.IPTAxes,nan,nan,'LineStyle','none','Marker','o','MarkerEdgeColor','b','MarkerFaceColor','none','DisplayName','MUAP Instants');
h.Legend = legend(h.IPTAxes,'FontName','Tahoma','TextColor','black');
h.Title = title(h.Layout,'IPT Auto-Cleaner Indicator','FontName','Consolas','Color','k');
h.Subtitle = title(h.IPTAxes,'Initial: IPT-0','FontName','Tahoma','Color','k');
h.Scale = line(h.IPTAxes,[0, options.SampleRate*options.HScale], [-0.2, -0.2], 'Color',[0.65 0.65 0.65],'LineWidth',1.5);
h.ScaleText = text(h.IPTAxes,options.SampleRate*options.HScale/2,-0.25,sprintf('%4.1f s',round(options.HScale,1)),'FontName','Tahoma','Color',[0.65 0.65 0.65]);
h.Scale.Annotation.LegendInformation.IconDisplayStyle = 'off';
drawnow();

end