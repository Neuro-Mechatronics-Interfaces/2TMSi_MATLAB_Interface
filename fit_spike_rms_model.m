function [beta0, beta, snips, clus, ratio, nspikes, template] = fit_spike_rms_model(Y, Xe, Xs, channels, options)
%FIT_SPIKE_RMS_MODEL  Fit polynomial model with iterative channel selection
%
% Syntax:
%   [beta0, beta] = fit_spike_rms_model(Y, Xe, Xs channels);
%
% Inputs:
%   Y - [1 x nSamples] Categories of gesture to fit (from categorical
%                           vector, where 1 is always REST)
%   Xs - [128 x nSamples] Highpass filtered sEMG
%   Xe - [128 x nSamples] Envelope of highpass filtered power from sEMG
%   channels - [1 x nChannels] List of viable channels for regression.
%
% Output:
%   beta0 - [nRows x 1] Intercept coefficient
%   beta  - [nRows x 128] Least-squares optimal regression coefficients
%
% See also: Contents

arguments
    Y double
    Xe (128,:) double  % Envelope
    Xs (128,:) double   % Spikes
    channels {mustBeInteger, mustBeInRange(channels, 1, 128)} = 1:128;
    options.SpikeExtension = -24:24;
    options.KClus = 5;
    options.SpikeCountThreshold = 30;
end
u = unique(Y);
u = setdiff(u,1);

beta = zeros(numel(u),128);
beta0 = zeros(numel(u),1);
nSamples = size(Xs,2);
E = numel(options.SpikeExtension);
snips = cell(numel(u),1);
ratio = cell(size(snips));
nspikes = cell(size(snips));
clus = cell(size(snips));
template = cell(size(snips));
ch_grid = reshape(1:128,8,16);
for ii = 1:numel(u)
    [~,iMax] = max(rms(Xe(channels,Y==u(ii)),2),[],1);
    z = zscore(Xs(channels(iMax),:));
    [~,locs] = findpeaks(z,'MinPeakHeight',4.5,'MinPeakDistance',6);
    mask = locs' + options.SpikeExtension;
    iRemove = any((mask<1) | (mask > nSamples),2);
    mask(iRemove,:) = [];
    locs(iRemove,:) = [];
    snips{ii} = nan(size(mask,1),size(mask,2).*numel(channels));
    for iCh = 1:numel(channels)
        ch = channels(iCh);
        xs = Xs(ch,:);
        idx = (1:E) + (iCh-1)*E;
        snips{ii}(:,idx) = xs(mask);
    end
    clus{ii} = kmeans(snips{ii},options.KClus);
    ratio{ii} = zeros(options.KClus,1);
    nspikes{ii} = nan(options.KClus,1);
    for ik = 1:options.KClus
        nspikes{ii}(ik) = nnz(clus{ii}==ik);
        if nspikes{ii}(ik) > options.SpikeCountThreshold
            ratio{ii}(ik) = nnz(Y(locs(clus{ii}==ik))==u(ii))/nspikes{ii}(ik);
        end
    end
    [~,iBest] = max(ratio{ii});
    template{ii} = mean(snips{ii}(clus{ii}==iBest,:),1);
    [iRow,iCol] = ind2sub([8,16],channels(iMax));
    for rr = -1:1
        for cc = -1:1
            if ((iRow+rr) > 0) && ((iRow+rr)<=8) && ((iCol+cc) > 0) && ((iCol+cc)<=16)
                ind = sub2ind([8,16],iRow+rr,iCol+cc);
                ch = ch_grid(ind);
                if ismember(ch,channels)
                    iCh = find(channels==ch,1,'first');
                    idx = (1:E) + (iCh-1)*E;
                    beta(ii,ch) = max(template{ii}(idx)) - min(template{ii}(idx));
                end
            end
        end
    end
    beta(ii,:) = beta(ii,:)./sum(beta(ii,:),2);
    beta0(ii) = -median(beta(ii,:)*Xe);
end

end
