function S = uni_2_pks(uni, options)

arguments
    uni
    options.MinPeakHeight = 4.5; % x median absolute deviations of input
    options.MinPeakDistance = 8; % samples
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

end