%EXAMPLE_DECOMPOSITION2 Shows how to do decomposition of MUAPs
clear;
close all force;
clc;

% Set constants here
K = 32;
NPC = 6;
CH = 28;
DATA_FILE = 'Max_2024_03_30_B_22.poly5';
LAMBDA = 0.1;
GAMMA = 1;

%% Load data and run spike detection
data = TMSiSAGA.Poly5.read(DATA_FILE);
uni_ch = find(startsWith({data.channels.alternative_name},'UNI'));
uni = data.samples(uni_ch,:);
[b,a] = butter(3,0.05,'high');
uni = filter(b,a,uni,[],2);
uni(:,1:100) = 0;
r = rms(uni,2);
i_bad = (r < 1) | (r > 100);
uni(i_bad,:) = 0;
uni(~i_bad,:) = uni(~i_bad,:) - mean(uni(~i_bad,:),1);

idx = uni_2_pks(uni);
idx = find(idx(CH,:));

%% 
[snips, idx] = uni_2_concatenated_snips(uni, idx);
[coeff,score,~,~,explained] = pca(snips);
F = pinv(coeff(:,1:24));
t = (0:(size(uni,2)-1))./data.sample_rate;
IPTs = F*uni;

fig = figure('Color','w','WindowState','maximized');
L = tiledlayout(fig,3,3);
ax1 = nexttile(L,1,[3 1]);
set(ax1,'NextPlot','add','FontName','Tahoma');
plot(ax1, t, IPTs(1:6,:));
title(ax1, "MUAP Trains",'FontName','Tahoma',"Color",'k');

iMUAP = 0;
for iCol = 1:2
    for iRow = 1:3
        ax = nexttile(L,3*(iRow-1)+iCol+1,[1 1]);
        iMUAP = iMUAP + 1;
        set(ax,'NextPlot','add','FontName','Tahoma','XLim',[0.5,8.5],'YLim',[0.5,8.5],'XColor','none','YColor','none');
        title(ax,sprintf('IPT-%d',iMUAP),'FontName','Tahoma','Color',ax1.ColorOrder(iMUAP,:));
        imagesc(ax,[1 8],[1 8],reshape(F(iMUAP,:),8,8));
        colorbar(ax);
    end
end

