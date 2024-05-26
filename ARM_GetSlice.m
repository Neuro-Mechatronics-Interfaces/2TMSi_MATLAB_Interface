function [fname,A,map,transparency,cdata] = ARM_GetSlice(x, options)
%ARM_GETSLICE  Returns file corresponding to MRI slice of arm
arguments
    x (1,1) double % Distance from first slice "column" (cm)
    % options.SlicesRoot {mustBeFolder} = "C:/Data/Anatomy/Cartoons/Sections";
    options.SlicesRoot {mustBeFolder} = "C:/Data/Anatomy/Human Arm/Sections";
    options.Slice0 (1,1) {mustBeInteger} = 105;
    options.SliceSpacing (1,1) double = 0.5; % cm
    options.SliceMax (1,1) {mustBeInteger} = 130;
    % options.SliceNameExpr {mustBeTextScalar} = "Slice_%d.png";
    options.SliceNameExpr {mustBeTextScalar} = "R_Forearm_Section_%d.png"
end
CDATA = [         ...
    0.0000    0.4470    0.7410; ...
    0.8500    0.3250    0.0980; ...
    0.9290    0.6940    0.1250; ...
    0.4940    0.1840    0.5560];
allSliceValues = options.Slice0:options.SliceMax;
sliceValuesZeroed = allSliceValues - allSliceValues(1);
sliceValuesScaled = sliceValuesZeroed .* options.SliceSpacing;

if x > sliceValuesScaled(end)
    error("Distance of %5.2f-cm is out of bounds of slices (max allowed with current settings is %5.2f-cm).", x, sliceValuesScaled(end));
end

[~,idx] = min(abs(sliceValuesScaled - x));
value = allSliceValues(idx(1));

% Return as char to make compatible with exportToPPTX function.
fname = char(strrep(fullfile(options.SlicesRoot, sprintf(options.SliceNameExpr, value)),"\","/"));
if x > 6.5
    cdata = CDATA([2,4],:);
else
    cdata = CDATA([1,3],:);
end

if nargout < 2
    return;
end

[A,map,transparency] = imread(fname);

end