function [H,stats] = batch_test_covariances(snippets, options)
%BATCH_TEST_COVARIANCES  Tests covariance on tensor of snippets or cell array of such tensors.
arguments
    snippets 
    options.Alpha (1,1) double {mustBeInRange(options.Alpha,0,1)} = 0.01;
    options.Verbose (1,1) logical = true;
end
data = [];
if iscell(snippets)
    for ii = 1:size(snippets,1)
        for ik = 1:size(snippets{ii},3)
            data = [data; [ones(size(snippets{ii},1),1).*ii, snippets{ii}(:,:,ik)]]; %#ok<AGROW>
        end
    end
else
    for ii = 1:size(snippets,3)
        data = [data; [ones(size(snippets,1),1).*ii, snippets(:,:,ii)]]; %#ok<AGROW>
    end
end
[H,stats] = utils.MBoxtest(data,options.Alpha,'Verbose',options.Verbose);

end