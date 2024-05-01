function rasterize_specific_muaps(src,~)
%RASTERIZE_SPECIFIC_MUAPS <TODO> Callback to rasterize a "cohort" of clustered or otherwise labeled MUAPs
data = jsondecode(readline(src));
uclus = unique(data.Cluster);
xl = src.UserData.n.xlim;
nRetain = src.UserData.n.retain;
if src.UserData.flags.spike_raster_on
    src.UserData.n.received = src.UserData.n.received + data.N;
    s = data.Sample + src.UserData.n.received;
    for ii = 1:numel(uclus)
        idx = data.Cluster == uclus(ii);
        nClu = sum(idx);
        h = src.UserData.h.raster(uclus(ii));
        xd = h.XData;
        nPoints = numel(xd);
        if nPoints >= nRetain
            xd = xd(1:(nRetain-nClu));
        end
        xd = [fliplr(reshape(rem(s(idx), xl),1,nClu)), xd]; %#ok<AGROW>
        set(h,'XData',xd,'YData',ones(size(xd)).*uclus(ii));
    end
end

if src.UserData.flags.bar_plot_on
    nUnit = src.UserData.n.clusters;
    alpha = src.UserData.param.alpha;
    for ii = 1:nUnit
        src.UserData.h.bar(ii).YData = alpha*sum(data.Cluster==ii)./(data.N/4000) + ...
                                   (1-alpha)*src.UserData.h.bar(ii).YData;
    end
end

end