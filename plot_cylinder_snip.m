function [fig,ax,h,c] = plot_cylinder_snip(Theta, Zs, Rs, data, options)
arguments
    Theta (:,1) double
    Zs (:,1) double
    Rs (:,1) double
    data double
    options.Axes = [];
    options.XLabel {mustBeTextScalar} = 'X (mm)';
    options.YLabel {mustBeTextScalar} = 'Y (mm)';
    options.ZLabel {mustBeTextScalar} = 'Z (mm)';
end

[nChannels, nTimeValues] = size(data);
uHeight = unique(Zs);
hDelta = mean(diff(uHeight));
zOffset = linspace(-0.35*hDelta,0.35*hDelta,nTimeValues);
nRing = nChannels / numel(uHeight);
cdata = winter(nRing);
cdata = repelem(cdata,numel(uHeight),1);
[Zs,iSort] = sort(Zs,'ascend');
Rs = Rs(iSort);
data = data(iSort,:);
Theta = Theta(iSort);

r = Rs + data(iSort,:);
Xi = r .* cos(Theta);
Yi = r .* sin(Theta);
Zi = Zs + zOffset;
rc = Rs .* data.*(data>0) ./ 100;
xc = sum(rc .* cos(Theta),1);
yc = sum(rc .* sin(Theta),1);
zmu = mean(Zs);
Zn = Zs - zmu;
zc = sum(Zn .* rms(data,2)./10,1) + zOffset + zmu;


if isempty(options.Axes)
    fig = figure('Color', 'w', 'Name', 'Cylinder Snippet Plot', 'Units','inches','Position',[0.5 0.5 8 5]);
    ax = axes(fig,'NextPlot','add','View',[15 30],'FontName','Tahoma', ...
        'FontSize',16,'ColorOrder',cdata, 'XDir', 'reverse');
else
    fig = options.Axes.Parent;
    ax = options.Axes;
end
zlabel(ax,options.XLabel,'FontName','Tahoma','Color','k');
ylabel(ax,options.ZLabel,'FontName','Tahoma','Color','k');
xlabel(ax,options.YLabel,'FontName','Tahoma','Color','k');

h = plot3(ax, Yi', Zi', Xi');
c = plot3(ax, yc', zc', xc', 'Color', 'k', 'LineWidth', 1.5);

title(ax, 'Cylinder Snippet Plot', 'FontName','Tahoma','Color','k');

end