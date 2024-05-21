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

GESTURE_INDEX = 501:6500;
REST_INDEX = -6500:-501;
NUM_CHANNELS = 256;

% Channel indexing and gesture metadata:
[X,Y] = meshgrid(1:8);
[Xq,Yq] = meshgrid(linspace(1,8,64));
name = meta_wb_table_2_name(C);

%% Initialize PowerPoint object
addpath('exportToPPTX');

pptx    = exportToPPTX('', ...
    'Dimensions',[10, 7.5], ...
    'Title',sprintf("%s Gestures RMS Analyses", TANK), ...
    'Author','Max Murphy', ...
    'Subject',TANK, ...
    'Comments',sprintf('RMS analyses of Gestures from data tank %s.', TANK));


%% Run main loop to produce slide deck
% Pre-allocate variables
gesture_snippets = cell(size(C,1),1);
rest_snippets = cell(size(C,1),1);
rest_rms = nan(size(C,1),NUM_CHANNELS);
gesture_rms = nan(size(C,1),NUM_CHANNELS);
n_good_gesture = nan(size(C,1),1);
i_good_gesture = cell(size(C,1),1);
n_good_rest = nan(size(C,1),1);
i_good_rest = cell(size(C,1),1);

fprintf(1,'Please wait, exporting slide deck....000%%\n');
NGestures = size(C,1);
for ii = 1:NGestures
    fname_in = fullfile('C:/Data/Temp',TANK,sprintf('%s_%d_synchronized.mat',TANK,C.Trial(ii)));
    [data,rising,rest_snippets{ii},gesture_snippets{ii},rest_rms(ii,:),gesture_rms(ii,:)] = io.load_synchronized_gesture_data(fname_in, ...
        'GestureIndex', GESTURE_INDEX, ...
        'RestIndex', REST_INDEX, ...
        'NumChannels', NUM_CHANNELS);

    [H_g,pairs_g] = batch_test_covariances(gesture_snippets{ii},'Verbose',false);
    [H_r,pairs_r] = batch_test_covariances(rest_snippets{ii},'Verbose',false);
    i_good_gesture{ii} = reshape(unique(pairs_g(H_g,:)),1,[]);
    n_good_gesture(ii) = numel(i_good_gesture{ii});
    i_good_rest{ii} = reshape(unique(pairs_r(H_r,:)),1,[]);
    n_good_rest(ii) = numel(i_good_rest{ii});
    x_gesture_patch = data.t(rising.gesture(i_good_gesture{ii}) + [GESTURE_INDEX(1); GESTURE_INDEX(end); GESTURE_INDEX(end); GESTURE_INDEX(1)]);
    y_gesture_patch = repmat([-50; -50; 550; 550],n_good_gesture(ii),1);
    faces_gesture_patch = [0:3,0] + ((1:4:(4*n_good_gesture(ii)))');
    verts_gesture_patch = [x_gesture_patch(:), y_gesture_patch];

    x_rest_patch = data.t(rising.rest(i_good_rest{ii}) + [REST_INDEX(1); REST_INDEX(end); REST_INDEX(end); REST_INDEX(1)]);
    y_rest_patch = repmat([-50; -50; 550; 550],n_good_rest(ii),1);
    faces_rest_patch = [0:3,0] + ((1:4:(4*n_good_rest(ii)))');
    verts_rest_patch = [x_rest_patch(:), y_rest_patch];

    fig = figure('Renderer','zbuffer','Color','w','Position',[488   460   800   400]); %#ok<*FGREN>
    ax = axes(fig,"NextPlot",'add','XColor','none','YColor','none');
    patch(ax,'Faces',faces_rest_patch,'Vertices',verts_rest_patch,'DisplayName',"LTI_{rest}",'EdgeColor','none','FaceColor',[0.85 0.85 0.85],'FaceAlpha',0.85);
    patch(ax,'Faces',faces_gesture_patch,'Vertices',verts_gesture_patch,'DisplayName',"LTI_{go}",'EdgeColor','none','FaceColor',[0.2 0.2 1.0],'FaceAlpha',0.85);
    h = plot(ax, data.t, data.uni(3:64:end,:)+((0:100:300)'));
    if ii == 1
        CDATA = ax.ColorOrder(1:4,:);
    end
    for iH = 1:4
        h(iH).DisplayName = sprintf('%s Example', GRID_NAME(iH));
    end
    plot(ax, data.t, (data.sync-30)*100 + 400, ...
        'Color', 'k', 'DisplayName', 'Gesture Prompts');
    plot(ax, data.t(rising.gesture), (data.sync(rising.gesture)-30)*100 + 400, ...
        'Color', 'r', 'LineStyle', 'none', 'Marker', '*', 'DisplayName', 'Rising Trigger');
    legend(ax,'FontName','Tahoma','TextColor','black','Location','eastoutside');
    plot.add_scale_bar(ax,-2.5,-75,2.5,25);
    
    slideId = pptx.addSlide();
    pptx.addTextbox(num2str(slideId), ...
        'Position',[4 7 0.5 0.5], ...
        'VerticalAlignment','bottom', ...
        'HorizontalAlignment','center', ...
        'FontSize', 10);
    pptx.addTextbox(name{ii}, ...
        'Position',[0 2 10 3.5], ...
        'FontName', 'Tahoma', ...
        'FontSize', 48);

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
        imgdata_q = interp2(X,Y,imgdata,Xq,Yq,'linear');
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
    pptx.addNote("Uses full-session TRIGGER sync instead of 1-s epochs for computing normalized gesture/rest RMS values. Image data is interpolated (x8) using 'linear' interpolation method.");
    fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*ii/NGestures));
end

slideId = pptx.addSlide();
pptx.addTextbox(num2str(slideId), ...
    'Position',[4 7 0.5 0.5], ...
    'VerticalAlignment','bottom', ...
    'HorizontalAlignment','center', ...
    'FontSize', 10);
pptx.addTextbox('Summary', ...
    'Position',[0 2 10 3.5], ...
    'FontName', 'Tahoma', ...
    'FontSize', 48);

slideId = pptx.addSlide();
pptx.addTextbox(num2str(slideId), ...
    'Position',[4 7 0.5 0.5], ...
    'VerticalAlignment','bottom', ...
    'HorizontalAlignment','center', ...
    'FontSize', 10);
tableData   = [{ 'Trial','Good Rests','Good Gestures'}; ...
               table2cell(table(name, n_good_rest, n_good_gesture))];
pptx.addTable(tableData,'FontSize',10,'FontName','Times New Roman');
pptx.save(sprintf('C:/Data/Temp/%s/%s-Gestures',TANK,TANK));


%%
delete(pptx);
save(sprintf('C:/Data/Temp/%s/%s_Good-Epochs.mat',TANK,TANK), ...
    'i_good_rest', 'i_good_gesture', 'C', '-v7.3');
save(sprintf('C:/Data/Temp/%s/%s_Trial-Gestures.mat', TANK, TANK), ...
    'rest_snippets', 'gesture_snippets', ...
    'rest_rms', 'gesture_rms', ...
    'n_good_gesture', 'n_good_rest', 'C','-v7.3');
    


