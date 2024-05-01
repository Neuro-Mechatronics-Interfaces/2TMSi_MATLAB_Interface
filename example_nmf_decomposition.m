%EXAMPLE_NMF_DECOMPOSITION

clc;
clearvars -except uni description
if exist('uni','var')==0
    load('C:\Data\Shared\MCP01_2024_04_12\MotorUnits Decomposition\Max\Decomposition Input\MCP01_2024_04_12_20_synchronized.mat','uni','description');
end


%%
NCH = 256;
K = 32;
VEC = -8:8;
N_PC_MAX = 6;

%%
[coeff,score] = pca(uni);
S = uni_2_pks(coeff(:,1:N_PC_MAX)');
nts = numel(VEC);

%%
idx = cell(N_PC_MAX,1);
snips = cell(N_PC_MAX,1);
clus = cell(N_PC_MAX,1);
snipdata = cell(N_PC_MAX,1);
cmapdata = jet(K);
nMonitor = size(get(groot,'MonitorPositions'),1);
for iCh = 1:N_PC_MAX
    idx{iCh} = find(S(iCh,:))';
    [snips{iCh},idx{iCh}] = uni_2_extended(uni, idx{iCh}, 'Vector', VEC);
    n = size(snips{iCh},1);
    
    Y = tsne(snips{iCh});
    clus{iCh} = kmeans(Y,K);
    snipdata{iCh} = reshape(snips{iCh}',nts,NCH,n);
    for ik = 1:K
        fig = figure('Color','w','Name','Snippet Example'); 
        ax = axes(fig,'NextPlot','add','ColorOrder',jet(256), ...
            'XColor','none','YColor','none'); 
        i_snippet = clus{iCh}==ik;
        for ii = 1:256 
            plot(ax, ...
                VEC+floor((ii-1)/8)*18+floor((ii-1)/64)*2.5, ...
                squeeze(snipdata{iCh}(:,ii,i_snippet))+rem((ii-1),8)*25, ...
                'Color',[0.65 0.65 0.65],'LineWidth',0.5); 
            plot(ax, ...
                VEC+floor((ii-1)/8)*18+floor((ii-1)/64)*2.5, ...
                mean(snipdata{iCh}(:,ii,i_snippet),3)+rem((ii-1),8)*25, ...
                'Color',cmapdata(ik,:),'LineWidth',3);
        end
        title(ax,sprintf('PC-%d | Cluster-%d (n = %d)', iCh, ik, sum(i_snippet)),'FontName','Tahoma','Color','k');
        if nMonitor > 2
            set(fig,'Position',[-2940 18 1165 529]);
        end
        utils.save_figure(fig,fullfile("C:\Data\Shared\Output","MCP01_2024_04_12","MUAPs"),sprintf("MUAP-Templates_PC-%02d_Cluster-%02d",iCh,ik),'ExportAs',{'.png'});
    end
end
