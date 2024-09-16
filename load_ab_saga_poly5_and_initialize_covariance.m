function [out,saga] = load_ab_saga_poly5_and_initialize_covariance(SUBJ, YYYY, MM, DD, BLOCK, options)
%LOAD_AB_SAGA_POLY5_AND_INITIALIZE_COVARIANCE  Loads poly5 files for SAGAA/B and then uses TRIGGERS data to parse classifier labels and train a bagged trees classification model for discrete gesture recognition.
%
% Syntax:
%   out = load_ab_saga_poly5_and_initialize_covariance(SUBJ, YYYY, MM, DD, BLOCK, 'Name', value, ...);
%   
% Inputs:
%   SUBJ - Name of subject
%   YYYY - Year (numeric)
%   MM - Month (numeric)
%   DD - Day (numeric)
%   BLOCK - Block indexing which recording this was (numeric)
%   
% Options:
%       'ApplyCAR' - Logical indicating whether to apply Common Average Referencing.
%       'ApplyFilter' - Logical indicating whether to apply high-pass filtering.
%       'HighpassFilterCutoff' - High-pass filter cutoff frequency.
%       'ApplyGridInterpolation' - Logical indicating whether to interpolate data on a grid.
%       'ApplySpatialLaplacian' - Logical indicating whether to apply spatial Laplacian filtering.
%       'TriggerChannelIndicator' - Name indicator for the trigger channel.
%       'RestBit' - Bit used to indicate REST in neutral position between each gesture. Also used in determining the bitmask to apply to trigger channel data for pulse detection.
%       'IsTextile64' - Logical indicating if data arrangement follows a 64-electrode textile configuration.
%       'TextileTo8x8GridMapping' - Mapping of electrodes from a textile configuration to a standard 8x8 grid.
%       'InputRoot' - Root directory for input files if not included in poly5_files paths.

arguments
    SUBJ
    YYYY
    MM
    DD
    BLOCK
    options.HighpassFilterCutoff (1,1) double = 100;
    options.ManualMask = [];
    options.GammaPrior = [];
    options.Enable = struct('A', true, 'B', true);
    options.ATag = "A";
    options.BTag = "B";
    options.InputRoot = "C:/Data/TMSi";
    options.MaskBit = 1;
    options.FileID string {mustBeTextScalar} = "Calibrations";
    options.IsTextile64 (1,1) logical = true;
    options.SampleRate (1,1) double {mustBeMember(options.SampleRate, [2000, 4000])} = 4000;
    options.PlotIFR = true;
    options.PlotWhitening = true;
    options.PlotComparisons = false;
    options.PlotTemplates = false;
    options.MaskTimesWhitening = [4.25 4.35];  % Seconds
    options.MaskTimesComparisons = [4, 6]; % Seconds
    options.ThresholdDeviations = 4.5; % Number of median absolute deviations for threshold-setting.
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
    options.ExtensionPeriod = 0.0075; % seconds

    % For threshold-crossings on HPF data, set the microvolts for
    % threshold-detection of spikes here. This number is used to compute the
    % fraction of variance we need to explain with the whitened data principal
    % components, which are ultimately what we use to recover the steering
    % vectors that give us the MUAPs.
    options.TypicalPeakThresholdMicrovolts = 75;
    options.Verbose (1,1) logical = true;
end

% Auto-derived filenames
SESSION = sprintf('%04d_%02d_%02d', YYYY, MM, DD);
TANK = sprintf('%s_%s', SUBJ, SESSION);
EXPERIMENT = sprintf('%s_%d',TANK, BLOCK);
INPUT_ROOT = sprintf("%s/%s/%s",options.InputRoot, SUBJ, TANK);
OUTPUT_ROOT = sprintf("%s/%s",INPUT_ROOT, EXPERIMENT);
if exist(OUTPUT_ROOT,'dir')==0
    mkdir(OUTPUT_ROOT);
end
MY_CALIBRATION_MATFILE = sprintf("%s/%s_%s_%d.mat", INPUT_ROOT, TANK, options.FileID, BLOCK);

A_file_expr = sprintf("%s/%s_%s*_%d.poly5", INPUT_ROOT, TANK, options.ATag, BLOCK);
A = dir(A_file_expr);
if isempty(A)
    error("No file matches expression: %s", A_file_expr);
elseif numel(A) > 1
    error("Non-specific match: multiple A blocks match file expression (%s)", A_file_expr);
end

B_file_expr = sprintf("%s/%s_%s*_%d.poly5", INPUT_ROOT, TANK, options.BTag, BLOCK);
B = dir(B_file_expr);
if isempty(B)
    error("No file matches expression: %s", B_file_expr);
elseif numel(A) > 1
    error("Non-specific match: multiple B blocks match file expression (%s)", B_file_expr);
end

saga = io.load_align_saga_data_many(...
    [string(fullfile(A.folder, A.name)); ...
     string(fullfile(B.folder, B.name))], ...
     'TriggerBitMask',2^options.MaskBit, ...
     'IsTextile64', options.IsTextile64, ...
     'TextileTo8x8GridMapping', textile_8x8_uni2grid_mapping(), ...
     'SampleRate', options.SampleRate, ...
     'ApplyCAR', false, ...
     'ApplyGridInterpolation', false, ...
     'ApplySpatialLaplacian', false, ...
     'ApplyFilter', true, ...
     'HighpassFilterCutoff', options.HighpassFilterCutoff);
[iUni, ~, iTrig] = ckc.get_saga_channel_masks(saga.channels);


extFact = options.SampleRate * options.ExtensionPeriod;
if exist(MY_CALIBRATION_MATFILE, 'file')==0
    save(MY_CALIBRATION_MATFILE, 'extFact', '-v7.3');
else
    save(MY_CALIBRATION_MATFILE, 'extFact', '-append');
end

SAGA = ["A", "B"];
out = struct();
for iSaga = 1:2
    dev = SAGA(iSaga);
    if ~options.Enable.(dev)
        continue;
    end
    if options.Verbose
        fprintf(1,'Please wait, initializing covariance for SAGA %s...\n', dev);
    end
    %% 1. Get data from single SAGA
    if isempty(options.ManualMask)
        trig_mask = bitand(saga.samples(iTrig(iSaga),:),2^options.MaskBit)==0;
    else
        trig_mask = options.ManualMask;
    end
    data = saga.samples(iUni((1:64) + (iSaga-1)*64),trig_mask);
    if isempty(options.GammaPrior)
        out.(dev).gamma = 2.5*rms(data(:)); % Get a prior for the background noise covariance.
    else
        out.(dev).gamma = options.GammaPrior;
    end
    %% 2. Extend input data and estimate sample covariance from extended array.
    edata = ckc.extend(data,extFact);
    R = (1/(size(edata,2))) * (edata * edata') + eye(size(edata,1)).*out.(dev).gamma;
    out.(dev).P = pinv(R);
    
    %% 3. Make a "whitening" per-channel projection matrix.
    Wz = zeros(64,extFact*64);
    out.(dev).windowingVector = generateSigmoid(extFact);
    for iCh = 1:64 % Basically, each channel gets a row of this projection.
        vec = (iCh-1)*extFact + (1:extFact);
        % Use a sigmoid to collapse back to the zero-lagged sample.
        Wz(iCh,vec) = out.(dev).windowingVector;
    end
    
    %% 4. From these whitened projected data, recover principal eigenvectors
    % Discard first vector (typically noise).
    %   Recover the rest of the vectors, reconstructing some fraction of the
    %   data according to our posterior background noise level estimate and our
    %   prior for what the typical peak detction microvolt amplitude should be.
    wedata = Wz * out.(dev).P * edata;
    [~,score,~,~,explained] = pca(wedata);
    % Use the RMS noise background to determine our threshold percentage for
    % how much of the data we would like to reconstruct:
    threshold_explained = 100 * cdf("Normal", ...
        options.TypicalPeakThresholdMicrovolts, 0, out.(dev).gamma);
    i_selected_eigs = 2:find(cumsum(explained)>=threshold_explained,1,'first');
    w = score(:,i_selected_eigs);
    attenuation = mag2db(explained(i_selected_eigs(1))/explained(i_selected_eigs(end)));
    s = generateSigmoid(numel(i_selected_eigs), attenuation, ...
        'SigmoidInitialValue', explained(i_selected_eigs(1)), ...
        'SigmoidShape', [-6 6]); % "Flip" the shape so low at left high at right
    out.(dev).w = w .* s;
    
    %% 5. Generate a "MUAP kernel" (1 MUAP/eigenvector).
    % This is similar to how we projected data onto each channel, except now we
    % are using the per-channel eigenvector values and multiplying those by the
    % same windowing type used before to get the kernel collapsing all time
    % values into a single time instant.
    out.(dev).W = zeros(size(w,2),extFact*64); % muap kernel
    for iW = 1:size(w,2)
        for iCh = 1:64
            vec = (iCh-1)*extFact + (1:extFact);
            out.(dev).W(iW,vec) = w(iCh,iW) * out.(dev).windowingVector;
        end
    end
    
    % We can use the filter kernel to project the MUAP pulse trains.
    IPTs = out.(dev).W * out.(dev).P * edata;
    n_muap = size(IPTs,1);
    
    %% 6. Now we are matching up the whitened vectors to "which channel is this MUAP coming from?" Using cross-correlation.
    % We will also collect our peak thresholds in this step based on whatever
    % selected number of median absolute deviations of the projected data we
    % have specified.
    rhoMax = nan(n_muap,1);
    iMax = nan(n_muap,1);
    threshold = nan(n_muap,1);
    k = 1:size(data,2);
    for iMuap = 1:n_muap
        rho = corr(IPTs(iMuap,k)', data');
        [~, iMax(iMuap)] = max(rho);
        rhoMax(iMuap) = rho(iMax(iMuap));
        threshold(iMuap) = options.ThresholdDeviations*median(abs(IPTs(iMuap,k)));
    end
    
    %% 7. On each whitened MUAP projection, now we figure out where the threshold-crossings occurred.
    MUPulses = cell(n_muap,1);
    MU_ID = cell(n_muap,1);
    for iMuap = 1:n_muap
        MUPulses{iMuap} = find(IPTs(iMuap,:)*sign(rhoMax(iMuap)) < -threshold(iMuap));
        MU_ID{iMuap} = sprintf("%s-%02d=Ch-%02d", dev, iMuap, iMax(iMuap));
    end
    
    %% 8. (Optional) If requested, plot IFRs
    if options.PlotIFR
        [b_env,a_env] = butter(3,1.5/2000,'low');
        fig = ckc.plotIDR(MUPulses,MU_ID,filtfilt(b_env,a_env,rms(data,1)),4000);
        utils.save_figure(fig,fullfile(OUTPUT_ROOT,TANK),sprintf('%s_%s_MUAP-IFRs',EXPERIMENT,dev));
    end
    
    %% 9. (Optional) Plot the whitened waveforms compared to original data
    t = k./options.SampleRate;
    if options.PlotWhitening
        
        t_mask = (t >= options.MaskTimesWhitening(1)) & (t < options.MaskTimesWhitening(2));
        delta_t = 1.1*(options.MaskTimesWhitening(2) - options.MaskTimesWhitening(1));
        X = repmat(t(t_mask)' - options.MaskTimesWhitening(1),1,64) + repelem(0:delta_t:(delta_t*7),1,8);
        fig = figure('Color','w','Units','inches','WindowState', 'maximized');
        cdata_tmp = [min(winter(64) + 0.2,1)];
        cdata_tmp = cdata_tmp(33:8:end,:);
        cdata_tmp = repelem(cdata_tmp,16,1);
        ax = axes(fig,'NextPlot','add','FontName','Tahoma', ...
            'ColorOrder', cdata_tmp, ...
            'XColor', 'none','YColor','none');
        plot(ax, X, data(:,t_mask)' + rem((1:64)-1,8).*75, ...
            'LineStyle', '-', 'LineWidth', 2.0);
        wedata_tmp = 50.*wedata(:,k(t_mask))';
        h = plot(ax, X,  wedata_tmp + rem((1:64)-1,8).*75,  ...
            'LineStyle', '-', 'LineWidth', 1.5, 'Color', 'k', ...
            'Marker', '*', 'MarkerEdgeColor', 'r', 'MarkerFaceColor', 'r', ...
            'MarkerIndices', [], 'MarkerSize', 24);
        all_locs = [];
        all_ch = [];
        warning('off','signal:findpeaks:largeMinPeakHeight');
        for iCh = 1:64
            [~,locs] = findpeaks(-wedata_tmp(:,iCh),'MinPeakHeight',20);
            all_locs = [all_locs; locs]; %#ok<*AGROW>
            all_ch = [all_ch; ones(numel(locs),1).*iCh];
        end
        warning('on','signal:findpeaks:largeMinPeakHeight');
        [u_locs,iA,iC] = unique(all_locs);
        u_ch = all_ch(iA);
        i_bad = setdiff(iC, unique(iC));
        i_remove = ismember(iC, i_bad);
        u_locs(i_remove) = [];
        u_ch(i_remove) = [];
    
        todo_ch = unique(u_ch);
        for iCh = 1:numel(todo_ch)
            h(todo_ch(iCh)).MarkerIndices = u_locs(u_ch == todo_ch(iCh));
        end
    
        plot.add_scale_bar(ax, -0.050, -25, -0.025, 25, 'XUnits', 'ms', 'XLabelScaleFactor', 1e3);
        title(ax, 'Whitening Overlay', 'FontName',"Tahoma");
        subtitle(ax, sprintf("( %d / %d locs unique )", numel(u_locs), numel(all_locs)));
        utils.save_figure(fig, OUTPUT_ROOT, sprintf('%s_%s_Whitening', EXPERIMENT,dev));
    end
    
    %% 10. Get the MUAP template waveforms (and whitened templates)
    MUAPs = cell(n_muap,1);
    WMUAPs = cell(n_muap,1);
    n_samples = size(data,2); 
    
    vec = (-extFact/2:(extFact/2-1))';
    for ii = 1:n_muap
        iMuap = MUPulses{ii}-extFact/2;
        i_remove = (iMuap < 1) | (iMuap > (n_samples - extFact));
        iMuap(i_remove) = [];
        MUPulses{ii}(i_remove) = [];

        if isempty(MUPulses{ii})
            continue;
        end
        MUAPs{ii} = reshape(edata(:,iMuap),extFact,64,[]);
        mask = MUPulses{ii} + vec;
        mask(any(mask<1 | mask>size(data,2),2),:) = [];
        for iCh = 1:64
            tmp = wedata(iCh,:);
            WMUAPs{ii}(:,iCh,:) = tmp(mask);
        end
    end
    
    %% 11. Save everything to data files.
    MY_RESULTS_MATFILE = fullfile(OUTPUT_ROOT,sprintf('%s_%s_Results.mat',EXPERIMENT, SAGA(iSaga)));
    out.(dev).threshold = -threshold;
    save(MY_RESULTS_MATFILE, ...
        'MUPulses', 'MU_ID', 'IPTs', ...
        'MUAPs', 'WMUAPs', ...
        'rhoMax','threshold','iMax','-v7.3');
    
    %% 12. (Optional) Plot the alignments of IPTs with correlated data channels
    if options.PlotComparisons
        comparisons_output_folder = fullfile(OUTPUT_ROOT,'Comparisons');
        if exist(comparisons_output_folder,'dir')
            rmdir(comparisons_output_folder, 's');
        end
        t_mask = (t >= options.MaskTimesComparisons(1)) & (t < options.MaskTimesComparisons(2));
        for iMuap = 1:n_muap
            pt = IPTs(iMuap,:) < threshold(iMuap);
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
    if options.PlotTemplates
        X = repmat(((-extFact/2):((extFact/2)-1))'./4,1,64) + repelem((0:(extFact/4):((extFact/4)*7)),1,8);
        templates_output_folder = fullfile(OUTPUT_ROOT,'Templates');
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
                plot(ax, X(:,iMax(ii)), squeeze(WMUAPs{ii}(:,iMax(ii),1:min(5,size(WMUAPs{ii},3)))) + rem(iMax(ii)-1,8).*25, ...
                    'Color', [0.65 0.65 0.65], 'LineWidth', 1.25);
                h = plot(ax, X, mean(WMUAPs{ii},3).*25+repmat(0:25:(7*25),1,8), ...
                    'Color','k','LineStyle', ':', 'LineWidth', 1.0);
                set(h(iMax(ii)),'LineWidth', 3.0, 'LineStyle', '-','Color',[1.0 0.1 0.1]);
                title(ax,sprintf('Whitened MUAP-%02d',ii),'Color','k','FontName','Tahoma');
                utils.save_figure(fig, templates_output_folder, sprintf('MUAP-%02d', ii));
            end
        end
    end
    
    
end

f = fieldnames(out);
for iF = 1:numel(f)
    eval(sprintf('%s = out.%s;',f{iF}, f{iF}));
    save(MY_CALIBRATION_MATFILE, f{iF}, '-append');
end

if options.Verbose
    fprintf(1,'Saved file to %s.\n', MY_CALIBRATION_MATFILE);
end

end