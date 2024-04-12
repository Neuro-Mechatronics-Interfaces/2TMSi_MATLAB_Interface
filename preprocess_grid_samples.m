function hpf = preprocess_grid_samples(uni, options)

arguments
uni (64,:) double
options.Fc = 100;
options.SampleRate = 4000;
options.MinRMS = 1.0;
end

[b,a] = butter(3,100/(options.SampleRate/2), 'high');
tmp = filter(b,a,uni,[],2);
tmp(:,1:100) = 0;
i_exc = rms(tmp,1) < options.MinRMS;
tmp(:,i_exc) = missing;
tmp = reshape(tmp,8,8,size(tmp,2));
hpf = nan(size(tmp));
for ii = 1:size(hpf,3)
    hpf(:,:,ii) = fillmissing2(tmp(:,:,ii),'linear');
end
hpf = reshape(hpf,64,size(tmp,3));

end