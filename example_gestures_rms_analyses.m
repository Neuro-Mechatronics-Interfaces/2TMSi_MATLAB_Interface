%%EXAMPLE_GESTURES_RMS_ANALYSES  Illustrates RMS gesture analysis

close all force;
clear;
clc;

SUBJ = "MCP04";
SESSION = "2024_05_16";
TANK = sprintf("%s_%s", SUBJ, SESSION);

C = getfield(load(sprintf('C:/Data/Temp/%s/metadata.mat',TANK),'C'),'C');
GRID_NAME = ["Proximal Extensor", "Distal Extensor", "Proximal Flexor", "Distal Flexor"];

SLIDE_DIMENSIONS = [10, 7.5]; % Inches (default)
RMS_MAP_POSITION = [0, 4, 4, 2.5; ...
                    6, 4, 4, 2.5; ...
                    0, 0, 4, 2.5; ...
                    6, 0, 4, 2.5];

%% Initialize PowerPoint object
addpath('exportToPPTX');

pptx    = exportToPPTX('', ...
    'Dimensions',[10, 7.5], ...
    'Title',sprintf("%s Gestures RMS Analyses", TANK), ...
    'Author','Max Murphy', ...
    'Subject',TANK, ...
    'Comments',sprintf('RMS analyses of Gestures from data tank %s.', TANK));

%%
name = meta_wb_table_2_name(C);
gesture_snippets = cell(size(C,1),1);
vec_gesture = (-500:1500)';
rest_snippets = cell(size(C,1),1);
rest_rms = nan(size(C,1),256);
gesture_rms = nan(size(C,1),256);
vec_rest = (-2500:-500)';
[X,Y] = meshgrid(1:8);
[Xq,Yq] = meshgrid(linspace(1,8,256));
fprintf(1,'Please wait, exporting slide deck....000%%\n');
NGestures = size(C,1);
for ii = 1:NGestures
    data = load(fullfile('C:/Data/Temp',TANK,sprintf('%s_%d_synchronized.mat',TANK,C.Trial(ii))));
    rising = utils.parse_sync(data.sync, 0, 'InvertLogic', false);
    data.t = (0:(size(data.uni,2)-1))./data.sample_rate;

    fig = figure('Renderer','zbuffer','Color','w','Position',[488   460   800   400]); %#ok<*FGREN>
    ax = axes(fig,"NextPlot",'add','XColor','none','YColor','none');
    h = plot(ax, data.t, data.uni(3:64:end,:)+((0:100:300)'));
    if ii == 1
        CDATA = ax.ColorOrder(1:4,:);
    end
    for iH = 1:4
        h(iH).DisplayName = sprintf('%s Example', GRID_NAME(iH));
    end
    plot(ax, data.t, (data.sync-30)*100 + 400, 'Color', 'k', 'DisplayName', 'Gesture Prompts');
    plot(ax, data.t(rising), (data.sync(rising)-30)*100 + 400, 'Color', 'r', 'LineStyle', 'none', 'Marker', '*', 'DisplayName', 'Rising Trigger');
    legend(ax,'FontName','Tahoma','TextColor','black','Location','eastoutside');
    plot.add_scale_bar(ax,-2.5,-75,2.5,25);

    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
        'Position',[4 7 0.5 0.5], ...
        'VerticalAlignment','bottom', ...
        'HorizontalAlignment','center', ...
        'FontSize', 10);
    pptx.addTextbox(name{ii}, ...
        'Position',[0 7.12 3.75 0.38], ...
        'FontSize', 14);
    pptx.addPicture(fig);
    delete(fig);
    all_gesture = bitand(data.sync,1)==1;
    all_rest = bitand(data.sync,1)==0;

    rising(1) = []; % Remove sync blip from Prakarsh Gesture GUI
    rising_rest = rising;
    mask_rest = rising + vec_rest;
    i_remove = any(mask_rest<1, 1);
    rising_rest(i_remove) = [];
    mask_rest(:,i_remove) = [];
    rising_gesture = rising;
    mask_gesture = rising + vec_gesture;
    i_remove = any((mask_gesture<1)|(mask_gesture > size(data.uni,2)), 1);
    mask_gesture(:,i_remove) = [];
    rising_gesture(i_remove) = [];
    rest_snippets{ii} = nan(2001, 256, numel(rising_rest));
    gesture_snippets{ii} = nan(2001, 256, numel(rising_gesture));
    for iCh = 1:256
        tmp = data.uni(iCh,:);
        rest_snippets{ii}(:,iCh,:) = tmp(mask_rest);
        gesture_snippets{ii}(:,iCh,:) = tmp(mask_gesture);
        rest_rms(ii,iCh) = rms(tmp(all_rest));
        gesture_rms(ii,iCh) = rms(tmp(all_gesture));
    end
    fig = figure('Renderer','zbuffer','Color','w','Position',[488   460   800   400]); %#ok<*FGREN>
    L = tiledlayout(fig,2,2);
    for iH = 1:4
        ax = nexttile(L);
        set(ax,"NextPlot",'add','FontName','Tahoma','ColorOrder',CDATA(iH,:));
        title(ax,GRID_NAME(iH),"FontName",'Tahoma','Color','k');
        vec = (1:64)+(64*(iH-1));
        bar_data = mean(rms(gesture_snippets{ii}(:,vec,:),1)./rms(rest_snippets{ii}(:,vec,:),1),3)';
        bar(ax, bar_data,'EdgeColor','none');
        error_data = std(rms(gesture_snippets{ii}(:,vec,:),1)./rms(rest_snippets{ii}(:,vec,:),1),[],3)';
        errorbar(ax,bar_data,error_data,'LineStyle','none');
    end
    xlabel(L,'Channel Number','FontName','Tahoma');
    ylabel(L, 'Gesture RMS / Rest RMS','FontName','Tahoma');
    title(L, name{ii}, 'FontName','Tahoma','Color','k');
    subtitle(L, sprintf('(N = %d)',size(gesture_snippets{ii},3)),'FontName','Tahoma','Color',[0.65 0.65 0.65]);

    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
        'Position',[4 7 0.5 0.5], ...
        'VerticalAlignment','bottom', ...
        'HorizontalAlignment','center', ...
        'FontSize', 10);
    pptx.addTextbox(name{ii}, ...
        'Position',[0 7.12 3.75 0.38], ...
        'FontSize', 14);
    pptx.addPicture(fig);
    delete(fig);
    pptx.addNote("Error Bars are +/- 1 standard deviation of the rest/gesture mean trial RMS (trials are 1-sec after/before rising edge of triggers for gesture/rest respectively).");

    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
        'Position',[4 7 0.5 0.5], ...
        'VerticalAlignment','bottom', ...
        'HorizontalAlignment','center', ...
        'FontSize', 10);
    
    for iH = 1:4
        fig = figure('Renderer','zbuffer','Color','w','Position',[200   200   800   600]); %#ok<*FGREN>
        cmap_current = cm.umap(CDATA(iH,:));
        ax = axes(fig,"NextPlot",'add','FontName','Tahoma','XColor','k','YColor','k','Color','none',...
                    'XTick',[],'YTick',[],'XLim',[0.525 8.525],'YLim',[0.525 8.525], ...
                    'CLim',[0 10],'Colormap',cmap_current,'Box','on');
        vec = (1:64)+(64*(iH-1));
        imgdata = reshape(gesture_rms(ii,vec),8,8)./reshape(rest_rms(ii,vec),8,8);
        imgdata_q = interp2(X,Y,imgdata,Xq,Yq,'spline');
        switch iH
            case {1,2}
                imagesc(ax,[0.5,8.5],[0.5,8.5],imgdata_q);
                xlabel(ax,GRID_NAME(iH),'FontName','Tahoma','Color',CDATA(iH,:),'FontSize',16)
                c = colorbar(ax,'Location','southoutside');
            case {3,4}
                set(ax,'YDir','reverse');
                imagesc(ax,[0.5,8.5],[0.5,8.5],fliplr(imgdata_q));
                title(ax,GRID_NAME(iH),"FontName",'Tahoma','Color',CDATA(iH,:),'FontSize',16);
                c = colorbar(ax,'Location','northoutside');
        end
        c.Label.String = "RMS Ratio";

        pptx.addPicture(fig,'Position',RMS_MAP_POSITION(iH,:));
        delete(fig);
    end

    PPTX_AddTemplateArm(pptx,'SlideDimensions',SLIDE_DIMENSIONS);
    
    pptx.addTextbox(name{ii}, ...
        'Position',[0 7.12 3.75 0.38], ...
        'FontSize', 14);
    pptx.addNote("Uses full-session TRIGGER sync instead of 1-s epochs for computing normalized gesture/rest RMS values. Image data is interpolated (x32) using 'spline' interpolation method.");
    fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*ii/NGestures));
end

pptx.save(sprintf('C:/Data/Temp/%s/%s-Gestures',TANK,TANK));
delete(pptx);

save(sprintf('C:/Data/Temp/%s/%s_Trial-Gestures.mat', TANK, TANK), ...
    'rest_snippets', 'gesture_snippets', '-v7.3');
