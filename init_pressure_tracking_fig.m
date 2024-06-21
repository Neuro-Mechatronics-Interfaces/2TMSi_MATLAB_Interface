function fig = init_pressure_tracking_fig()

fig = figure('Name','Pressure Tracker Figure','Color','w', ...
    'CloseRequestFcn', @handleFigureClosing, ...
    'WindowKeyReleaseFcn', @handleWindowKeyUp);
L = tiledlayout(fig,4,1);
ax = nexttile(L,1,[3 1]);
set(ax,'NextPlot','add','Color','none','XColor','none','YColor','none', ...
    'XLim',[0, 15000],'YLim',[0, 10000],'CLim',[1,1000],'Colormap',turbo(1000));
title(ax,'Tablet Pen Pressure + Location', 'FontName','Tahoma','Color','k');
fig.UserData.PressureSpots = struct(...
    'h',scatter(ax,nan(1,1000),nan(1,1000),'Marker','o','MarkerFaceColor','flat','MarkerEdgeColor','none','MarkerFaceAlpha',0.25,'CData',1:1000,'SizeData',ones(1,1000)),...
    'idx',1);

ax = nexttile(L,4,[1 1]);
set(ax,'NextPlot','add','Color','none','XColor','none','YColor','none','YLim',[0,20000],'XLim',[1,1000]);
title(ax,'Tablet Pen Pressure History','FontName','Tahoma','Color','k');
fig.UserData.PressureLine = struct(...
    'h', line(ax,1:1000,nan(1,1000),'Color','k','LineWidth',2),...
    'idx',1);

% Initialize library/mex function
WinTabMex(0,fig,1);
WinTabMex(2);

    function handleFigureClosing(src,~)
        WinTabMex(3);
        WinTabMex(1);
        src.CloseRequestFcn = @closereq;
        try %#ok<TRYNC>
            delete(src);
        end
    end

    function handleWindowKeyUp(src,evt)
        switch evt.Key
            case 'space'
                WinTabMex(2);
                src.UserData.PressureSpots.h.XData = nan(1,1000);
                src.UserData.PressureSpots.h.YData = nan(1,1000);
                src.UserData.PressureLine.h.YData = nan(1,1000);
                src.UserData.PressureLine.idx = 1;
                src.UserData.PressureSpots.idx = 1;
                drawnow();
                disp(evt);
            otherwise
                disp(evt);
        end
    end


end