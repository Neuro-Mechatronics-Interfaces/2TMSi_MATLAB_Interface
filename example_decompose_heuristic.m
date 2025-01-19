
x = TMSiSAGA.Poly5.read("C:/MyRepos/NML/2TMSi_MATLAB_Interface/.local-tests/Max_2024_12_29_Synchronized_1.poly5");
t = 0:0.0005:(0.0005*(size(x.samples,2)-1));

SELECTED_CHANNEL = 9;

bad_ch = [32,71,72,80,88,90];
n_bad_ch = numel(bad_ch);
channelOrder = textile_8x8_uni2grid_mapping();
channelOrder = [channelOrder + 70; channelOrder];

uni = filtfilt(b_hpf,a_hpf,x.samples(channelOrder,:)')';
uni(bad_ch,:) = randn(n_bad_ch,size(uni,2));
uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);


%%
nSpatialExtend = 4;
nTimeExtend = 100;
nPeakOffset = 20;
Y_ext = ckc.extend(uni_s((SELECTED_CHANNEL-floor(nSpatialExtend/2)):(SELECTED_CHANNEL+floor(nSpatialExtend/2)),:), nTimeExtend);
[~,iPk] = findpeaks(uni_s(SELECTED_CHANNEL,:),'MinPeakHeight',20);
features = abs(Y_ext(:,iPk+nPeakOffset))';
[coeff,score] = pca(features);
clus = kmeans(score,4);

%%

grid_features = reshape(features', nTimeExtend, nSpatialExtend+1, numel(iPk));
fig = figure('Color','w');
L = tiledlayout(fig,2,2);
for ii = 1:4
    ax = nexttile(L); set(ax,'NextPlot','add');
    ydata = grid_features(:,:,clus==ii);
    ax.ColorOrder = repmat(ax.ColorOrder(ii,:),nSpatialExtend+1,1) .* (linspace(0.5,1,nSpatialExtend+1)');
    for k = 1:size(ydata,3)
        plot(ax,-(nPeakOffset*0.5 - 0.25):0.5:((nTimeExtend-nPeakOffset)*0.5 - 0.25), ...
            ydata(:,:,k) + (0:30:(nSpatialExtend*30)));
    end
end
title(L, "target waveforms");
xlabel(L,'Time (ms)');

%%