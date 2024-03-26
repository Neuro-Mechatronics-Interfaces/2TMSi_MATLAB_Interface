function [coeffFig, coeffAx] = plot_controller_coeffs(src)
coeffFig = figure('Color', 'w', 'Name', 'Coefficients');
coeffAx = axes(coeffFig, 'YDir','reverse', 'Clipping', 'off', 'NextPlot','add','FontName','Tahoma','XColor','k','YColor','none');
imagesc(coeffAx, src.UserData.T);
for iC = 1:12
    text(coeffAx, iC-0.33, -2, sprintf('%d%%',round(src.UserData.explained(iC))), ...
        'FontName', 'Tahoma', 'FontSize', 8);
end
end