function eSamples = data_2_extended_samples(data, extensionFactor,options)
%DATA_2_EXTENDED_SAMPLES Convert data to extended samples array.
arguments
    data struct
    extensionFactor (1,1) {mustBePositive, mustBeInteger} = 15;
    options.BigGridSize (1,2) {mustBePositive, mustBeInteger} = [16 16];
    options.SmallGridSize (1,2) {mustBePositive, mustBeInteger} = [8 8];
end

[iRow,iCol] = grid_of_grids_to_columns(options.BigGridSize,options.SmallGridSize);
samples = zeros(numel(data.SIG),numel(data.SIG{1,1}));
for ii = 1:numel(data.SIG)
    if ~isempty(data.SIG{iRow(ii),iCol(ii)})
        samples(ii,:) = data.SIG{iRow(ii),iCol(ii)};
    end
end
eSamples = ckc.extend(samples,extensionFactor);

end