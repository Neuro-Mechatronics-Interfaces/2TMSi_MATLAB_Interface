close all force;

% [mdl, saga, S, labels] = load_ab_saga_poly5_and_train_classifier('Max', 2024, 7, 10, 3);
% [b_env,a_env] = butter(3,1/(saga.sample_rate/2),'low');
% uni_env = filtfilt(b_env,a_env,abs(uni)')';
% t = 0:(1/saga.sample_rate):((size(uni,2)-1)/saga.sample_rate);

RING_NAME = ["MOST-PROXIMAL"; "PROXIMAL+1"; "PROXIMAL+2"; "PROXIMAL+3"; ...
             "DISTAL-3"; "DISTAL-2"; "DISTAL-1"; "MOST-DISTAL"];
xe = nan(8,size(uni_env,2));
ye = nan(size(xe));

for k = 0:7
    [fig,L,vec,ax] = plot_ring_labels(k, channelOrder, theta, proxdist);
    [xe(k+1,:),ye(k+1,:)] = project_ring(uni_env(channelOrder(vec),:),theta);
    scatter(ax,xe(k+1,:),ye(k+1,:),'Marker','o','MarkerFaceAlpha',0.01,'SizeData',4,'MarkerFaceColor','m','MarkerEdgeColor','none');
    
    title(L, RING_NAME(k+1),'FontName','Tahoma','Color','k');
    subtitle(L, '2D-Ring Projection', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
    utils.save_figure(fig,fullfile('export','Max_2024_07_10'),sprintf('Ring2D_k%d',k));
    
    fig = figure('Color','w','Name','Stacked Plots','Position',[353   172   607   658]); 
    L = tiledlayout(fig,3,1); 
    ax = nexttile(L); 
    set(ax,'NextPlot','add','XColor','none','FontName','Tahoma','FontSize',14,'YLim',[0.5, 5.5],'YTick',1:5,'YTickLabel',string(categories(labels))); 
    plot(ax,t,double(labels),'Color','k'); 
    title(ax,'Events','FontName','Tahoma');

    ax = nexttile(L); 
    set(ax,'NextPlot','add','XColor','none','FontName','Tahoma','FontSize',14); 
    yyaxis(ax,'left');
    set(ax,'YLim',[-50, 50],'YColor',[1.00 0.00 0.00]);
    plot(ax,t,uni(channelOrder(vec(1)),:),'Color','r',"LineWidth",0.5);
    ylabel(ax,'HPF EMG (\muV)', 'FontName','Tahoma','Color','r');
    yyaxis(ax,'right');
    set(ax,'YLim',[0 3],'YColor',[0.00 0.00 1.00]);
    plot(ax,t,uni_env(channelOrder(vec(1)),:),'Color','b','LineWidth',1.0);
    ylabel(ax,'ENVELOPE EMG (\muV)', 'FontName','Tahoma','Color','b');
    title(ax, sprintf('UNI-%03d EMG', channelOrder(vec(1))),'FontName','Tahoma','Color','k');
    
    ax = nexttile(L); 
    set(ax,'NextPlot','add','FontName','Tahoma','FontSize',14); 
    yyaxis(ax,'left');
    set(ax,'YLim',[-2.5 2.5],'YColor',[0.00 0.00 0.00]);
    plot(ax, t, xe(k+1,:),'Color','k');
    ylabel(ax,'X_{proj} (a.u.)','FontName',"Tahoma",'Color','k');
    yyaxis(ax,'right');
    set(ax,'YLim',[-2.5 2.5],'YColor',[0.65 0.65 0.65]);
    plot(ax, t, ye(k+1,:),'Color',[0.65 0.65 0.65]);
    ylabel(ax,'Y_{proj} (a.u.)','FontName',"Tahoma",'Color',[0.65 0.65 0.65]);
    xlabel(ax,'Time (s)', 'FontName','Tahoma','Color','k');

    linkaxes(findobj(L.Children,'type','axes'),'x');
    title(L, RING_NAME(k+1),'FontName','Tahoma','Color','k');
    utils.save_figure(fig,fullfile('export','Max_2024_07_10'),sprintf('Stacked_k%d',k));
end

%%
xy = labels_2_cartesian(labels);
xy_plot = xy;
xy_plot(xy_plot==0) = nan;
[beta0, beta, xy_hat] = fit_poly_model(xy, uni_env);
fig = figure('Color','w','Name','Continuous 2D Regression');
ax = axes(fig,'NextPlot','add','FontName','Tahoma','ColorOrder',[0 0 0; 0.65 0.65 0.65]);
plot(ax, t, xy_plot, 'LineStyle', '-', 'LineWidth', 1.5);
plot(ax, t, (xy_hat)' + beta0','LineStyle', ':', 'LineWidth', 0.75);
xlabel(ax,'Time (s)', 'FontName','Tahoma',"Color",'k');
ylabel(ax,'2D Position (a.u.)', 'FontName','Tahoma','Color','k');
title(ax, 'position_{hat} ~ \beta_0 + \beta * ||uni_{env}||', 'FontName','Tahoma','Color','k');
subtitle(ax, 'Solid: Instructed | Dashed: Predicted', 'FontName','Tahoma','Color',[0.75 0.75 0.75]);
utils.save_figure(fig,fullfile('export','Max_2024_07_10'),'Decode_LSOptimal_Regression2D');

xy_decode = naive_bayes_decode_2D(beta0, beta, uni_env);
fig = figure('Color','w','Name','Continuous 2D Naive Bayes Classifier');
ax = axes(fig,'NextPlot','add','FontName','Tahoma','ColorOrder',[0 0 0; 0.65 0.65 0.65]);
plot(ax, t, xy_plot, 'LineStyle', '-', 'LineWidth', 1.5);
plot(ax, t, xy_decode,'LineStyle', ':', 'LineWidth', 0.75);
xlabel(ax,'Time (s)', 'FontName','Tahoma',"Color",'k');
ylabel(ax,'2D Position (a.u.)', 'FontName','Tahoma','Color','k');
title(ax, 'position_{hat} ~ \beta_0 + \beta * ||uni_{env}||', 'FontName','Tahoma','Color','k');
subtitle(ax, 'Solid: Instructed | Dashed: Predicted', 'FontName','Tahoma','Color',[0.75 0.75 0.75]);
utils.save_figure(fig,fullfile('export','Max_2024_07_10'),'Decode_Result_2D');

%%
for k = 0:7
    [fig,L,vec,ax] = plot_ring_labels(k, channelOrder, theta, proxdist);
    x_beta = uni_env(channelOrder(vec),:).*(beta(1,channelOrder(vec))');
    [xx,yx] = project_ring(x_beta,theta);
    y_beta = uni_env(channelOrder(vec),:).*(beta(2,channelOrder(vec))');
    [xy,yy] = project_ring(y_beta,theta);
    scatter(ax,xx,yx,'Marker','o','MarkerFaceAlpha',0.01,'SizeData',4,'MarkerFaceColor','k','MarkerEdgeColor','none');
    scatter(ax,xy,yy,'Marker','o','MarkerFaceAlpha',0.01,'SizeData',4,'MarkerFaceColor',[0.65 0.65 0.65],'MarkerEdgeColor','none');
    
    title(L, RING_NAME(k+1),'FontName','Tahoma','Color','k');
    subtitle(L, '2D-Ring Projection (\beta)', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
    utils.save_figure(fig,fullfile('export','Max_2024_07_10'),sprintf('Ring2D_k%d__Beta-Weighted',k));
    
    fig = figure('Color','w','Name','Stacked Plots','Position',[353   172   607   658]); 
    L = tiledlayout(fig,3,1); 
    ax = nexttile(L); 
    set(ax,'NextPlot','add','XColor','none','FontName','Tahoma','FontSize',14,'YLim',[0.5, 5.5],'YTick',1:5,'YTickLabel',string(categories(labels))); 
    plot(ax,t,double(labels),'Color','k'); 
    title(ax,'Events','FontName','Tahoma');

    ax = nexttile(L); 
    set(ax,'NextPlot','add','XColor','none','FontName','Tahoma','FontSize',14); 
    yyaxis(ax, 'left');
    set(ax,'YColor','b');
    plot(ax,t,x_beta,'Color','b','LineWidth',0.5);
    ylabel(ax,'X_{beta}', 'FontName','Tahoma','Color','b');
    yyaxis(ax, 'right');
    set(ax,'YColor','r');
    plot(ax,t,y_beta,'Color','r','LineWidth',0.5);
    ylabel(ax,'Y_{beta}', 'FontName','Tahoma','Color','r');
    title(ax, 'Projected XY','FontName','Tahoma','Color','k');
    
    ax = nexttile(L); 
    set(ax,'NextPlot','add','FontName','Tahoma','FontSize',14); 
    yyaxis(ax,'left');
    set(ax,'YColor',[0.00 0.00 0.00]);
    plot(ax, t, xx,'Color','k');
    plot(ax, t, xy,'Color','k', 'LineStyle', ':');
    ylabel(ax,'X_{proj} (a.u.)','FontName',"Tahoma",'Color','k');
    yyaxis(ax,'right');
    set(ax,'YColor',[0.65 0.65 0.65]);
    plot(ax, t, yy,'Color',[0.65 0.65 0.65]);
    plot(ax, t, yx,'Color',[0.65 0.65 0.65], 'LineStyle', ':');
    ylabel(ax,'Y_{proj} (a.u.)','FontName',"Tahoma",'Color',[0.65 0.65 0.65]);
    xlabel(ax,'Time (s)', 'FontName','Tahoma','Color','k');

    linkaxes(findobj(L.Children,'type','axes'),'x');
    title(L, RING_NAME(k+1),'FontName','Tahoma','Color','k');
    utils.save_figure(fig,fullfile('export','Max_2024_07_10'),sprintf('Stacked_k%d__Beta-Weighted',k));
end