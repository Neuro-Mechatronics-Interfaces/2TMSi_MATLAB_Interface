function fig = plot_nmf(W,H,k,options)
arguments
    W
    H
    k
    options.SampleRate (1,1) double {mustBePositive} = 4000;
    options.FindPeaks (1,1) logical = true;
    options.MinPeakHeight (1,1) double = 6.5; % Times RMS
    options.MinPeakDistance (1,1) double = 0.025;
end
fig = gobjects(numel(k),1);
for ii = 1:numel(k)
    t = (0:(size(H,2)-1))/options.SampleRate;
    fig(ii) = figure("Color", "w", 'Name', "NMF Weights and Encodings", ...
        'Position', [20+200*(ii-1),400,720,350]);
    L = tiledlayout(fig(ii), 2, 2);
    ax = nexttile(L,1,[1 2]);
    set(ax,'NextPlot','add','FontName','Tahoma');
    plot(ax, t, H(k(ii),:).*1e3,'Color','k','LineWidth',0.5);
    if options.FindPeaks
        r = rms(H(k(ii),:).*1e3);
        [pks,locs] = findpeaks(H(k(ii),:).*1e3,"MinPeakHeight",options.MinPeakHeight*r,"MinPeakDistance",options.MinPeakDistance);
        scatter(ax,t(locs),pks,"Marker","x","MarkerEdgeColor",'r');
        pnr = mean(pks) / mean(H(k(ii),setdiff(1:size(H,2),locs)).*1e3);
        title(ax,sprintf("PNR = %5.2f", round(pnr,2)),'FontName','Tahoma','Color','k');
        subtitle(ax,sprintf("RMS = %7.3f", round(r,3)),'FontName','Tahoma','Color',[0.65 0.65 0.65]);
    end
    xlabel(ax,'Time (s)','FontName','Tahoma','Color','k');

    ax = nexttile(L,3,[1 2]);
    set(ax,'XLim',[0.5,8.5],'YLim',[0.5,8.5],...
        'NextPlot','add','FontName','Tahoma',...
        'XColor','none','YColor','none');
    imagesc(ax,[1,8],[1,8],reshape(W(:,k(ii))./1e3,8,8));
    [~,iMax] = max(W(:,k(ii)));
    [iRow,iCol] = ind2sub([8,8],iMax);
    text(ax,iCol,iRow,sprintf('Ch-%02d',iMax),...
        'HorizontalAlignment','center', ...
        'VerticalAlignment','middle',...
        'FontName','Tahoma','FontWeight','bold','Color','k','FontSize',8);

    colorbar(ax);
    title(ax,sprintf('Weights (Factor-%d)',k(ii)),"FontName",'Tahoma');
    title(L,sprintf("NMF Weights and Encodings %d", k(ii)),'FontName','Tahoma','Color','k');
end
end