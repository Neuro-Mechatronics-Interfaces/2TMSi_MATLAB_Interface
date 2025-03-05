%EXAMPLE_PLAYBACK_WITH_PLS  Playback pre-loaded data from prior recording(s)
clear;
close all force;
clc;

SUBJ = "MCP04";
YYYY = 2025;
MM = 2;
DD = 14;
BLOCK = 6;

TANK = sprintf('%s_%04d_%02d_%02d', SUBJ, YYYY, MM, DD);
MY_TITLE = sprintf('%s: %04d-%02d-%02d PLS Decode', SUBJ, YYYY, MM, DD); 
DATA_ROOT = parameters('raw_data_folder');
TMSI_SUBFOLDER = 'TMSi';

SAMPLE_CHUNK_DURATION = 0.020; % seconds
LINE_VERTICAL_OFFSET = 25; % microvolts
HORIZONTAL_SCALE = 0.5; % seconds
SAMPLE_RATE_RECORDING = 2000;
FC_SMOOTHER = 6; % Hz, for decode output
CDATA = parameters('color_textiles');

%% Load data
x = load_align_2_textile_poly5(SUBJ, YYYY, MM, DD, BLOCK, ...
    'DataRoot', DATA_ROOT, ...
    'DataSubfolder', TMSI_SUBFOLDER);

% Get total number of grid channels to plot as well as number of channels
% in grid rows and columns. 
numChannels = numel(x.mask.uni);
numRows = 8; % Based on textile size
numCols = numChannels/8;

% Get total number of samples in record as well as samples per chunk and
% relative indexing vector.
nTotal = size(x.env,2);
step_size = round(SAMPLE_CHUNK_DURATION * SAMPLE_RATE_RECORDING);
sample_vec = 1:step_size;

%% Load model
BETA = getfield(load(sprintf('%s/%s/%s/%s_MODEL.mat',DATA_ROOT,TANK,TMSI_SUBFOLDER,TANK),'BETA'),'BETA');

%% Setup graphics
% Estimate how long to pause between each read iteration:
h_scale = round(SAMPLE_RATE_RECORDING * HORIZONTAL_SCALE);
h_spacing = 0.1*h_scale;
[b,a] = butter(1,FC_SMOOTHER/(SAMPLE_RATE_RECORDING/2),'low');
zs = zeros(1,3);
vigem_gamepad(1);

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','w',...
    'Name','Sample Reader Interface',...
    'Position',[150   50   720   750]);
L = tiledlayout(fig,3,4);
ax = nexttile(L,1,[3 3]);
set(ax,'NextPlot','add', ...
    'YLim',[-0.5*LINE_VERTICAL_OFFSET, 8.5*LINE_VERTICAL_OFFSET], ...
    'XColor','none','YColor','none', ...
    'XLim',[-10, (numCols+0.1)*(h_scale+h_spacing)], ...
    'Clipping', 'off');
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
h = gobjects(numChannels,1);
for iH = 1:numChannels
    h(iH) = line(ax,(1:h_scale)+floor((iH-1)/8)*(h_scale+h_spacing), ...
                    nan(1,h_scale), ...
                    'Color',CDATA(iH,:),...
                    'LineWidth',0.5,...
                    'LineStyle','-', ...
                    'Marker', '*', ...
                    'MarkerEdgeColor', 'r', ...
                    'MarkerIndices', []);
end

cursor_ax = nexttile(L,4,[1 1]);
set(cursor_ax,'NextPlot','add','FontName','Consolas','XLim',[-1.1,1.1],'YLim',[-1.1,1.1]);
box(cursor_ax,'on');
state = [0, 0];
h_cursor = line(cursor_ax,state(1),state(2),'Marker','o',...
    'LineStyle','none','MarkerIndices',1,...
    'MarkerFaceColor','b','MarkerEdgeColor','k','MarkerSize',10);
txt_decode = title(cursor_ax,"DEASSERTED",'FontName','Consolas','Color','k');
title(cursor_ax,'Decode Output','FontName','Tahoma','Color','k');

decode_ax = nexttile(L,8,[1 1]);
set(decode_ax,'NextPlot','add','FontName','Tahoma', ...
    'YTick',[],'XColor','none','YColor','none','YLim',[-1, 1]);
h_x = line(decode_ax,1:h_scale,nan(1,h_scale),'Color','k','LineStyle','-','LineWidth',1.5);
h_y = line(decode_ax,1:h_scale,nan(1,h_scale),'Color',[0.65 0.65 0.65],'LineStyle','-','LineWidth',1.5);
h_btn = line(decode_ax,1:h_scale,nan(1,h_scale),'Color','m','LineStyle',':','LineWidth',1.25);

sync_ax = nexttile(L,12,[1 1]);
set(sync_ax,...
    'NextPlot','add','FontName','Tahoma', ...
    'YLim',[-0.1, 1.1],'YTick',[],'XColor','none','YColor','none');
title(sync_ax,'Sync','FontName','Tahoma','Color','k');
h_sync = line(sync_ax,1:h_scale,nan(1,h_scale),'Color','k','LineStyle','-','LineWidth',1.5);


loopTic = tic;
% Run loop while figure is open.
while isvalid(fig)
    hpf = apply_del2_textiles(x.samples(x.mask.uni,sample_vec))';
    env = x.env(:, sample_vec)';
    sync = x.samples(x.mask.trig(1),sample_vec);

    % % % Calculation part % % %
    iVec = rem(sample_vec-1,h_scale)+1;
    % Compute the PLS regression predicted values
    Y = [ones(step_size,1), env] * BETA;
    [Ys,zs] = filter(b,a,Y,zs,1);
    state = update_nonlinear_velocity_decode(state, Ys(:,1:2), ...
        'XBound', [-5,5], 'XDeadzone', 0.5, ...
        'YBound',[-5,5], 'YDeadzone', 0.5);

    % % % Graphics update part % % %
    try
        time_txt.String = sprintf('T = %07.3fs', (sample_vec(1)-1)/SAMPLE_RATE_RECORDING);
        % Update the unipolar grid montage ydata values with new chunk data
        for iH = 1:numChannels
            h(iH).YData(iVec) = hpf(:,iH)+LINE_VERTICAL_OFFSET*rem(iH-1,8);
        end
        % Update the sync indicator with new chunk data
        h_sync.YData(iVec) = bitand(sync,1)==0;
    
        % Handle decode assertion/deassertion indication
        [~,asserting] = handle_pacman_decode(Ys);
        if asserting
            txt_decode.String = "ASSERTED";
        else
            txt_decode.String = "DEASSERTED";
        end
        
        set(h_cursor,'XData',state(1),'YData',state(2));
        h_x.YData(iVec) = Ys(:,1);
        h_y.YData(iVec) = Ys(:,2);
        h_btn.YData(iVec) = Ys(:,3);
    catch
        break;
    end
    
    % Block until enough time has elapsed.
    while toc(loopTic) < (SAMPLE_CHUNK_DURATION-0.016)
        pause(SAMPLE_CHUNK_DURATION*0.01);
    end
    loopTic = tic();
    % Update loop timer and sample chunk vector before next iteration.
    sample_vec = rem(sample_vec + step_size - 1, nTotal) + 1;
end

disp("Exited loop successfully.");
vigem_gamepad(0);