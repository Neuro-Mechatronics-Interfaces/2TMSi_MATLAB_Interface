function [muapTrain, pastSamples] = apply_betas(curSamples, pastSamples, betas, nts, nch)
arguments
    curSamples
    pastSamples
    betas
    nts (1,1) double {mustBeInteger, mustBePositive} = 21;
    nch (1,1) double {mustBeInteger, mustBePositive} = 64;
end

ntot = nts*nch;
nUpdate = size(curSamples,2);
muapTrain = nan(1,nUpdate);
for iSample = 1:nUpdate
    pastSamples(setdiff(1:ntot,nts:nts:ntot)) = pastSamples(setdiff(1:ntot,1:nts:ntot)); % "shift" past samples backward
    pastSamples(nts:nts:ntot) = curSamples(:,iSample)';
    muapTrain(iSample) = pastSamples * betas;
end
end