%%EXAMPLE_GESTURES_MUAPS_ANALYSES  Illustrates RMS gesture analysis

close all force;
clear;
clc;

SUBJ = "MCP04";
SESSION = "2024_05_16";
TANK = sprintf("%s_%s", SUBJ, SESSION);
INPUT_FOLDER_ROOT = 'C:/Data/Temp';

C = getfield(load(sprintf('C:/Data/Temp/%s/metadata.mat',TANK),'C'),'C');
GRID_NAME = ["Proximal Extensor", "Distal Extensor", "Proximal Flexor", "Distal Flexor"];

SLIDE_DIMENSIONS = [10, 7.5]; % Inches (default)
MAP_POSITION = [0, 4, 4, 3; ...
    6, 4, 4, 3; ...
    0, 0, 4, 3; ...
    6, 0, 4, 3];

GESTURE_INDEX = 501:6500;
REST_INDEX = -6500:-501;
NUM_CHANNELS = 256;
CDATA = [         ...
    0.0000    0.4470    0.7410; ...
    0.8500    0.3250    0.0980; ...
    0.9290    0.6940    0.1250; ...
    0.4940    0.1840    0.5560];

% Channel indexing and gesture metadata:
[X,Y] = meshgrid(1:8);
[Xq,Yq] = meshgrid(linspace(1,8,64));
name = meta_wb_table_2_name(C);

%% Initialize PowerPoint object
addpath('exportToPPTX');

pptx    = exportToPPTX('', ...
    'Dimensions',[10, 7.5], ...
    'Title',sprintf("%s Gestures MUAP Analyses", TANK), ...
    'Author','Max Murphy', ...
    'Subject',TANK, ...
    'Comments',sprintf('MUAPs analyses of Gestures from data tank %s.', TANK));


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
    fname_in = fullfile(INPUT_FOLDER_ROOT,TANK,'Input',sprintf('%s_%d_synchronized.mat',TANK,C.Trial(ii)));
    data_sync = io.load_synchronized_gesture_data(fname_in, ...
        'GestureIndex', GESTURE_INDEX, ...
        'RestIndex', REST_INDEX, ...
        'NumChannels', NUM_CHANNELS);
    [data_cleaned, metadata] = io.load_autocleaned_muaps(ii,"InputRoot",fullfile(INPUT_FOLDER_ROOT,TANK,"Auto"));
    [i_source,pk2pk,snips,tsnip] = ckc.localize_muaps(data_sync, data_cleaned);

    % Add "section header" slide for this trial %
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

    

    for iIPT = 1:numel(i_source)
        if isnan(i_source)
            continue;
        end
        slideId = pptx.addSlide();
        pptx.addTextbox(num2str(slideId), ...
            'Position',[4 7 0.5 0.5], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','center', ...
            'FontSize', 10);
        pptx.addTextbox(metadata.ID_NonTracked{iIPT}, ...
            'Position',[6.5 7 3.5 0.5], ...
            'FontName', 'Tahoma', ...
            'HorizontalAlignment', 'right', ...
            'FontSize', 10);
        for iH = 1:4
            fig = figure('Renderer','zbuffer','Color','w','Position',[200   200   800   600]); %#ok<*FGREN>
            cmap_current = cm.umap(CDATA(iH,:));
            ax = axes(fig,"NextPlot",'add','FontName','Tahoma','XColor','k','YColor','k','Color','none',...
                'XTick',[],'YTick',[],'XLim',[0.525 8.525],'YLim',[0.525 8.525], ...
                'CLim',[0 1e3],'Colormap',cmap_current,'Box','on');
            vec = (1:64)+(64*(iH-1));
            imgdata = reshape(pk2pk{iIPT}(vec),8,8);
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
            c.Label.String = "Peak-to-Peak Amplitude (μV)";

            pptx.addPicture(fig,'Position',MAP_POSITION(iH,:));
            delete(fig);
        end

        PPTX_AddTemplateArm(pptx,'SlideDimensions',SLIDE_DIMENSIONS);

        pptx.addTextbox(name{ii}, ...
            'Position',[0 7.12 3.75 0.38], ...
            'FontSize', 14);
        pptx.addNote("Image data is interpolated (x8) using 'linear' interpolation method. Values are peak-to-peak amplitude (microvolts) of MUAP template waveforms from DEMUSE IPTs.");
    end
    fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*ii/NGestures));
end

pptx.save(sprintf('C:/Data/Temp/%s/%s-Gestures-MUAPs',TANK,TANK));




