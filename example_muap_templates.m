K = 32;
CH = 28;

[S,uni_d] = uni_2_pks(data.samples(2:65,:));
idx = find(S(CH,:));
[snips,idx] = uni_2_extended(uni, idx);
Y = tsne(snips);
clus = kmeans(Y,K);

%%
iSort = nan(K,2);
snipdata = cell(K,1);
for ii = 1:K
    iclus = clus == ii;
    snipdata{ii} = reshape(snips(iclus,:)',21,64,sum(iclus));

    iSort(ii,1) = ii;
    itmp = find(clus==ii);
    isub = idx(itmp);
    iSort(ii,2) = isub(find(isub>2e4,1,'first'));
end
[~,iAscend] = sort(iSort(:,2),'ascend');

%%
figure('Color','w'); 
cols = copper(K+10);
cols = cols(11:end,:);
for ii = 1:K
    hold on; 
    scatter(Y(clus==iAscend(ii),1), Y(clus==iAscend(ii),2), 'filled', 'MarkerFaceColor', cols(ii,:));
end
xlabel('t-SNE_1');
ylabel('t-SNE_2');
utils.save_figure(gcf,'G:\My Drive\Murphy-Data_Share\VR','Max_2024_03_30_Extensors-TSNE-Embeddings','ExportAs',{'.png','.svg'});

%%
fig = figure('Color', 'w');
L = tiledlayout(fig, 7, 5);
for ii = 1:K
    ax = nexttile(L);
    set(ax,'NextPlot','add','FontName','Tahoma');
    histogram(ax,diff(idx(clus==iAscend(ii))./4),0:5:250,'FaceColor',cols(ii,:),'EdgeColor','none');
end
xlabel(L,'ISI (ms)');
ylabel(L,'Count');
utils.save_figure(fig,'G:\My Drive\Murphy-Data_Share\VR','Max_2024_03_30_Extensors-ISI','ExportAs',{'.png','.svg'});



%%
fig = figure('Color','w','Position',[352   178   690   765]);
L = tiledlayout(fig,7,5);

xdata = 0:20;
xoffset = 22;
yoffset = 25;
for ii = 1:K
    ax = nexttile(L);
    set(ax,'NextPlot','add','XColor','none','YColor','none','XLim',[-2, xoffset*8+2],'YLim',[-yoffset/2, 8.5*yoffset]);
    mu = mean(snipdata{iAscend(ii)},3);
    n = size(snipdata{iAscend(ii)},3);
    for iCh = 1:64
        plot(ax,xdata+floor((iCh-1)/8)*xoffset,mu(:,iCh)+rem(iCh-1,8)*yoffset,'Color',cols(ii,:));
    end
    title(ax,sprintf('N = %d',n),'FontName','Tahoma','Color','k');
end
utils.save_figure(gcf,'G:\My Drive\Murphy-Data_Share\VR','Max_2024_03_30_Extensors-MUAPs','ExportAs',{'.png','.svg'});

%%
SUBSET = [4,8,12,17,19,20,21:24,26,27];
iAscend_Subset = iAscend(SUBSET); % After visual inspection of ISIs
figure('Color','w','Position',[252   178   690   765]); 
plot((0:(size(uni_d,2)-1))/4000,uni_d(CH,:)); 
hold on; 
for ii = 1:numel(iAscend_Subset)
    scatter(idx(clus==iAscend_Subset(ii))./4000,ones(sum(clus==iAscend_Subset(ii))).*(100+10*ii), ...
        'filled','MarkerFaceColor',cols(SUBSET(ii),:),'Marker','|','MarkerEdgeColor',cols(SUBSET(ii),:)); 
end
xlabel('Time (s)');
utils.save_figure(gcf,'G:\My Drive\Murphy-Data_Share\VR','Max_2024_03_30_Extensors','ExportAs',{'.png','.svg'});