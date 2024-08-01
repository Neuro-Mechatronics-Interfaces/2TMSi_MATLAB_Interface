function fig = plot_fitts_result(trialsTable, performance, options)
arguments
    trialsTable
    performance
    options.Subtitle {mustBeTextScalar} = "";
end
coefName = performance.model.CoefficientNames{2};
fig = figure('Color', 'w', 'Name', 'Trial Time and ID');
ax = axes(fig,'NextPlot','add','FontName','Tahoma');
xl = [min(trialsTable.(coefName));max(trialsTable.(coefName))];
xl = [xl(1)-0.25*diff(xl); xl(2)+0.25*diff(xl)];
yl = predict(performance.model,table(xl,'VariableNames',{coefName}));
line(ax, xl, yl, 'LineWidth', 1.5, 'Color', 'k', 'LineStyle', '--', 'DisplayName', 'Fitts'' Law Model');
yp = predict(performance.model, trialsTable);
iFast = trialsTable.DialInTime < yp;
iVert = trialsTable.TargetVerticalOffset == 0;
scatter(ax,trialsTable.(coefName)(iFast & iVert),trialsTable.DialInTime(iFast & iVert), ...
    'Marker', 's', 'MarkerFaceColor', 'b', 'MarkerEdgeColor', 'none', 'DisplayName', '"Fast" Vertical');
scatter(ax, trialsTable.(coefName)(~iFast & iVert), trialsTable.DialInTime(~iFast & iVert), ...
    'Marker', 's', 'MarkerFaceColor', 'r', 'MarkerEdgeColor', 'none', 'DisplayName', '"Slow" Vertical');
scatter(ax,trialsTable.(coefName)(iFast & ~iVert),trialsTable.DialInTime(iFast & ~iVert), ...
    'Marker', 's', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'b', 'DisplayName', '"Fast" Horizontal');
scatter(ax, trialsTable.(coefName)(~iFast & ~iVert), trialsTable.DialInTime(~iFast & ~iVert), ...
    'Marker', 's', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'r', 'DisplayName', '"Slow" Horizontal');
text(ax, mean(xl)+0.35*diff(xl), mean(yl)-0.35*diff(yl), sprintf('%.2f bits/sec', performance.index), ...
    'FontName','Tahoma','Color','m','FontSize',12,'BackgroundColor','w');
legend(ax, 'FontName', 'Tahoma', 'TextColor', 'black', 'Color', 'none', 'EdgeColor', 'none', 'Location', 'northwest');
title(ax, 'Fitts'' Law Result (Score)', 'FontName','Tahoma','FontWeight','bold','Color','k');
ylabel(ax, 'Duration (sec)', 'FontName','Tahoma','Color','k');
if strcmpi(coefName,'ID')
    xlabel(ax, 'Fitts Index of Difficulty (Bits)', 'FontName','Tahoma','Color','k');
else
    xlabel(ax, 'Mackenzie/Hargrove Index of Difficulty (Bits)', 'FontName','Tahoma','Color','k');
end
if strlength(options.Subtitle) > 0
    subtitle(ax, options.Subtitle, 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end
end