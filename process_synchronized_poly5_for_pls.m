function [X,Y,bad_ch] = process_synchronized_poly5_for_pls(x, bad_ch)

fs = x.sample_rate;
[b_hpf,a_hpf] = butter(3,100/(fs/2),'high');
[b_env,a_env] = butter(1,1.5/(fs/2),'low');

[iUni,~,iTrig] = get_saga_channel_masks(x.channels);
mask = bitand(x.samples(iTrig(1),:),2)==2;

uni = filtfilt(b_hpf,a_hpf,x.samples(iUni,mask)')';
uni(bad_ch,:) = randn(numel(bad_ch),size(uni,2));
uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
X = filtfilt(b_env,a_env,abs(uni_s)');
bad_ch = unique([bad_ch, find(isoutlier(rms(X,1)))]);

uni = filtfilt(b_hpf,a_hpf,x.samples(iUni,mask)')';
uni(bad_ch,:) = randn(numel(bad_ch),size(uni,2));
uni_s = reshape(del2(reshape(uni,8,16,[])),128,[]);
X = filtfilt(b_env,a_env,abs(uni_s)');

sync = x.samples(iTrig(1),mask);
sync = 15 - bitand(bitshift(sync,-3),15);
for ii = 1:numel(sync)
    sync(ii) = bitrevorder(sync(ii));
end
Y = dummyvar(categorical(sync'));
iFirst = zeros(1,size(Y,2));
for iY = 1:size(Y,2)
    iFirst(iY) = find(Y(:,iY)>0,1,'first');
end
[~,iAscend] = sort(iFirst,'ascend');
Y = Y(:,iAscend);

end