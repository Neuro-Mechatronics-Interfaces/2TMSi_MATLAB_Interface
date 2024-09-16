%EXAMPLE_INITIALIZE_COVARIANCE  Example illustrating how to initialize covariance matrix with pseudo-inverse projection and weighting vectors.
clear;
close all force;
clc;

SUBJ = 'Max';
SESSION = '2024_03_30';
ARRAY = "B";
BLOCK = 22;

% Set input and output folders
INPUT_ROOT = pwd;
OUTPUT_ROOT = 'C:/Data/Decompositions/MUAPs';

% Set flags for whether to plot stuff
PLOT_IFR = true;
PLOT_WHITENING = true;
T_MASK_WHITENING_START = 14.25;
PLOT_COMPARISONS = true;
T_MASK_COMPARISONS = [14, 16];
PLOT_TEMPLATES = true;

% Auto-derived filenames
TANK = sprintf('%s_%s', SUBJ, SESSION);
EXPERIMENT = sprintf('%s_%s_%d',TANK, ARRAY, BLOCK);
MY_INPUT_POLY5 = fullfile(INPUT_ROOT,sprintf('%s.poly5',EXPERIMENT));
MY_CALIBRATION_MATFILE = fullfile(INPUT_ROOT, sprintf('%s_PInv.mat', EXPERIMENT));
MY_RESULTS_MATFILE = fullfile(OUTPUT_ROOT,TANK,sprintf('%s_Results.mat',EXPERIMENT));

% Number of median absolute deviations for threshold-setting.
%   This is used for plotting and getting the template waveforms, primarily
THRESHOLD_DEVIATIONS = 4.5;

% Set this value to determine the extension factor based on acquisition
% sample rate. Setting this value very high can give a better decomposition
% for example in sustained isometric contractions especially; however, for
% online use case, this number directly relates to how "delayed" processing
% related to a given sample actually is. In practice, TMSi can pull in
% batches of around 50-100 samples at 4kHz, which translates to roughly
% 12.5-25 milliseconds per loop cycle. That means if you set this number
% UNDER that value, you should not incur additional processing delays
% except for any added latency related to the larger matrix multiply
% operations and associated processing speed of those add/multiply
% operations.
EXTENSION_PERIOD = 0.0125; % seconds
T_MASK_WHITENING = [T_MASK_WHITENING_START, T_MASK_WHITENING_START + 8*EXTENSION_PERIOD];

% For threshold-crossings on HPF data, set the microvolts for
% threshold-detection of spikes here. This number is used to compute the
% fraction of variance we need to explain with the whitened data principal
% components, which are ultimately what we use to recover the steering
% vectors that give us the MUAPs.
TYPICAL_PEAK_THRESHOLD_MICROVOLTS = 75;

%% 1. Load and filter input data.
x = TMSiSAGA.Poly5.read(MY_INPUT_POLY5);
[b,a] = butter(3,100/2000,'high');
data = filter(b,a,x.samples(2:65,:)',[],1)'; % Make sure it is using UNI channels
data(:,1:100) = 0;
n_samples = size(data,2);
k = 1:n_samples;

extFact = EXTENSION_PERIOD * x.sample_rate;
gamma = 2.5*rms(data(:)); % Get a prior for the background noise covariance.

%% 2. Extend input data and estimate sample covariance from extended array.
edata = fast_extend(data,extFact);
R = (1/(size(edata,2))) * (edata * edata') + eye(size(edata,1)).*gamma;
P = pinv(R);

%% 3. Make a "whitening" per-channel projection matrix.
Wz = zeros(64,extFact*64);
windowingVector = generateSigmoid(extFact);
for iCh = 1:64 % Basically, each channel gets a row of this projection.
    vec = (iCh-1)*extFact + (1:extFact);
    % Use a sigmoid to collapse back to the zero-lagged sample.
    Wz(iCh,vec) = windowingVector;
end

%% 4. From these whitened projected data, recover principal eigenvectors
% Discard first vector (typically noise).
%   Recover the rest of the vectors, reconstructing some fraction of the
%   data according to our posterior background noise level estimate and our
%   prior for what the typical peak detction microvolt amplitude should be.
wedata = Wz * P * edata;
[coef,score,latent,~,explained] = pca(edata');
% Use the RMS noise background to determine our threshold percentage for
% how much of the data we would like to reconstruct:
threshold_explained = 100 * cdf("Normal", ...
    TYPICAL_PEAK_THRESHOLD_MICROVOLTS, 0, gamma);
i_selected_eigs = 2:find(cumsum(explained)>=threshold_explained,1,'first');

% threshold_explained = explained(17); % Testing only- if you whiten before
% % pca, the explained fraction from each PC is tiny (obviously) so
% % therefore you will get too many selected eigenvectors...
% i_selected_eigs = 2:17;
w = coef(:,i_selected_eigs);
n_muap = size(w,2);
% attenuation = mag2db(explained(i_selected_eigs(1))/explained(i_selected_eigs(end)));
% s = generateSigmoid(numel(i_selected_eigs), attenuation, ...
%     'SigmoidInitialValue', explained(i_selected_eigs(1)), ...
%     'SigmoidShape', [-6 6]); % "Flip" the shape so low at left high at right
% w = w .* s;
save(MY_CALIBRATION_MATFILE, 'P', 'gamma', 'extFact', 'threshold_explained', '-v7.3');

%% 5. Generate a "MUAP kernel" (1 MUAP/eigenvector).
% This is similar to how we projected data onto each channel, except now we
% are using the per-channel eigenvector values and multiplying those by the
% same windowing type used before to get the kernel collapsing all time
% values into a single time instant.

% W = zeros(size(w,2),extFact*64); % muap kernel
% for iW = 1:size(w,2)
%     for iCh = 1:64
%         vec = (iCh-1)*extFact + (1:extFact);
%         W(iW,vec) = w(iCh,iW) * windowingVector;
%     end
% end

W = zeros(64,extFact*64,n_muap); % muap kernel
IPTs = zeros(n_muap, n_samples);
for iMuap = 1:n_muap
    for iCh = 1:64
        vec = (iCh-1)*extFact + (1:extFact);
        W(iCh,vec,iMuap) = w(vec,iMuap);
    end
    % IPTs(iMuap,:) = latent(iMuap) * w(:,iMuap)' * P * edata(:,k);
    IPTs(iMuap,:) = w(:,iMuap)' * edata(:,k);
end

% We can use the filter kernel to project the MUAP pulse trains.
% IPTs = W * P * edata;

%% 6. Now we are matching up the whitened vectors to "which channel is this MUAP coming from?" Using cross-correlation.
% We will also collect our peak thresholds in this step based on whatever
% selected number of median absolute deviations of the projected data we
% have specified.
rhoMax = nan(n_muap,1);
iMax = nan(n_muap,1);
threshold = nan(n_muap,1);
for iMuap = 1:n_muap
    rho = corr(IPTs(iMuap,k)', data');
    [~, iMax(iMuap)] = max(rho);
    rhoMax(iMuap) = rho(iMax(iMuap));
    threshold(iMuap) = THRESHOLD_DEVIATIONS*median(abs(IPTs(iMuap,k)));
end

%% 7. On each whitened MUAP projection, now we figure out where the threshold-crossings occurred.
MUPulses = cell(n_muap,1);
MU_ID = cell(n_muap,1);
for iMuap = 1:n_muap
    [~,MUPulses{iMuap}] = findpeaks(-1*IPTs(iMuap,:), ...
        'MinPeakHeight',threshold(iMuap),...
        'MinPeakDistance', extFact/2);
    MU_ID{iMuap} = sprintf("MUAP-%02d=Ch-%02d", iMuap, iMax(iMuap));
end

%% 8. (Optional) If requested, plot IFRs
if PLOT_IFR
    [b_env,a_env] = butter(3,1.5/2000,'low');
    fig = ckc.plotIDR(MUPulses,MU_ID,filtfilt(b_env,a_env,rms(data,1)),4000);
    utils.save_figure(fig,fullfile(OUTPUT_ROOT,TANK,EXPERIMENT),sprintf('%s_MUAP-IFRs',EXPERIMENT));
end

%% 9. (Optional) Plot the whitened waveforms compared to original data
t = k./4000;
if PLOT_WHITENING
    t_mask = find((t >= T_MASK_WHITENING(1)) & (t < T_MASK_WHITENING(2)));
    for iMuap = 1:n_muap
        delta_t = 1.1*(T_MASK_WHITENING(2) - T_MASK_WHITENING(1));
        X = repmat(t(t_mask)' - T_MASK_WHITENING(1),1,64) + repelem(0:delta_t:(delta_t*7),1,8);
        fig = figure('Color','w','Units','inches','WindowState', 'maximized');
        L = tiledlayout(fig,5,1);
        cdata_tmp = [min(winter(64) + 0.2,1)];
        cdata_tmp = cdata_tmp(33:8:end,:);
        cdata_tmp = repelem(cdata_tmp,16,1);
        ax = nexttile(L,1,[4 1]);
        set(ax,'NextPlot','add','FontName','Tahoma', ...
            'ColorOrder', cdata_tmp, ...
            'XColor', 'none','YColor','none');
        plot(ax, X, data(:,t_mask)' + rem((1:64)-1,8).*75, ...
            'LineStyle', '-', 'LineWidth', 2.0);
        muapdata = W(:,:,iMuap) * edata(:,k(t_mask));
        pkIndices = MUPulses{iMuap}(MUPulses{iMuap} >= t_mask(1) & MUPulses{iMuap} < t_mask(end))-t_mask(1)+1;
        h = plot(ax, X,  muapdata' + rem((1:64)-1,8).*75,  ...
            'LineStyle', '-', 'LineWidth', 1.5, 'Color', [0.65 0.65 0.65], ...
            'Marker', '*', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', ...
            'MarkerIndices', [], 'MarkerSize', 12);
        set(h(iMax(iMuap)),'MarkerIndices',pkIndices);
        title(L, sprintf('MUAP-%02d',iMuap), 'FontName',"Tahoma");
        title(ax, 'Projections By Channel', 'FontName','Tahoma','Color',[0.65 0.65 0.65]);
        plot.add_scale_bar(ax, -0.050, -25, -0.025, 25, 'XUnits', 'ms', 'XLabelScaleFactor', 1e3);
        
        % wedata_tmp = 50.*wedata(:,k(t_mask))';
        % h = plot(ax, X,  wedata_tmp + rem((1:64)-1,8).*75,  ...
        %     'LineStyle', '-', 'LineWidth', 1.5, 'Color', 'k', ...
        %     'Marker', '*', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', ...
        %     'MarkerIndices', [], 'MarkerSize', 24);
        % all_locs = [];
        % all_ch = [];
        % warning('off','signal:findpeaks:largeMinPeakHeight');
        % for iCh = 1:64
        %     [~,locs] = findpeaks(-wedata_tmp(:,iCh),'MinPeakHeight',20);
        %     all_locs = [all_locs; locs]; %#ok<*AGROW>
        %     all_ch = [all_ch; ones(numel(locs),1).*iCh];
        % end
        % warning('on','signal:findpeaks:largeMinPeakHeight');
        % [u_locs,iA,iC] = unique(all_locs);
        % u_ch = all_ch(iA);
        % i_bad = setdiff(iC, unique(iC));
        % i_remove = ismember(iC, i_bad);
        % u_locs(i_remove) = [];
        % u_ch(i_remove) = [];
        % 
        % todo_ch = unique(u_ch);
        % for iCh = 1:numel(todo_ch)
        %     h(todo_ch(iCh)).MarkerIndices = u_locs(u_ch == todo_ch(iCh));
        % end
        % title(ax, 'Whitening Overlay', 'FontName',"Tahoma");
        % subtitle(ax, sprintf("( %d / %d locs unique )", numel(u_locs), numel(all_locs)));
        % plot.add_scale_bar(ax, -0.050, -25, -0.025, 25, 'XUnits', 'ms', 'XLabelScaleFactor', 1e3);
        
        ax = nexttile(L,5,[1 1]);
        set(ax,'NextPlot','add','FontName','Tahoma', ...
            'XColor', 'k','YColor','k','XLim',T_MASK_WHITENING);
        plot(ax, t(t_mask), IPTs(iMuap,t_mask), 'Color', 'k', 'LineWidth', 2, ...
            'Marker', '*', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', ...
            'MarkerIndices', pkIndices, 'MarkerSize', 12);
        yline(ax,-threshold(iMuap),'r--','Label','Threshold');
        xlabel(ax, 'Time (s)', 'FontName','Tahoma','Color','k');
        ylabel(ax, 'IPT (\muV)', 'FontName','Tahoma','Color','k');
        title(ax, '\SigmaOverlays', 'FontName','Tahoma','Color','k','FontWeight','bold');
        yl = [min(-threshold(iMuap)*1.25,ax.YLim(1)), max(ax.YLim(2),threshold(iMuap).*1.25)];
        set(ax,'YLim',yl);
        utils.save_figure(fig, fullfile(OUTPUT_ROOT,TANK,EXPERIMENT,'Whitening'), sprintf('%s_MUAP-%02d_Whitening', EXPERIMENT, iMuap));
    end
end

%% 10. Get the MUAP template waveforms (and whitened templates)
MUAPs = cell(n_muap,1);
WMUAPs = cell(n_muap,1);

vec = (-extFact/2:(extFact/2-1))';
for ii = 1:n_muap
    MUAPs{ii} = reshape(edata(:,MUPulses{ii}-extFact/2),extFact,64,[]);
    mask = MUPulses{ii} + vec;
    mask(any(mask<1 | mask>size(data,2),2),:) = [];
    muapdata = W(:,:,ii) * P * edata;
    for iCh = 1:64
        tmp = muapdata(iCh,:);
        WMUAPs{ii}(:,iCh,:) = tmp(mask);
    end

end

%% 11. Save everything to data files.
threshold = -threshold;
save(MY_CALIBRATION_MATFILE, 'w', 'W', 'threshold', '-append');
save(MY_RESULTS_MATFILE, ...
    'MUPulses', 'MU_ID', 'IPTs', ...
    'MUAPs', 'WMUAPs', ...
    'rhoMax','threshold','iMax','-v7.3');

%% 12. (Optional) Plot the alignments of IPTs with correlated data channels
if PLOT_COMPARISONS
    comparisons_output_folder = fullfile(OUTPUT_ROOT,TANK,EXPERIMENT,'Comparisons');
    if exist(comparisons_output_folder,'dir')
        rmdir(comparisons_output_folder, 's');
    end
    t_mask = (t >= T_MASK_COMPARISONS(1)) & (t < T_MASK_COMPARISONS(2));
    for iMuap = 1:n_muap
        pt = (IPTs(iMuap,:) < threshold(iMuap)) - 0.5;
        if nnz(pt) < 10
            continue;
        end

        fig = figure('Color','w','Units','inches','Position',[2 2 8 5]);
        ax = axes(fig,'NextPlot','add','FontName','Tahoma', ...
            'ColorOrder', [0 0 0; 1.0 0.1 0.1]);
        yyaxis(ax,'left');
        plot(ax, t(t_mask),data(iMax(iMuap),t_mask), ...
            'LineWidth', 1.5, ...
            'Color', [0 0 0]);
        plot(ax, t(t_mask),IPTs(iMuap,k(t_mask)), ...
            'Color', [0.65 0.65 0.65], ...
            'LineStyle', ':', ...
            'LineWidth',0.75);
        yyaxis(ax,'right');
        plot(ax,t(t_mask),pt(k(t_mask)), ...
            'Color', [1.0 0.1 0.1], ...
            'LineStyle', '-', ...
            'LineWidth',1.5);
        xlabel(ax,'Time (s)', 'FontName','Tahoma','Color','k');
        title(ax,sprintf("Z_{%d}=Ch_{%02d}",iMuap,iMax(iMuap)));
        subtitle(ax,sprintf('\\rho=%.2f',rhoMax(iMuap)));
        utils.save_figure(fig,comparisons_output_folder,sprintf('MUAP-%02d_Ch-%02d_Comparison', iMuap, iMax(iMuap)));
    end
end

%% 13. (Optional) Plot the template waveforms (and "whitened" counterparts)
if PLOT_TEMPLATES
    X = repmat(((-extFact/2):((extFact/2)-1))'./4,1,64) + repelem((0:(extFact/4):((extFact/4)*7)),1,8);
    templates_output_folder = fullfile(OUTPUT_ROOT,TANK,EXPERIMENT,'Templates');
    if exist(templates_output_folder, 'dir')~=0
        rmdir(templates_output_folder, 's');
    end
    for ii = 1:n_muap
        if (size(WMUAPs{ii},3) > 1) && (size(WMUAPs{ii},1)==extFact)
            fig = figure('Color','w',"Name",'MUAP Templates', ...
                'Units','inches','Position',[2 2 8 5]);
            L = tiledlayout(fig,1,2);
            ax = nexttile(L);
            set(ax,'NextPlot','add');
            plot(ax, X(:,iMax(ii)), squeeze(MUAPs{ii}(:,iMax(ii),1:min(5,size(MUAPs{ii},3)))) + rem(iMax(ii)-1,8).*25, ...
                'Color', [0.65 0.65 0.65], 'LineWidth', 1.25);
            h = plot(ax, X, mean(MUAPs{ii},3)+repmat(0:25:(7*25),1,8), ...
                'Color','k', 'LineStyle', ':', 'LineWidth', 1.0);
            set(h(iMax(ii)),'LineWidth', 3.0, 'LineStyle', '-','Color',[1.0 0.1 0.1]);
            title(ax,sprintf('MUAP-%02d',ii),'Color','k','FontName','Tahoma');

            ax = nexttile(L);
            set(ax,'NextPlot','add');
            plot(ax, X(:,iMax(ii)), squeeze(WMUAPs{ii}(:,iMax(ii),1:min(35,size(WMUAPs{ii},3)))) + rem(iMax(ii)-1,8).*25, ...
                'Color', [0.65 0.65 0.65], 'LineWidth', 1.25);
            h = plot(ax, X, mean(WMUAPs{ii},3).*25+repmat(0:25:(7*25),1,8), ...
                'Color','k','LineStyle', ':', 'LineWidth', 1.0);
            set(h(iMax(ii)),'LineWidth', 3.0, 'LineStyle', '-','Color',[1.0 0.1 0.1]);
            title(ax,sprintf('Whitened MUAP-%02d',ii),'Color','k','FontName','Tahoma');
            utils.save_figure(fig, templates_output_folder, sprintf('MUAP-%02d', ii));
        end
    end
end