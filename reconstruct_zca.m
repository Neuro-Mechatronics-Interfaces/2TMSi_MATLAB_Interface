function uni_r = reconstruct_zca(uni, options)

arguments
    uni (64,:) double
    options.ChunkSize (1,1) {mustBePositive, mustBeInteger} = 256;
    options.ExtensionFactor (1,1) {mustBePositive, mustBeInteger} = 48;
    options.BufferSize (1,1) {mustBePositive, mustBeInteger} = 4096;
    options.NKeep (1,1) {mustBeInteger} = 3;
    options.NDrop (1,1) {mustBeInteger} = 0;
    options.NoiseLevel (1,1) double = 1;
    options.FilterCutoff (1,2) double = [0.03, 0.1];
    options.Alpha (1,1) double = 0.95;
end

[b,a] = butter(1,options.FilterCutoff,'bandpass');
zca_buf = WhiteningBuffer(64, options.BufferSize);
Pw = eye(64*options.ExtensionFactor);
zi = zeros(2,64);
uni_r = zeros(size(uni));
for ii = 1:options.ChunkSize:size(uni,2)
    vec = ii:min(ii+options.ChunkSize-1,size(uni,2));
    [hpf,zi] = filter(b,a,uni(:,vec),zi,2);
    [refresh,K] = zca_buf.update(hpf);
    edata = fast_extend(zca_buf.getWindow(options.ExtensionFactor,K),options.ExtensionFactor);
    if refresh
        [zdata,Pw] = fast_proj_eig_dr(edata, Pw.(device(ii).tag), options.ExtensionFactor, options.Alpha, options.NoiseLevel, options.NKeep, options.NDrop);
    else
        zdata = Pw * edata(:, (options.ExtensionFactor+1):(end-options.ExtensionFactor+1));
    end
    uni_r(:,vec) = zdata((1:options.ExtensionFactor:(63*options.ExtensionFactor+1)),:);
end
uni_r(:,1:round(options.ChunkSize/2)) = 0;

end