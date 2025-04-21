edata = randn(256, 100000);  % Example data
normalTic = tic;
Rw = (edata * edata') / (size(edata,2) - 1);
[V, D] = eig(Rw);
normalToc = toc(normalTic);

gpuTic = tic;
edata_gpu = gpuArray(edata);
Rw_gpu = (edata_gpu * edata_gpu') / (size(edata,2) - 1);
[Vg, Dg] = eig(Rw_gpu);
wait(gpuDevice);  % Ensure all GPU work finishes
gpuToc = toc(gpuTic);

fprintf(1,'normalToc / gpuToc = %.2f (if > 1.5, use GPU to significantly boost performance).\n', normalToc / gpuToc);