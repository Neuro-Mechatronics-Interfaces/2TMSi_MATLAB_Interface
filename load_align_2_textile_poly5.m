function x = load_align_2_textile_poly5(SUBJ,YYYY,MM,DD,BLOCK,options)
%LOAD_ALIGN_2_TEXTILE_POLY5 Loads two aligned textile TMSiSAGA polyy5 recordings from the same session.
arguments
    SUBJ {mustBeTextScalar}
    YYYY (1,1) double {mustBeInteger, mustBePositive}
    MM (1,1) double {mustBeInteger, mustBePositive}
    DD (1,1) double {mustBeInteger, mustBePositive}
    BLOCK (:,1) double
    options.DataRoot {mustBeTextScalar} = "C:/Data/MetaWB";
    options.DataSubfolder {mustBeTextScalar} = "TMSi";
    % options.DataRoot {mustBeTextScalar} = "C:/Data/TMSi"; % For acquisition machine
    % options.DataSubfolder {mustBeTextScalar} = ""; % For acquisition machine
    options.Debug (1,1) logical = false;
    options.UseFirstSampleIfNoSyncPulse (1,1) logical = true;
    options.AlignSync (1,1) logical = true;
    options.ApplyFilter (1,1) logical = true;
    options.ApplyCAR (1,1) logical = true;
    options.ApplySpatialFilter (1,1) logical = true;
    options.ApplyEnvelope (1,1) logical = true;
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
    options.SyncBit (1,:) double = 0;
    options.RegressionComponents (1,1) double {mustBePositive, mustBeInteger} = 5;
    options.InvertSyncLogic = [];
    options.TriggerChannelIndicator {mustBeTextScalar} = 'TRIG';
    options.ExcludedPulseIndices (1,:) {mustBeInteger,mustBePositive} = [];
    options.SwappedTextileCables (1,2) logical = false(1,2);
    options.Description {mustBeTextScalar} = "1-64 = PROXINMAL; 65-128 = DISTAL"
end

TANK = sprintf("%s_%04d_%02d_%02d", SUBJ, YYYY, MM, DD);
if strlength(options.DataSubfolder)==0
    input_root = sprintf('%s/%s/%s', options.DataRoot, SUBJ, TANK);
else
    input_root = sprintf('%s/%s/%s', options.DataRoot, TANK, options.DataSubfolder);
end

A = dir(fullfile(input_root,sprintf("*A*%d.poly5",BLOCK)));
if isempty(A)
    error("Missing A file for BLOCK=%d", BLOCK(iB));
end
B = dir(fullfile(input_root,sprintf("*B*%d.poly5",BLOCK)));
if isempty(B)
    error("Missing B file for BLOCK=%d", BLOCK);
end
poly5_files = [string(fullfile(A(1).folder,A(1).name)); ...
    string(fullfile(B(1).folder,B(1).name))];
x = io.load_align_saga_data_many(poly5_files, ...
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
    'TriggerBitMask', 2.^options.SyncBit, ...
    'IsTextile64', true, ...
    'SwappedTextileCables', options.SwappedTextileCables, ...
    'UseFirstSampleIfNoSyncPulse', options.UseFirstSampleIfNoSyncPulse, ...
    'ExcludedPulseIndices', options.ExcludedPulseIndices);
x.mask = struct;
[x.mask.uni, x.mask.bip, x.mask.trig] = get_saga_channel_masks(x.channels,'ReturnNumericIndices',true);
if options.ApplyEnvelope
    [b_env,a_env] = butter(1,options.EnvelopeCutoffFrequency/(x.sample_rate/2),'low');
    x.env = filtfilt(b_env,a_env,abs(x.samples(x.mask.uni,:))')';
end
end