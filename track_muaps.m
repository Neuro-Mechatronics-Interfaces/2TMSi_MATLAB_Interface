function [IPTs, Rt_inv, source, target] = track_muaps(cleaned_file_source, cleaned_file_target, options)
arguments
    cleaned_file_source {mustBeTextScalar}
    cleaned_file_target {mustBeTextScalar}
    options.InputRoot {mustBeTextScalar} = "C:/Data/Temp/Auto";
    options.ExtensionFactor (1,1) {mustBePositive, mustBeInteger} = 18;
    options.Verbose (1,1) logical = true;
end
if options.Verbose
    muapTrackerTic = tic;
end
inRoot = options.InputRoot;

if exist(fullfile(inRoot, cleaned_file_source),'file')==0
    error("No file %s exists in folder %s.", cleaned_file_source, options.InputRoot);
end

if exist(fullfile(inRoot, cleaned_file_target),'file')==0
    error("No file %s exists in folder %s.", cleaned_file_target, options.InputRoot);
end
if options.Verbose
    fprintf(1,'Loading source (%s)...\n', cleaned_file_source);
end
source = load(fullfile(inRoot, cleaned_file_source));
if options.Verbose
    fprintf(1,'Loading target (%s)...\n', cleaned_file_target);
end
target = load(fullfile(inRoot, cleaned_file_target));
Ys = ckc.sig_2_samples(source);
Yt = ckc.sig_2_samples(target);
% Yc = [Ys, Yt];

Ys_e = ckc.extend(Ys, options.ExtensionFactor);
% tmp = Ys_e ./ var(Ys_e,[],2);
% Rs = cov(tmp');
Yt_e = ckc.extend(Yt, options.ExtensionFactor);
if options.Verbose
    fprintf(1,'Computing covariance of target...');
end
Rt = Yt_e * Yt_e';
Rt_inv = pinv(Rt);


% Yc_e = ckc.extend(Yc, options.ExtensionFactor);
% Ry = Yc_e * Yc_e';
% Ry_inv = pinv(Ry);
if options.Verbose
    fprintf(1,'Projecting target IPTs...');
end
IPTs = zeros(numel(source.MUPulses),size(Yt_e,2));
for m = 1:numel(source.MUPulses)
    IPTs(m,:) = sum(Ys_e(:,source.MUPulses{m}),2)'*Rt_inv*Yt_e;
    IPTs(m,:) = IPTs(m,:) ./ max(IPTs(m,:));
end
if options.Verbose
    fprintf(1,'complete!\n');
end
if options.Verbose
    toc(muapTrackerTic);
end

end