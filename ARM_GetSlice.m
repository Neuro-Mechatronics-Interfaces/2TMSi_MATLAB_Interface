function [fname,A,map,transparency] = ARM_GetSlice(x, options)
%ARM_GETSLICE  Returns file corresponding to MRI slice of arm
arguments
    x (1,1) double % Distance from first slice "column" (cm)
    options.SlicesRoot {mustBeFolder} = "C:\Data\Anatomy\Human Arm\Sections";
    options.Slice0 (1,1) {mustBeInteger} = 105;
    options.SliceSpacing (1,1) double = 0.5; % cm
    options.SliceMax (1,1) {mustBeInteger} = 130;
    options.SliceNameExpr {mustBeTextScalar} = "R_Forearm_Section_%d.png";
end

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

if nargout < 2
    return;
end

[A,map,transparency] = imread(fname);

end