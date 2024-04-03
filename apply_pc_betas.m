function [y, zf] = apply_pc_betas(curSamples, zi, betas, coeff)
arguments
    curSamples
    zi
    betas
    coeff
end

score = curSamples * coeff;
[y, zf] = filter(betas', 1, abs(score), zi);

end