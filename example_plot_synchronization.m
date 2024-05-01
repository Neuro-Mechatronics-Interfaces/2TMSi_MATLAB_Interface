%EXAMPLE_PLOT_SYNCHRONIZATION Example iterating over 2024-02-20 cleaned MUAPs results.
close all force;
clear;
clc;

%% Set constants
OUT_FOLDER = "C:\Data\Shared\MCP01_2024_02_20\MotorUnits Decomposition\Cleaned Figures";

%% Load metadata
C = readtable("C:\Data\Shared\MCP01_2024_02_20\MCP01_2024_02_20_Experiments-cleaned.csv");
[name,fname] = meta_wb_table_2_name(C);
C.NUnits = nan(size(C,1),1);

%% Trials 14-40 were with force modulation.
goodCombinations = cell(size(C,1),1);
for ii = 14:40
    [data,~,n] = io.load_cleaned_decomposition(ii);
    if isempty(data)
        continue;
    end
    if n.Total > 30
        warning("example:muaps:too_many_muaps","Unusually high number of MUAPs (%d) detected!",n.Total);
        % res = questdlg(sprintf("Skip current? (%s)",name{ii}), ...
        %     'Skip current?', 'Yes','No','Yes');
        % if strcmpi(res,'Yes')
        %     continue;
        % end
        continue;
    end
    [fig, C.NUnits(ii), goodCombinations{ii}] = ckc.plot_synchronization(data, n, 'Title', name{ii});
    utils.save_figure(fig,fullfile(OUT_FOLDER,"Synchronization"),fname{ii},...
        'ExportAs', {'.png'});
end
writetable(C, fullfile(OUT_FOLDER, "Summary.xlsx"));
save(fullfile(OUT_FOLDER,'Grid_and_MUAP_keys.mat'),'goodCombinations','-v7.3');

%% Get temporal recruitment and template waveforms for remaining units.
% k = 22;
% GRID_INDEX = [1,1,1,2,2,3,3,3,4];
% MUAP_INDEX = [1,2,4,3,5,1,3,4,2];

% k = 28;
% GRID_INDEX = [1,1,1,1,2,2,2,2,3,3,4,4];
% MUAP_INDEX = [1,2,3,4,2,3,4,5,1,3,2,3];
REF_MODE = 'MONO';
% for k = [14:19,21:40]
for k = 32 
    if isempty(goodCombinations{k})
        continue;
    end
    GRID_INDEX = goodCombinations{k}(:,1)';
    MUAP_INDEX = goodCombinations{k}(:,2)';
    [data,metadata,n] = io.load_cleaned_decomposition(C.Trial(k));
    fprintf(1,'%d/%d unique units in Trial-%d\n', C.NUnits(k), n.Total, C.Trial(k));

    G_ID = ["Proximal Ext"; "Distal Ext"; "Proximal Flex"; "Distal Flex" ];
    G_COL = validatecolor(["#E9502C"; "#3A71E7";  "#A7F900"; "#F929A1" ],"multiple");
    LAB_COORD = [ ...
        50, -25, 1;
        230, -25, 1;
        50, -10, 2; 
        230, -10, 2];
    for ii = 1:numel(GRID_INDEX)
        iMUAP = MUAP_INDEX(ii);
        iGrid = GRID_INDEX(ii);
        [snips, tsnip, pulses, samples] = ckc.cleaned_2_template(data, iGrid, iMUAP, ...
            'SpatialFilter', REF_MODE);
        if isempty(snips)
            continue;
        end
        fig = figure('Color', 'w');
        ax = axes(fig); %#ok<LAXES>
        ckc.add_snips_to_axes(ax, snips, tsnip, 'FormatAxes', true);
        for ik = 1:4
            text(ax, LAB_COORD(ik,1), ax.YLim(LAB_COORD(ik,3)) + LAB_COORD(ik,2), G_ID(ik), ...
                'FontWeight','bold',...
                'FontName', 'Consolas', 'FontSize', 14, 'Color', G_COL(ik,:));
        end
        title(ax,sprintf('%s | %s MUAP_%d', name{k}, G_ID(iGrid), iMUAP), ...
            'FontName', 'Tahoma', 'Color', 'k');
        utils.save_figure(fig,fullfile(OUT_FOLDER,"Templates",REF_MODE,fname{k}),sprintf("G%d_U%d",iGrid,iMUAP),...
            'ExportAs', {'.png'});
    end
    fig = ckc.plot_muap_raster(data,GRID_INDEX,MUAP_INDEX,'Title',name{k});
    utils.save_figure(fig,fullfile(OUT_FOLDER,"Recruitment"),fname{k},'ExportAs',{'.png'});
end