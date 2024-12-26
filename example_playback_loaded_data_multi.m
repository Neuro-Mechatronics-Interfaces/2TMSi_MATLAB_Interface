%EXAMPLE_PLAYBACK_LOADED_DATA_MULTI  Playback pre-loaded data from prior recording(s), from multiple SAGAs
%#ok<*UNRCH>
clear;
close all force;
clc;

LOAD_DATA_DIRECT = true;
LOAD_WEIGHTS = false;

TAG = ["Distal Flexor"; "Distal Extensor"];
if LOAD_DATA_DIRECT
    MY_TITLE = "MCP01 - 2024-04-12 - WRIST FLEXION"; 
    % MY_TITLE = "MCP01 - 2024-04-12 - WRIST EXTENSION";
    load(fullfile(pwd,sprintf('%s - DATA.mat',MY_TITLE)),'data','sync','iExc');
else
    DATA_ROOT = "C:/MyRepos/MetaLocal/Data/MCP01_2024_04_12";
    T = readtable(fullfile(DATA_ROOT,"MCP01_2024_04_12_Experiments.csv"),'Delimiter',',','ReadVariableNames',true);
    TRIAL_NUMS = 23;
    poly5_files = ["C:/Data/TMSi/MCP03/MCP03_2024_04_23/MCP03_2024_04_23_A_DISTFLX_15.poly5";
                   "C:/Data/TMSi/MCP03/MCP03_2024_04_23/MCP03_2024_04_23_B_DISTEXT_15.poly5"];
    % poly5_files = strings(4,numel(TRIAL_NUMS));
    % for ii = 1:numel(TRIAL_NUMS)
    %     k = find(T.Trial==TRIAL_NUMS(ii),1,'first');
    %     poly5_files(:,ii) = [fullfile(DATA_ROOT,T.TMSiFileExtProx(k)); ...
    %                          fullfile(DATA_ROOT,T.TMSiFileExtDist(k)); ...
    %                          fullfile(DATA_ROOT,T.TMSiFileFlexDist(k)); ...
    %                          fullfile(DATA_ROOT,T.TMSiFileFlexProx(k))];
    % end
    % poly5_files = [...
    %     fullfile(pwd,"MCP01_2024_04_12_B_EXT_4.poly5"); ...
    %     fullfile(DATA_ROOT,"Wrist Extension","1712945861.4286742_dev2_-20240412_141741.poly5"); ...
    %     fullfile(DATA_ROOT,"Wrist Extension","1712945861.4286742_dev1_-20240412_141741.poly5"); ...
    %     fullfile(pwd,"MCP01_2024_04_12_A_FLX_4.poly5")];
    % MY_TITLE = "MCP01 - 2024-04-12 - WRIST EXTENSION";
    % poly5_files = [...
    %     fullfile(pwd,"MCP01_2024_04_12_B_EXT_2.poly5"); ...
    %     fullfile(DATA_ROOT,"Wrist Flexion","1712945596.6765876_dev2_-20240412_141316.poly5"); ...
    %     fullfile(DATA_ROOT,"Wrist Flexion","1712945596.6765876_dev1_-20240412_141316.poly5"); ...
    %     fullfile(pwd,"MCP01_2024_04_12_A_FLX_2.poly5")];
    % MY_TITLE = "MCP01 - 2024-04-12 - WRIST FLEXION";
    % MY_TITLE = "MCP01 - 2024-04-12 - WRIST FLEX RING EXT WRIST EXT";
    MY_TITLE = "MCP03 - 2024-04-23 - Multi-Gesture";
    [data,sync] = io.load_align_saga_data_many(poly5_files);
    iExc = nan;
end
TANK = strsplit(MY_TITLE, " - ");
TANK = sprintf('%s_%s',TANK(1),strrep(TANK(2),"-","_"));

%%
ch_name = {data.channels.alternative_name};
[iUni,iBip,iTrig,iCounter] = get_saga_channel_masks(data.channels);
nUni = numel(iUni);
nGrid = ceil(nUni/64);
if isnan(iExc)
    iExc = rms(data.samples(iUni,:),2) > 9; % Too noisy channels
    save(fullfile(pwd,sprintf('%s - DATA.mat',MY_TITLE)),'data','sync','iExc','-v7.3');
end

LINE_VERTICAL_OFFSET = 10; % microvolts
HORIZONTAL_SCALE = 2.00; % seconds
SAMPLE_RATE_RECORDING = data.sample_rate;

%% Setup graphics
% Estimate how long to pause between each read iteration:
h_scale = round(SAMPLE_RATE_RECORDING * HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;
grid_spacing = 0.5*h_scale;

% Create a GUI that lets you break the loop if needed:
nMonitors = size(get(groot,'MonitorPositions'),1);
switch nMonitors
    case 1
        pos = [15         111        1496         748];
    case 3
        pos = [-2681          44        1510         643];
    otherwise
        pos = [15         111        1496         748];
end

fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',pos);
L = tiledlayout(fig,5,1);
ax = nexttile(L,1,[4 1]);
cmapdata = winter(nUni);
set(ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XLim',[-10, 8.1*(h_scale+h_spacing)*nGrid+(nGrid-1)*grid_spacing], ...
    'Clipping', 'off');
for ii = 1:numel(TAG)
    text(ax, (3.5 + 8*(ii-1))*(h_scale+h_spacing)+(ii-1)*grid_spacing, 8.5*LINE_VERTICAL_OFFSET, TAG(ii), ...
        'FontName', 'Consolas','FontWeight','bold','Color',cmapdata(32+64*(ii-1),:));
end
line(ax,[-(h_scale+h_spacing), -(h_scale+h_spacing)], [-0.4*LINE_VERTICAL_OFFSET, 0.6*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -1.02*(h_scale+h_spacing), 0.65*LINE_VERTICAL_OFFSET, sprintf('%4.1f\\muV', LINE_VERTICAL_OFFSET), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','left', 'VerticalAlignment','bottom');

line(ax,[-(h_scale+h_spacing), -h_spacing], [-0.4*LINE_VERTICAL_OFFSET,-0.4*LINE_VERTICAL_OFFSET], ...
    'Color', 'k', 'LineWidth', 1.5);
text(ax, -h_spacing, -0.45*LINE_VERTICAL_OFFSET, sprintf('%4.1fms', round(h_scale/(SAMPLE_RATE_RECORDING*1e-3),1)), ...
    'FontName','Tahoma','Color','k','HorizontalAlignment','right','VerticalAlignment','top');


title(ax, MY_TITLE,'FontName','Tahoma','Color','k');
time_txt = subtitle(ax, 'T = 0.000s', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
h = gobjects(nUni,1);
for iH = 1:nUni
    h(iH) = line(ax,(1:h_scale)+floor((iH-1)/8)*(h_scale+h_spacing)+floor((iH-1)/64)*grid_spacing, ...
                    nan(1,h_scale), ...
                    'Color',cmapdata(iH,:),...
                    'LineWidth',0.5,...
                    'LineStyle','-');
end
h_model = line(ax, linspace(-10, 8.1*(h_scale+h_spacing)*nGrid+(nGrid-1)*grid_spacing, 20), ones(1,20).*8.25, 'Color', 'k', 'LineWidth', 1, 'LineStyle', ':');

sync_ax = nexttile(L,5,[1 1]);
maxSync = max(data.samples(iTrig(end),:));
minSync = min(data.samples(iTrig(end),:));
deltaSync = maxSync - minSync;
set(sync_ax,'NextPlot','add','FontName','Tahoma','YLim',[minSync-0.05*deltaSync, maxSync+0.05*deltaSync],'YTick',[]);
title(sync_ax,'Sync','FontName','Tahoma','Color','k');
h_sync = line(sync_ax,1:h_scale,nan(1,h_scale),'Color','k','LineStyle','-','LineWidth',1.5);

% Run loop while figure is open.
needs_initial_ts = true;
ts0 = 0;
nTotal = size(data.samples,2);
step_size = round(h_scale * 0.1);
sample_vec = 1:step_size;
counter_data = data.samples(iCounter(end),:);
counter_data = counter_data - counter_data(1) + 1;
trigger_data = data.samples(iTrig(end),:);
trigger_data(counter_data < sync{1}.rising(2)) = minSync;
model_update_step = 1;
channel_vec = (1:nUni)';
while isvalid(fig)
    uni = data.samples(iUni, sample_vec);
    uni(iExc,:) = 0;
    counter = counter_data(sample_vec);
    trig = trigger_data(sample_vec);
    if needs_initial_ts
        ts0 = counter(end)/SAMPLE_RATE_RECORDING;
        needs_initial_ts = false;
    end
    time_txt.String = sprintf('T = %07.3fs', counter(end,end)/SAMPLE_RATE_RECORDING - ts0);
    iVec = rem(counter-1,h_scale)+1;
    for iH = 1:nUni
        h(iH).YData(iVec) = uni(iH,:)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
    end
    h_sync.YData(iVec) = trig;
    r = rms(uni,2);
    decode = randn(1,1) .* 15; % This is supposed to me model(r) or r * BETA;
    h_model.YData(model_update_step) = decode;

    drawnow limitrate;
    pause(0.005);
    model_update_step = rem(model_update_step, 20) + 1;
    sample_vec = rem(sample_vec + step_size - 1, nTotal) + 1;
end

%% After done, make summary of RMS changes
uni_samples = data.samples(iUni,:);
uni_samples(iExc,:) = 0;
moving_rms_fast = movstd(uni_samples,[20, 20], 1, 2);
uni_blanked = uni_samples;
uni_blanked(moving_rms_fast > 20) = 0;
moving_rms = movstd(uni_samples,[200, 200],1,2);
moving_rms_fast = movstd(uni_samples,[20, 20], 1, 2); % Repeat now that we blanked.

trigger_mask = bitand(trigger_data,deltaSync)==deltaSync;
go_rms = rms(uni_blanked(:,trigger_mask),2);
rest_rms = rms(uni_blanked(:,~trigger_mask),2);

fig = figure('Color','w'); 
L = tiledlayout(fig,2,2); 
rest_ax = nexttile(L,1,[1 1]); 
set(rest_ax,'NextPlot','add','FontName','Tahoma'); 
bar(rest_ax,rest_rms,'FaceColor','k'); 
title(rest_ax,"Rest"); 
ylabel(rest_ax,'RMS'); 
xline(rest_ax,0:64:(nGrid*64),'Color','k','LineStyle',':');

go_ax = nexttile(L,2,[1 1]); 
set(go_ax,'NextPlot','add','FontName','Tahoma');
bar(go_ax,go_rms,'FaceColor','b'); 
title(go_ax,"GO"); 
xline(go_ax,0:64:(nGrid*64),'Color','k','LineStyle',':');

rms_ylim = [0, max(rest_ax.YLim(2),go_ax.YLim(2))];
ylim(go_ax,rms_ylim);
ylim(rest_ax,rms_ylim);

ax = nexttile(L,3,[1 2]); 
set(ax,'NextPlot','add','FontName','Tahoma'); 
for ii = 1:numel(TAG)
    vec = (1:64)+(ii-1)*64;
    bar(ax,vec,100*(go_rms(vec)-rest_rms(vec))./rest_rms(vec),'EdgeColor','none','FaceColor',cmapdata(32+64*(ii-1),:)); 
end
title(ax,"(GO - REST) / REST"); 
ylabel(ax,"%\DeltaRMS"); 
ylim(ax,[ax.YLim(1),max(ax.YLim(2),100)]);
title(L,MY_TITLE);
xlabel(L,'Grid Channel');

for ii = 1:numel(TAG)
    text(ax, 32 + 64*(ii-1), ax.YLim(2)*0.9, TAG(ii), ...
        'FontName', 'Consolas','FontWeight','bold',...
        'VerticalAlignment','middle','HorizontalAlignment','center',...
        'Color',cmapdata(32+64*(ii-1),:));
    xline(ax,[64*(ii-1)+0.5,64*ii-0.5],...
        'LineStyle','--','Color',cmapdata(32+64*(ii-1),:),'LineWidth',2);
end

utils.save_figure(fig,fullfile(pwd,"Meta","Out",TANK,"4Grid"),sprintf('%s - RMS',MY_TITLE),'ExportAs',{'.png','.svg'});

%% How does RMS fluctuate over course of trial?
if LOAD_WEIGHTS
    load(sprintf('%s_NMF-Weights.mat',TANK),'W');
    fprintf(1,'Recovering least-squares nonnegative estimate of factor encodings...');
    H = lsqnonneg_matrix(moving_rms_fast,W);
    fprintf(1,'complete\n');
else
    fprintf(1,'Recovering NMF weights...');
    W = nnmf(moving_rms_fast(:,trigger_mask),16);
    fprintf(1,'complete. Recovering least-squares factor encoding estimates...');
    H = lsqnonneg_matrix(moving_rms_fast,W);
    fprintf(1,'complete\n');
end

%% Plot out Weights
close all force;
fig = figure('Color','w','Name','RMS NMFs','WindowState','maximized','UserData',struct('W',W));
nRow = ceil(sqrt(size(W,2)));
nCol = ceil(size(W,2)/nRow);
L = tiledlayout(fig,nRow,nCol);
for ii = 1:size(W,2)
    ax = nexttile(L,ii,[1 1]);
    set(ax,'NextPlot','add','XTick',4:8:(4+8*(nGrid-1)),...
        'XTickLabel',TAG,'FontName','Tahoma','XLim',[0.5, (nGrid*8)+0.5],'YLim',[0.5, 8.5]);
    imagesc(ax,[1 nGrid*8],[1 8],reshape(W(:,ii),8,nGrid*8));
    xline(ax,8.5:8:(8.5+8*(nGrid-1)),'LineStyle','-','LineWidth',1.5,'Color','w');
    colorbar(ax);
    title(ax,sprintf('NMF-%d',ii),'FontName','Tahoma','Color',[0.65 0.65 0.65]);
end
title(L,MY_TITLE);
utils.save_figure(fig,fullfile(pwd,"Meta","out",TANK,"4Grid"),sprintf('%s - NMF',MY_TITLE),'ExportAs',{'.png','.svg'});

%% Plot out encodings, indicating the "GO" cues
cue_data = bitand(data.samples(iTrig(end),:),deltaSync)./deltaSync;
fig = figure('Color','w','Name','NMF Encodings','WindowState','maximized','UserData',struct('H',H,'cue_data',cue_data));
t = (0:(size(H,2)-1))/SAMPLE_RATE_RECORDING;
ax = axes(fig,'NextPlot','add','FontName','Tahoma');
for ii = 1:size(H,1)
    plot(ax,t(1:end-100),H(ii,1:(end-100))'+0.005*ii,'LineStyle','-','LineWidth',1,'DisplayName',sprintf('Factor-%d',ii));
end
plot(ax,t(1:end-100),cue_data(1:(end-100)).*ax.YLim(2),'Color','k','LineWidth',1.5,'DisplayName','CUE');
legend(ax);
utils.save_figure(fig,fullfile(pwd,"Meta","out",TANK,"4Grid"),sprintf('%s - NMF-Loadings',MY_TITLE),'ExportAs',{'.png','.svg'});

%%
