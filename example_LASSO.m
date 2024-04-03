%EXAMPLE_LASSO  Runs example LASSO regression, using initial kmeans algorithm.

clear; 
close all force;
clc;

%% 1. Set parameters.
CH = 28;
LAMBDA = 100;
MIN_PEAK_HEIGHT = 1; % x median absolute deviation
MIN_PEAK_DISTANCE = 10; % Samples
MAX_PC_VARCAPT = 95;
TOP_PEAK_FRACTION = 0.33;   
MIN_PEAKS_RETAINED = 30;
MAX_MUAPS = 40;
FCUTOFF = 10; % Hz
PC_INDEX = 1;
INPUT_FILE = "C:/Data/TMSi/Max/Max_2024_03_30_B_22.poly5";

%% 2. Load data and derive the relevant statistics.
data = TMSiSAGA.Poly5.read(INPUT_FILE);
[b,a] = butter(3, FCUTOFF / (data.sample_rate/2), 'high');
uni_ch = find(startsWith({data.channels.alternative_name},'UNI'));
uni_d = filtfilt(b,a,data.samples(uni_ch,:)');

warning('off','stats:pca:ColRankDefX');
[coeff,score,~,~,explained] = pca(uni_d);
explained_total = cumsum(explained);
warning('on','stats:pca:ColRankDefX');

[~,idx] = findpeaks(abs(score(:,PC_INDEX)), ...
    'MinPeakHeight', median(abs(score(:,PC_INDEX)))*MIN_PEAK_HEIGHT, ...
    'MinPeakDistance', MIN_PEAK_DISTANCE);
[snips, idx, n_pc, n_ts] = scores_2_extended(abs(score), explained, idx);

%% 3. Feed the relevant statistics to the LASSO regressor.
% `iterative_LASSO` -- estimate kernels for each MUAP separately
% `combined_LASSO` -- estimate the kernel "all-at-once" 
% `multi_LASSO` -- probably the way to go--has to estimate peak height for
%                    every channel, for each peak. So steps are:
%                       1. Detect peaks (pca)
%                       2. Use LASSO to fit muapTrain
%                       3. 
%   As of 2024-04-01 not sure which of these is better. 
res = abs(score(:, PC_INDEX));
fig = figure('Color','w','Name','Residual Magnitude');
ax = axes(fig,'NextPlot','add','FontName','Tahoma','YScale','log');
h = line(ax,0,nan,'Color','k','MarkerFaceColor','b','Marker','o','MarkerIndices',1);
xlabel(ax, 'Iteration','FontName','Tahoma','Color','k');
ylabel(ax, 'Residual (L^2 norm)', 'FontName','Tahoma','Color','k');
title(ax,sprintf('Recovery of MUAPS from top %d PCs', n_pc), 'Color','k','FontName','Tahoma');
subtitle(ax, sprintf('Spikes: PC-%d | Strikes: 0', PC_INDEX), 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
curPC_Peaks = PC_INDEX;
iFilter = 1;
strike = 0;
% updated = abs(uni_d);
updated = uni_d;
muap = {};
while isvalid(fig)
    if iFilter >= MAX_MUAPS
        iFilter = iFilter - 1;
        break;
    end
    % [muap{iFilter}.B, muap{iFilter}.fitinfo] = multi_LASSO(snips, abs(res(idx)), 'Lambda', LAMBDA); 
    [muap{iFilter}.B, muap{iFilter}.fitinfo] = multi_LASSO(snips, res(idx), 'Lambda', LAMBDA); 
    muap{iFilter}.pc = curPC_Peaks; 
    muap{iFilter}.coeff = coeff(:,curPC_Peaks);
    muap{iFilter}.train = apply_pc_betas(uni_d, zeros(size(muap{iFilter}.B,1)-1,1), muap{iFilter}.B, muap{iFilter}.coeff); %#ok<*SAGROW>
    
    
    % recon = abs(muapTrain) * (coeff(:,curPC_Peaks)');
    % updated_pre = abs(updated) - abs(recon);
    % updated_pre = updated - recon;
    updated_pre = muap{iFilter}.train;
    mse = mean(sum((updated_pre).^2,2),1);
    if mse < 10
        [muap{iFilter}.pks, muap{iFilter}.locs] = findpeaks(muap{iFilter}.train, 'MinPeakHeight', median(abs(muap{iFilter}.train)).*6.5);
        % m = mode(muap{iFilter}.pks);
        % d = median(abs(muap{iFilter}.pks - median(muap{iFilter}.pks)));
        % muap{iFilter}.mask = (muap{iFilter}.pks > (m - d/2)) & (muap{iFilter}.pks <= (m + d/2));
        
        [sorted_pks, sorted_idx] = sort(muap{iFilter}.pks,'descend');
        muap{iFilter}.mask = false(size(muap{iFilter}.pks));
        muap{iFilter}.mask(sorted_idx(1:max(round(TOP_PEAK_FRACTION*numel(sorted_idx)),MIN_PEAKS_RETAINED))) = true;
        break;
    end
    if iFilter > 1
        if mse < min(h.YData)
            strike = 0;
            updated = updated_pre;
            res = muap{iFilter}.train;
            [muap{iFilter}.pks, muap{iFilter}.locs] = findpeaks(muap{iFilter}.train, 'MinPeakHeight', median(abs(muap{iFilter}.train)).*6.5);
            % m = mode(muap{iFilter}.pks);
            % d = median(abs(muap{iFilter}.pks - median(muap{iFilter}.pks)));
            % muap{iFilter}.mask = (muap{iFilter}.pks > (m - d/2)) & (muap{iFilter}.pks <= (m + d/2));
            
            [sorted_pks, sorted_idx] = sort(muap{iFilter}.pks,'descend');
            muap{iFilter}.mask = false(size(muap{iFilter}.pks));
            muap{iFilter}.mask(sorted_idx(1:max(round(TOP_PEAK_FRACTION*numel(sorted_idx)),MIN_PEAKS_RETAINED))) = true;
            set(h,'YData',[h.YData, mse],'MarkerIndices',h.MarkerIndices + 1,'XData',[h.XData, h.XData(end)+1]);
            drawnow();
            idx = muap{iFilter}.locs(~muap{iFilter}.mask);
            [snips, idx] = scores_2_extended(abs(score(:,curPC_Peaks)), explained, idx);
            muap{iFilter}.pks = muap{iFilter}.pks(muap{iFilter}.mask);
            muap{iFilter}.locs = muap{iFilter}.locs(muap{iFilter}.mask);
            muap{iFilter}.mask = muap{iFilter}.mask(muap{iFilter}.mask);
            [muap{iFilter}.B, muap{iFilter}.fitinfo] = multi_LASSO(snips(muap{iFilter}.mask,:), res(muap{iFilter}.locs(muap{iFilter}.mask)), 'Lambda', LAMBDA);  
            muap{iFilter}.train = apply_pc_betas(uni_d, zeros(size(muap{iFilter}.B,1)-1,1), muap{iFilter}.B, coeff(:,curPC_Peaks)); %#ok<*SAGROW>
            
            iFilter = iFilter + 1;
        else
            strike = strike + 1;
            if strike < 3
                curPC_Peaks = curPC_Peaks + 1;
                [~,idx] = findpeaks(abs(score(:,curPC_Peaks)), ...
                    'MinPeakHeight', median(abs(score(:,curPC_Peaks)))*MIN_PEAK_HEIGHT, ...
                    'MinPeakDistance', MIN_PEAK_DISTANCE);

                [snips, idx] = scores_2_extended(abs(score(:,curPC_Peaks)), explained, idx);
                res = abs(score(:, curPC_Peaks));
                % score = updated_pre * coeff;
                % res = muap{iFilter}.train;
                subtitle(ax, sprintf('Spikes: PC-%d | Strikes: %d', curPC_Peaks, strike), 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
                drawnow();
            else
                subtitle(ax, sprintf('Spikes: PC-%d | Strikes: %d', curPC_Peaks, strike), 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
                drawnow();
                [muap{iFilter}.pks, muap{iFilter}.locs] = findpeaks(muap{iFilter}.train, 'MinPeakHeight', median(abs(muap{iFilter}.train)).*6.5);
                % m = mode(muap{iFilter}.pks);
                % d = median(abs(muap{iFilter}.pks - median(muap{iFilter}.pks)));
                % muap{iFilter}.mask = (muap{iFilter}.pks > (m - d/2)) & (muap{iFilter}.pks <= (m + d/2));
                
                [sorted_pks, sorted_idx] = sort(muap{iFilter}.pks,'descend');
                muap{iFilter}.mask = false(size(muap{iFilter}.pks));
                muap{iFilter}.mask(sorted_idx(1:max(round(TOP_PEAK_FRACTION*numel(sorted_idx)),MIN_PEAKS_RETAINED))) = true;
                break;
            end
        end
    else
        [muap{iFilter}.pks, muap{iFilter}.locs] = findpeaks(muap{iFilter}.train, 'MinPeakHeight', median(abs(muap{iFilter}.train)).*6.5);
        % m = mode(muap{iFilter}.pks);
        % d = median(abs(muap{iFilter}.pks - median(muap{iFilter}.pks)));
        % muap{iFilter}.mask = (muap{iFilter}.pks > (m - d/2)) & (muap{iFilter}.pks <= (m + d/2));
        
        [sorted_pks, sorted_idx] = sort(muap{iFilter}.pks,'descend');
        muap{iFilter}.mask = false(size(muap{iFilter}.pks));
        muap{iFilter}.mask(sorted_idx(1:max(round(TOP_PEAK_FRACTION*numel(sorted_idx)),MIN_PEAKS_RETAINED))) = true;
        updated = updated_pre;
        res = muap{iFilter}.train;
        idx = muap{iFilter}.locs(~muap{iFilter}.mask);
        [snips, idx] = scores_2_extended(abs(score(:,curPC_Peaks)), explained, idx);
        muap{iFilter}.pks = muap{iFilter}.pks(muap{iFilter}.mask);
        muap{iFilter}.locs = muap{iFilter}.locs(muap{iFilter}.mask);
        muap{iFilter}.mask = muap{iFilter}.mask(muap{iFilter}.mask);
        set(h,'YData',[h.YData, mse],'MarkerIndices',h.MarkerIndices + 1,'XData',[h.XData, h.XData(end)+1]);
        drawnow();
        [muap{iFilter}.B, muap{iFilter}.fitinfo] = multi_LASSO(snips(muap{iFilter}.mask,:), res(muap{iFilter}.locs(muap{iFilter}.mask)), 'Lambda', LAMBDA);  
        muap{iFilter}.train = apply_pc_betas(uni_d, zeros(size(muap{iFilter}.B,1)-1,1), muap{iFilter}.B, coeff(:,curPC_Peaks)); %#ok<*SAGROW>
    
        iFilter = iFilter + 1;
    end
    % 
    % [~,idx] = findpeaks(abs(score(:,curPC_Peaks)), ...
    %     'MinPeakHeight', median(abs(score(:,curPC_Peaks)))*MIN_PEAK_HEIGHT, ...
    %     'MinPeakDistance', MIN_PEAK_DISTANCE);

    
    % [snips, idx] = scores_2_extended(abs(score(:,curPC_Peaks)), explained, idx);
    
end

%%
fig = figure('Color','w','Name','MUAP Trains');
nRow = ceil(sqrt(numel(muap)));
nCol = ceil(numel(muap)/nRow);
L = tiledlayout(fig, nRow, nCol);
t = (0:(numel(muap{iFilter}.train)-1))/data.sample_rate;
% muap = cell(numel(Bm),1);
for iFilter = 1:numel(muap)
    % muap{iFilter}.train = apply_pc_betas(uni_d, zeros(size(muap{iFilter}.B,1)-1,1), muap{iFilter}.B, coeff(:,muap{iFilter}.pc));
    ax = nexttile(L);
    set(ax,'NextPlot','add','XColor','none','YColor','none');
    plot(ax, t, muap{iFilter}.train, 'Color','k');
    scatter(ax, t(muap{iFilter}.locs(muap{iFilter}.mask)), muap{iFilter}.pks(muap{iFilter}.mask), 'Marker', '*', 'MarkerEdgeColor', 'r');
end
linkaxes(findobj(L,'Type','axes'),'xy');