x = TMSiSAGA.Poly5.read('C:/Data/TMSi/Pok/Pok_2024_08_21/Pok_2024_08_21_B_DIST_8.poly5');
[b,a] = butter(3,100/2000,'high');
uni = filtfilt(b,a,x.samples(1:64,:)')';
mu = mean(uni,1);
t = 0:(1/4000):((numel(mu)-1)/4000);
% fig = figure('Color','w','Name','Grid EMG Signals','WindowState','maximized'); 
% ax = axes(fig,'XColor','none','YColor','none','NextPlot','add', ...
%     'FontName','Tahoma','FontSize',14,'ColorOrder',winter(64)); 
% title(ax,"Pok 2024-08-21 B-DIST 8"); 
% plot(ax, t, (uni-mu)' + (0:35:(63*35)),'LineWidth',0.2); 
% plot.add_scale_bar(ax,-15,-25,-5,125); 
% utils.save_figure(fig, ...
%     'C:/Data/TMSi/Pok/Pok_2024_08_21/Export', ...
%     'Pok_2024_08_21_B_DIST_8_UNI','ExportAs',{'.png','.svg'});

%%
x = TMSiSAGA.Poly5.read('C:/Data/TMSi/Pok/Pok_2024_08_21/Pok_2024_08_21_A_PROX_8.poly5');
[b,a] = butter(3,100/2000,'high');
uni = filtfilt(b,a,x.samples(1:64,:)')';
mu = mean(uni,1);
t = 0:(1/4000):((numel(mu)-1)/4000);
% fig = figure('Color','w','Name','Grid EMG Signals','WindowState','maximized'); 
% ax = axes(fig,'XColor','none','YColor','none','NextPlot','add', ...
%     'FontName','Tahoma','FontSize',14,'ColorOrder',spring(64)); 
% title(ax,"Pok 2024-08-21 A-PROX 8"); 
% subtitle(ax,"HPF: 3rd-Order Butter 100-Hz | CAR | MONOPOLAR ");
% plot(ax, t, (uni-mu)' + (0:35:(63*35)),'LineWidth',0.2); 
% plot.add_scale_bar(ax,-15,-25,-5,125); 
% utils.save_figure(fig, ...
%     'C:/Data/TMSi/Pok/Pok_2024_08_21/Export', ...
%     'Pok_2024_08_21_A_PROX_8_UNI','ExportAs',{'.png','.svg'});

%%
E = readtable("C:\Data\Anatomy\Human Arm\Sections\Electrodes.xlsx", ...
    "Sheet","Electrodes");

%%
y = uni(1,:);
[~,locs] = findpeaks(-y,'MinPeakHeight',65);
vec = (-20:20)';
mask = locs + vec;

snips = nan(size(mask,1),size(mask,2),64);
idx = nan(64,1);
for iCh = 1:64
    tmp = uni(iCh,:);
    snips(:,:,iCh) = tmp(mask);
    idx(iCh) = find(E.Uni==(iCh+64),1,'first');
end

%%
test = squeeze(snips(:,1,:));
Zs = E.Zs(idx);
Theta = E.Theta(idx);
Rs = E.Rs(idx);
H = gobjects(64,10);
[fig,ax,H(:,1),c] = plot_cylinder_snip(Theta, Zs, Rs, test'./10); 
pause(0.030);
for ii = 2:size(snips,2)
    tmp = squeeze(snips(:,ii,:));
    H = circshift(H,1,2);
    delete(c);
    [~,~,H(:,1),c] = plot_cylinder_snip(Theta,Zs,Rs,tmp'./10,'Axes',ax);
    pause(0.030);
    if ii >= 10
        delete(H(:,end));
    end
end