function pdata = filter_patterns_by_spatial_extent(pdata, xLim, yLim, dX, dY)
%FILTER_PATTERNS_BY_SPATIAL_EXTENT  Filters array of patterns by spatial coordinates
%
% Syntax:
%   pdata = filter_patterns_by_spatial_extent(pdata, xLim, yLim);
%   pdata = filter_patterns_by_spatial_extent(pdata, xLim, yLim, dX, dY);
%
% Example 1:
%   pdata = filter_patterns_by_spatial_extent(pdata, [-3000,-1500], [0,2000]);
%
% Example 2:
%   pdata = filter_patterns_by_spatial_extent(pdata, [-3000,-1500], [0,2000], 500, 1000);
%       -> Returns a coarser grid (less patterns) than in first example.
%
% Inputs:
%   pdata - Array of pattern data parsed from the pattern filenames using
%               `parse_pattern_volume_string`
%               -> Assumes that 'x' and 'y' of each `pdata` element is in
%               units of millimeters (as returned by that function).
%   xLim  - [min, max] extents in x-dimension (microns)
%   yLim  - [min, max] extents in y-dimension (microns)
%
%  Orientation:
%   X: Mediolateral axes. Negative is lateral.
%   Y: Anteroposterior axes. Negative is anterior.
%
% See also: Contents, parse_pattern_volume_string

X = ([pdata.x]) .* 1e3;
Y = ([pdata.y]) .* 1e3;

idx_x = (X >= xLim(1)) & (X < xLim(2));
idx_y = (Y >= yLim(1)) & (Y < yLim(2));
idx_xy = idx_x & idx_y;

pdata = pdata(idx_xy);
if nargin < 5
    return;
end
% Restrict these to only the pdata we are considering after cutting down
% the "ROI" for our grid:
X = X(idx_xy);
Y = Y(idx_xy);

x_edges = xLim(1):dX:xLim(2);
y_edges = yLim(1):dY:yLim(2);

iX = discretize(X, x_edges);
iY = discretize(Y, y_edges);

uBinX = unique(iX); % Unique "columns" in the grid.
keep = false(size(X));

for iBinX = 1:numel(uBinX)  % Go through each column
    mask_iX = iX == uBinX(iBinX); % Get mask for the row entries related to this column
    uBinY = unique(iY(mask_iX)); 
    for iBinY = 1:numel(uBinY)
        % Find the unique bins where each row intersects with this column
        i_keep = find((iY == uBinY(iBinY)) & mask_iX, 1, 'first');
        keep(i_keep) = true;
    end
end
% Use this sub-sampled grid to return the subset of pdata elements matching
% the first member in each discretized bin.
pdata = pdata(keep);

end