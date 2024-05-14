function [S,all_locs,explained] = uni_2_pks(uni, options)

arguments
    uni
    options.MinPeakHeight = 4.5; % x median absolute deviations of input
    options.MinPeakDistance = 8; % samples
    options.NPCs (1,1) {mustBeNumeric} = nan;
    options.Verbose (1,1) logical = true;
end

nch = size(uni,1);

i = [];
j = [];
v = [];

warning('off','signal:findpeaks:largeMinPeakHeight');
for iCh = 1:nch
    thresh = median(abs(uni(iCh,:)))*options.MinPeakHeight;
    [pks,locs] = findpeaks(abs(uni(iCh,:)), ...
        'MinPeakHeight',thresh, ...
        'MinPeakDistance',options.MinPeakDistance);
    ch = ones(numel(pks),1).*iCh;
    i = [i; ch]; %#ok<*AGROW> 
    j = [j; locs'];
    v = [v; pks'];
end
warning('on','signal:findpeaks:largeMinPeakHeight');
S = sparse(i, j, v);

if nargout < 2
    return;
end

if isnan(options.NPCs)
    all_locs = cell(1,nch);
    for ii = 1:nch
        all_locs{ii} = find(S(ii,:));
    end
    explained = 100;
else
    warning('off','stats:pca:ColRankDefX');
    [eigenvector, ~, ~, ~, explained] = pca(uni);
    warning('on','stats:pca:ColRankDefX');
    all_locs = cell(1,options.NPCs);
    for ii = 1:options.NPCs
        thresh = median(abs(eigenvector(:,ii)))*options.MinPeakHeight;
        [~, all_locs{ii}] = findpeaks(eigenvector(:,ii), ...
            'MinPeakHeight',thresh, ...
            'MinPeakDistance',options.MinPeakDistance);
    end
    if options.Verbose
        fprintf(1,'Used IPTs from %d PCs explaining %d%% of data.\n', options.NPCs, round(sum(explained(1:options.NPCs))));
    end
    explained = sum(explained(1:options.NPCs));
end

end