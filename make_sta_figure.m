function fig = make_sta_figure(name)
%MAKE_STA_FIGURE  Layout figure for plotting temporal averages

CMAP = ["#2b2d42";
        "#8a4c6a";
        "#e86a92";
        "#f0a963";
        "#f7e733";
        "#f7ef96";
        "#9ce9a8";
        "#41e2ba"];

fig = make_ui_figure(name);
ch = reshape(1:64, 8, 8);
for iFig = 1:numel(fig)
     fig(iFig).WindowKeyPressFcn = @handle_hotkey;
     fig(iFig).UserData.ax = gobjects(8, 8);
     fig(iFig).UserData.grid = tiledlayout(fig(iFig), 8, 8);
     fig(iFig).UserData.line = gobjects(8, 8);
     for iRow = 1:8
         for iCol = 1:8
            fig(iFig).UserData.ax(iRow, iCol) = nexttile(fig(iFig).UserData.grid);
            set(fig(iFig).UserData.ax(iRow, iCol), 'NextPlot', 'add', 'XColor', 'k', 'YColor', 'k', 'UserData', ch(iRow, iCol));
            title(fig(iFig).UserData.ax(iRow, iCol), sprintf('Ch-%02d', ch(iRow, iCol)));
            fig(iFig).UserData.line(iRow, iCol) = line(fig(iFig).UserData.ax(iRow, iCol), ...
                nan, nan, 'LineWidth', 1.5, 'Color', validatecolor(CMAP(iCol)));
         end
     end
end

    function setTerminationFlag(fig)
        fig.Visible = 'off';
    end

    function handle_hotkey(src, evt)
        switch evt.Key
            case 'q'
                setTerminationFlag(src);
            otherwise
                disp(evt);
        end
    end

end