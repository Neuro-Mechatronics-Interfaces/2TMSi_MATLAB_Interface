function [fig, client] = init_muap_receiver(address, port, options)

arguments
    address = "127.0.0.1";
    port = 6056;
    options.Alpha = 0.02;
    options.Callback = @rasterize_muaps;
    options.NRetain = 10;
    options.NMUAPsMax = 9;
    options.SampleRate = 4000;
    options.TMax = 0.5;
    options.MakeSpikeRaster (1,1) logical = true;
    options.MakeBarPlot (1,1) logical = true;
end
xl = [0, options.SampleRate*options.TMax];
fig = figure('Color', 'w', 'Name', 'MUAPs History');
if size(groot().MonitorPositions,1) > 2
    set(fig,'Position',[-4671        -537        1162         509]);
end
L = tiledlayout(fig,3,1);
if options.MakeSpikeRaster
    ax = nexttile(L, 1, [1+2*double(~options.MakeBarPlot) 1]);
    set(ax,'NextPlot','add','FontName','Tahoma');
    hSpikeScatter = gobjects(options.NMUAPsMax,1);
    set(ax,'XLim',xl,'XTick',[0, xl(2)],'XTickLabel',[0,options.TMax],'YLim',[0,options.NMUAPsMax+1]);
    xlabel(ax,'Time (s)','FontName','Tahoma','Color','k');
    cmapdata = jet(options.NMUAPsMax);
    for iH = 1:numel(hSpikeScatter)
        hSpikeScatter(iH) = scatter(ax,nan,nan,'MarkerEdgeColor',cmapdata(iH,:),'Marker','|','LineWidth',1.25);
    end
else
    hSpikeScatter = [];
end

if options.MakeBarPlot
    ax = nexttile(L, 2-double(~options.MakeSpikeRaster), [2+double(~options.MakeSpikeRaster) 1]);
    set(ax,'NextPlot','add','FontName','Tahoma','XLim',[0, options.NMUAPsMax+1], ...
        'YLim',[0, 50]);
    ylabel(ax,'Rate (MUAPs/sec)','FontName','Tahoma','Color','k');
    hBar = gobjects(options.NMUAPsMax,1);
    for iB = 1:options.NMUAPsMax
        hBar(iB) = bar(ax,iB,0,'EdgeColor','none','FaceColor',cmapdata(iB,:));
    end
else
    hBar = [];
end
client = tcpclient(address, port);
client.UserData = struct(...
    'h', struct('raster', hSpikeScatter, ...
                'bar', hBar), ...
    'n', struct('retain', options.NRetain, ...
                'clusters', options.NMUAPsMax, ...
                'xlim', xl(2), ...
                'received', 0), ...
    'param', struct('alpha',options.Alpha), ...
    'flags', struct('spike_raster_on', options.MakeSpikeRaster, ...
                    'bar_plot_on', options.MakeBarPlot)); 
client.configureCallback("terminator", options.Callback);
fig.DeleteFcn = @(~,~)delete(client);

end