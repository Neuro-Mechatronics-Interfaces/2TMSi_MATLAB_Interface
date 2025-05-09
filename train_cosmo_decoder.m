function [X,Y,BETA] = train_cosmo_decoder(SUBJ,YYYY,MM,DD,BLOCK,ENCODING,options)
arguments
    SUBJ {mustBeTextScalar}
    YYYY (1,1) double {mustBeInteger, mustBePositive}
    MM (1,1) double {mustBeInteger, mustBePositive}
    DD (1,1) double {mustBeInteger, mustBePositive}
    BLOCK (:,1) double
    ENCODING (:,:) double
    % options.DataRoot {mustBeTextScalar} = "C:/Data/MetaWB";
    % options.DataSubfolder {mustBeTextScalar} = "TMSi";
    options.DataRoot {mustBeTextScalar} = "C:/Data/TMSi"; % For acquisition machine
    options.DataSubfolder {mustBeTextScalar} = ""; % For acquisition machine
    options.Debug (1,1) logical = false;
    options.UseFirstSampleIfNoSyncPulse (1,1) logical = true;
    options.AlignSync (1,1) logical = true;
    options.ApplyFilter (1,1) logical = true;
    options.ApplyCAR (1,1) logical = true;
    options.ApplySpatialFilter (1,1) logical = true;
    options.SpatialFilterMode {mustBeMember(options.SpatialFilterMode, {'SD Columns', 'SD Rows', 'Laplacian'})} = 'Laplacian';
    options.ChannelMap (1,128) double {mustBePositive, mustBeInteger, mustBeInRange(options.ChannelMap,1,128)} = 1:128;
    options.EnvelopeCutoffFrequency (1,1) double = 1.5;
    options.HighpassFilterCutoff (1,1) double = 100;
    options.ApplyRMSCutoff (1,1) logical = false;
    options.RMSCutoff (1,2) double = [1, 100];
    options.ZeroMissing (1,1) logical = true; % Sets "missing" samples as zeros
    options.ApplyGridInterpolation (1,1) logical = true;
    options.InitialPulseOffset (1,1) {mustBeInteger} = 0; % Samples prior to first rising pulse, to include.
    options.SampleRate (1,1) double {mustBeMember(options.SampleRate, [2000, 4000])} = 2000;
    options.SyncBit (1,1) double = 0;
    options.RegressionComponents (1,1) double {mustBePositive, mustBeInteger} = 5;
    options.InvertSyncLogic = [];
    options.TriggerChannelIndicator {mustBeTextScalar} = 'TRIG';
    options.ExcludedPulseIndices (1,:) {mustBeInteger,mustBePositive} = [];
    options.IsTextile64 (:,1) logical = true;
    options.SwappedTextileCables (1,4) logical = false(1,4);
    options.Description {mustBeTextScalar} = "1-64 = PROX-EXT; 65-128 = DIST-EXT; 129-192 = PROX-FLX; 193-256 = DIST-FLX."
end
if numel(BLOCK)~=size(ENCODING,1)
    error("Must have same number of rows in ENCODING as elements of BLOCK!");
end

TANK = sprintf("%s_%04d_%02d_%02d", SUBJ, YYYY, MM, DD);
if strlength(options.DataSubfolder)==0
    input_root = sprintf('%s/%s/%s', options.DataRoot, SUBJ, TANK);
else
    input_root = sprintf('%s/%s/%s', options.DataRoot, TANK, options.DataSubfolder);
end
X = [];
Y = [];
trigBitMask = 2^options.SyncBit;
fprintf(1,'Please wait, training decoder...000%%\n');
for iB = 1:numel(BLOCK)
    A = dir(fullfile(input_root,sprintf("*A*%d.poly5",BLOCK(iB))));
    if isempty(A)
        error("Missing A file for BLOCK=%d", BLOCK(iB));
    end
    B = dir(fullfile(input_root,sprintf("*B*%d.poly5",BLOCK(iB))));
    if isempty(B)
        error("Missing B file for BLOCK=%d", BLOCK(iB));
    end
    poly5_files = [string(fullfile(A(1).folder,A(1).name)); ...
                   string(fullfile(B(1).folder,B(1).name))];
    [data,~,ch_name] = io.load_align_saga_data_many(poly5_files, ...
        'ApplyFilter', options.ApplyFilter, ...
        'ApplyCAR', options.ApplyCAR, ...
        'Debug', options.Debug, ...
        'HighpassFilterCutoff', options.HighpassFilterCutoff, ...
        'ApplyRMSCutoff', options.ApplyRMSCutoff, ...
        'RMSCutoff', options.RMSCutoff, ...
        'ZeroMissing',options.ZeroMissing,...
        'ApplyGridInterpolation', options.ApplyGridInterpolation, ...
        'ApplySpatialFilter', options.ApplySpatialFilter, ...
        'SpatialFilterMode', options.SpatialFilterMode, ...
        'InitialPulseOffset', options.InitialPulseOffset, ...
        'InvertLogic', options.InvertSyncLogic, ...
        'SampleRate', options.SampleRate, ...
        'TriggerChannelIndicator', options.TriggerChannelIndicator, ...
        'TriggerBitMask', trigBitMask, ...
        'IsTextile64', options.IsTextile64, ...
        'SwappedTextileCables', options.SwappedTextileCables, ...
        'UseFirstSampleIfNoSyncPulse', options.UseFirstSampleIfNoSyncPulse, ...
        'ExcludedPulseIndices', options.ExcludedPulseIndices);
    [iUni,~,iTrig] = get_saga_channel_masks(ch_name,...
        'ReturnNumericIndices',true);
    uni = data.samples(iUni,:);
    trig = bitand(data.samples(iTrig(1),:)', trigBitMask)==0;
    % i_start = strfind(trig',[1 0]);
    % trig(1:i_start(1)) = false;
    [b_env,a_env] = butter(1,options.EnvelopeCutoffFrequency/(data.sample_rate/2),'low');
    env = filtfilt(b_env,a_env,abs(uni'));
    X = [X; env]; %#ok<*AGROW>
    Y = [Y; trig * ENCODING(iB,:)];
    fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*iB/numel(BLOCK)));
end
r = rms(X,2);
R = movmean(r,options.SampleRate);
X(isoutlier(R),:) = 0;
[XL,YL,XS,YS,BETA,PCTVAR,MSE,stats] = plsregress(X,Y,options.RegressionComponents);

save(sprintf('%s/%s_MODEL.mat',input_root,TANK),'XL','YL','XS','YS','BETA','PCTVAR','MSE','stats','-v7.3');
utils.print_windows_folder_link(input_root,sprintf('Saved file: %s_MODEL.mat', TANK));

end