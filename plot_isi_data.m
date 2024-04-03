function fig = plot_isi_data(isi_data, options)

arguments
    isi_data struct
    options.FontName {mustBeTextScalar} = 'Tahoma';
    options.Position (1,4) double = [600   50   720   750];
    options.Order {mustBePositive, mustBeInteger} = [];
    options.LabelPadding (1,1) double {mustBePositive, mustBeInteger} = 8; % Index padding so labels do not overlap bars
end

K = numel(isi_data);
cols = copper(K+10);
cols = cols(11:end,:);

if isempty(options.Order)
    ord = 1:K;
else
    if numel(options.Order) > K
        error("Must have less than or equal to %d elements in 'Order' option indexing (based on size of isi_data input).", K);
    end
    ord = options.Order;
end
n = [isi_data(ord).n];
cv = [isi_data(ord).cv];
k = numel(n);

fig = figure('Color','w',...
    'Name','ISI Data',...
    'Position',options.Position);
L = tiledlayout(fig, 2, 1);
ax = nexttile(L);
set(ax,'NextPlot','add','FontName',options.FontName,'XColor','k','YColor','none',...
    'XTick',10:10:k,'XLim',[0, k+options.LabelPadding]);
for ii = 1:k
    bar(ax, ii, n(ii), 'FaceColor', cols(ii,:), 'EdgeColor', 'k');
end
mu = mean(n);
sigma = std(n);
yline(ax, mu, 'b--', sprintf('Mean = %5.1f',round(mu,1)), 'FontName', options.FontName);
yline(ax, [mu+sigma, mu-sigma], 'm:', sprintf('SD = %5.1f',round(sigma,1)), 'FontName', options.FontName);
title(ax, 'N_{intervals}', 'FontName','Tahoma','Color','k');

ax = nexttile(L);
set(ax,'NextPlot','add','FontName',options.FontName,'XColor','k','YColor','none',...
    'XTick',10:10:k,'XLim',[0, k+options.LabelPadding]);
for ii = 1:k
    bar(ax, ii, cv(ii), 'FaceColor', cols(ii,:), 'EdgeColor', 'k');
end
mu = mean(cv);
sigma = std(cv);
yline(ax, mu, 'b--', sprintf('Mean = %5.1f',round(mu,1)), 'FontName', options.FontName);
yline(ax, [mu+sigma, mu-sigma], 'm:', sprintf('SD = %5.1f',round(sigma,1)), 'FontName', options.FontName);
title(ax, 'CV_{ISI}', 'FontName','Tahoma','Color','k');

xlabel(L,'MUAP ID', 'FontName','Tahoma','Color','k');
end