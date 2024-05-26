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
MAP_POSITION = [...
                    0, 4, 4, 3; ...
                    6, 4, 4, 3; ...
                    0, 0, 4, 3; ...
                    6, 0, 4, 3  ...
                ];
TEMPLATE_POSITION = [ ...
                          4,   5, 3, 2.5; ...
                          7,   5, 3, 2.5; ...
                          4, 2.5, 3, 2.5; ...
                          7, 2.5, 3, 2.5  ...
                      ];

GESTURE_INDEX = 501:6500;
REST_INDEX = -6500:-501;
NUM_CHANNELS = 256;
CDATA = [         ...
    0.0000    0.4470    0.7410; ...
    0.8500    0.3250    0.0980; ...
    0.9290    0.6940    0.1250; ...
    0.4940    0.1840    0.5560];
AMPDATA = [750, 250, 1000, 500];

% Channel indexing and gesture metadata:
[X,Y] = meshgrid(1:8);
[Xq,Yq] = meshgrid(linspace(1,8,64));
name = meta_wb_table_2_name(C);
XSLICE = 0:0.8:(0.8*15);
FLEXOR_COL_ORDER = [8:-1:1,16:-1:9];

%% Initialize PowerPoint object
addpath('exportToPPTX');

pptx = exportToPPTX('', ...
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
%%
fprintf(1,'Please wait, exporting slide deck....000%%\n');
NGestures = size(C,1);
for ii = 1:NGestures
    fname_in = fullfile(INPUT_FOLDER_ROOT,TANK,'Input',sprintf('%s_%d_synchronized.mat',TANK,C.Trial(ii)));
    data_sync = io.load_synchronized_gesture_data(fname_in, ...
        'GestureIndex', GESTURE_INDEX, ...
        'RestIndex', REST_INDEX, ...
        'NumChannels', NUM_CHANNELS);
    [data_cleaned, metadata] = io.load_autocleaned_muaps(C.Trial(ii),"InputRoot",fullfile(INPUT_FOLDER_ROOT,TANK,"Auto"));
    [i_source,pk2pk,snips,tsnip] = ckc.localize_muaps(data_sync, data_cleaned,'Verbose',false);

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
    tIPT = (0:(size(data_cleaned.IPTs,2)-1))./data_cleaned.fsamp;
    tRef = (0:(size(data_cleaned.ref_signal,2)-1))./data_cleaned.fsamp;
    for iIPT = 1:numel(i_source)
        if isnan(i_source(iIPT))
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
            'FontName', 'Consolas', ...
            'FontWeight', 'bold', ...
            'Color', metadata.Color(iIPT,:), ...
            'HorizontalAlignment', 'right', ...
            'FontSize', 10);
        for iH = 1:4
            fig = figure('Renderer','zbuffer','Color','w',...
                'MenuBar','None','ToolBar','none','Units','inches',...
                'Position',[2 1 4.5 3.5]); %#ok<*FGREN>
            cmap_current = cm.umap(CDATA(iH,:));
            ax = axes(fig,"NextPlot",'add','FontName','Tahoma','XColor','k','YColor','k','Color','none',...
                'XTick',[],'YTick',[],'XLim',[0.525 8.525],'YLim',[0.525 8.525], ...
                'CLim',[0 AMPDATA(iH)],'Colormap',cmap_current,'Box','on', ...
                'HitTest','off');
            vec = (1:64)+(64*(iH-1));
            imgdata = reshape(pk2pk{iIPT}(vec),8,8);
            imgdata_q = interp2(X,Y,imgdata,Xq,Yq,'linear');
            switch iH
                case {1,2}
                    imagesc(ax,[0.5,8.5],[0.5,8.5],imgdata_q);
                    xlabel(ax,GRID_NAME(iH),'FontName','Tahoma','Color',CDATA(iH,:),'FontSize',24)
                    c = colorbar(ax,'Location','southoutside');
                case {3,4}
                    set(ax,'YDir','reverse');
                    imagesc(ax,[0.5,8.5],[0.5,8.5],fliplr(imgdata_q));
                    title(ax,GRID_NAME(iH),"FontName",'Tahoma','Color',CDATA(iH,:),'FontSize',24);
                    c = colorbar(ax,'Location','northoutside');
            end
            set(c.Label,'String',"Peak-to-Peak Amplitude (μV)",'FontName','Tahoma','FontSize',20);
            pptx.addPicture(fig,'Position',MAP_POSITION(iH,:));
            delete(fig);
        end
        PPTX_AddTemplateArm(pptx,'SlideDimensions',SLIDE_DIMENSIONS);
        pptx.addTextbox(name{ii}, ...
            'Position',[0 7.12 3.75 0.38], ...
            'FontSize', 14);
        pptx.addNote("Image data is interpolated (x8) using 'linear' interpolation method. Values are peak-to-peak amplitude (microvolts) of MUAP template waveforms from DEMUSE IPTs.");


        % % % Second slide is the BSS/slices/muscle co-register
        slideId = pptx.addSlide();
        pptx.addTextbox(num2str(slideId), ...
            'Position',[4 7 0.5 0.5], ...
            'VerticalAlignment','bottom', ...
            'HorizontalAlignment','center', ...
            'FontSize', 10);
        pptx.addTextbox(metadata.ID_NonTracked{iIPT}, ...
            'Position',[0 0 3.5 0.5], ...
            'FontName', 'Consolas', ...
            'Color', metadata.Color(iIPT,:), ...
            'FontWeight', 'bold', ...
            'HorizontalAlignment', 'left', ...
            'FontSize', 10);
        pptx.addTextbox('BSS ROUGH Approx', ...
            'Position',[5,0,5,0.5],...
            'FontName','Tahoma',...
            'HorizontalAlignment', 'right', ...
            'FontSize',16);

        % % % Add IPT and Ref Traces % % %
        fig = figure('Renderer','zbuffer','Color','w','Units','inches', ...
            'ToolBar', 'none','MenuBar','none',...
            'Position',[2 1 6.75 2.25]); %#ok<*FGREN>            
        ax = axes(fig,'NextPlot','add','FontName','Tahoma',...
                'XColor','none','YColor','none', ...
                'HitTest','off');
        line(ax,tRef, bitand(data_cleaned.ref_signal(1,:),1)==1, 'Color', [0.65 0.65 0.65]);
        line(ax,tIPT, data_cleaned.IPTs(iIPT,:),'Color', metadata.Color(iIPT,:));
        line(ax,tIPT(data_cleaned.MUPulses{iIPT}), data_cleaned.IPTs(iIPT,data_cleaned.MUPulses{iIPT}), ...
            'LineStyle', 'none', 'Marker', 'o', 'MarkerFaceColor', 'none', 'MarkerEdgeColor', 'k');
        plot.add_scale_bar(ax,-2.5,-0.75,2.5,0.25,'YUnits','IPT Unit','FontSize',20);

        pptx.addPicture(fig,'Position',[3.5,0.5,6.5,2.0]);
        delete(fig);

        % % % Add template image % % %
        k_slice = rem(i_source(iIPT)-1,128)+1;
        if i_source(iIPT)>128
            k_slice = ceil((k_slice-1)/8); % Get the column, first column is most-distal
            k_slice = FLEXOR_COL_ORDER(k_slice);
            i_same = (1:8) + (128 + floor((i_source(iIPT)-129)/8)*8);
            i_opp = (1:8) + (k_slice-1)*8;
            w_slice = pk2pk{iIPT}([i_opp, i_same]);
        else
            k_slice = ceil((k_slice-1)/8); % Get the column, 1 is most-proximal.
            k_slice_opp = find(FLEXOR_COL_ORDER==k_slice);
            i_opp = (1:8) + (128 + (k_slice_opp-1)*8);
            i_same = (1:8) + (k_slice-1)*8;
            w_slice = pk2pk{iIPT}([i_same, i_opp]);
        end

        PPTX_AddTemplateSlice(pptx,XSLICE(k_slice),w_slice,...
            'SlideDimensions',SLIDE_DIMENSIONS, ...
            'SourceColor', metadata.Color(iIPT,:));

        % % % Add Template for this MUAP % % %
        template = mean(snips{iIPT},3);
        x0 = diff(tsnip([1,end]))*1.05;
        xoffset = repmat(0:x0:(7*x0),8,1);
        y0 = (3*mean(pk2pk{iIPT}));
        yoffset = repmat(0:y0:(7*y0),1,8);
        for iH = 1:4
            vec = (1:64)+(64*(iH-1));
            cur_data = template(:,vec);

            if iH > 2
                xtmp = fliplr(xoffset);
                tt = (tsnip + xtmp(:))';
            else
                tt = (tsnip + xoffset(:))';
            end

            fig = figure('Renderer','zbuffer','Color','w',...
                'MenuBar','none','ToolBar','none','Units','inches',...
                'Position',[2 1 3.5 2.5]);           
            ax = axes(fig,'NextPlot','add','FontName','Tahoma',...
                'XColor','none','YColor','none', ...
                'HitTest','off');
            h_template = plot(ax, tt, cur_data + yoffset, 'LineWidth', 0.75, 'Color', [0.65 0.65 0.65]);
            plot.add_scale_bar(ax,tsnip(1)-x0*0.5,-y0,tsnip(1)+x0,y0,'FontSize',20,'XUnits','ms','XLabelScaleFactor',1e3,'YUnits','\muV');
            i_rel = i_source(iIPT) - (iH-1)*64;
            if (i_rel > 0) && (i_rel <= 64)
                [iRowTemplate, iColTemplate] = ind2sub([8 8],i_rel);
                iRowTemplateAll = max(1,iRowTemplate-1):min(8,iRowTemplate+1);
                iColTemplateAll = max(1,iColTemplate-1):min(8,iColTemplate+1);
                for iR = 1:numel(iRowTemplateAll)
                    for iC = 1:numel(iColTemplateAll)
                        indTemplate = sub2ind([8 8],iRowTemplateAll(iR), iColTemplateAll(iC));
                        set(h_template(indTemplate),'Color',CDATA(iH,:),'LineWidth', 1.5);
                    end
                end
            end
            pptx.addPicture(fig,'Position',TEMPLATE_POSITION(iH,:));
            delete(fig);
        end

        pptx.addTextbox(name{ii}, ...
            'Position',[0 7.12 3.75 0.38], ...
            'FontSize', 14);
        pptx.addNote("Approximate BSS using MRI scan of R Forearm on template adult male arm."); 
    end
    fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*ii/NGestures));
end

pptx.save(sprintf('C:/Data/Temp/%s/%s-Gestures-MUAPs',TANK,TANK));




