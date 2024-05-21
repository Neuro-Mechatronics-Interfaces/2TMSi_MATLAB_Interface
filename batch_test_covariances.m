function [H,pair,stats] = batch_test_covariances(snippets, options)
%BATCH_TEST_COVARIANCES  Tests covariance on tensor of snippets or cell array of such tensors.
arguments
    snippets 
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.05;
    options.Channels (1,:) = [];
    options.ConditioningLevel (1,1) double = 0;
    options.NumDimensions (1,1) {mustBePositive,mustBeInteger} = 2;
    options.Verbose (1,1) logical = true;
end
if isempty(options.Channels)
    if iscell(snippets)
        channels = 1:size(snippets{1},2);
    else
        channels = 1:size(snippets,2);
    end
else
    channels = options.Channels;
end
numDims = min(options.NumDimensions,numel(channels));
data = [];
if iscell(snippets)
    for ii = 1:size(snippets,1)
        pooled_group = [];
        for ik = 1:size(snippets{ii},3)
            pooled_group = [pooled_group; snippets{ii}(:,channels,ik)]; %#ok<AGROW>
        end
        [~,pooled_group] = pca(pooled_group,'NumComponents',numDims);
        data = [data; [ones(size(pooled_group,1),1).*ii, pooled_group]]; %#ok<AGROW>
    end
else
    for ii = 1:size(snippets,3)
        [~,scores] = pca(snippets(:,channels,ii),'NumComponents',numDims);
        data = [data; [ones(size(snippets,1),1).*ii, scores]]; %#ok<AGROW>
    end
end
G = findgroups(data(:,1));
pair = nchoosek(1:max(G),2);
N = size(pair,1);
H = false(N,1);
stats = cell(N,1);
if options.Verbose
    fprintf(1,'Please wait, running batch Box M Test for %d pairs...000%%\n',N);
end
for ii = 1:N
    idx = (data(:,1)==pair(ii,1)) | (data(:,1)==pair(ii,2));
    [H(ii),stats{ii}] = utils.MBoxtest(data(idx,:), ...
        options.Alpha/N, ...
        'Verbose',false, ...
        'PlotScatter',false,...
        'ConditioningLevel',options.ConditioningLevel);
    if options.Verbose
        fprintf(1,'\b\b\b\b\b%03d%%\n',round(100*ii/N));
    end
end
end