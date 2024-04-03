function [S, uni_d] = uni_2_pks(uni, options)

arguments
    uni
    options.MinPeakHeight = 15; % microvolts
    options.MinPeakDistance = 8; % samples
end

uni_d = uni - [zeros(64,1), uni(:,(1:(end-1)))];
uni_d(:,1) = zeros(64,1);

i = [];
j = [];
v = [];

for iCh = 1:64
    [pks,locs] = findpeaks(abs(uni_d(iCh,:)), ...
        'MinPeakHeight',options.MinPeakHeight, ...
        'MinPeakDistance',options.MinPeakDistance);
    ch = ones(numel(pks),1).*iCh;
    i = [i; ch]; %#ok<*AGROW> 
    j = [j; locs'];
    v = [v; pks'];
end

S = sparse(i, j, v);
uni_d = uni_d(:,1:size(S,2));

end