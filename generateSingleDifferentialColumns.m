function S = generateSingleDifferentialColumns(gridDims)
% GENERATESINGLEDIFFERENTIALCOLUMNS Generate single-differential matrix for columns.
%
%   S = GENERATESINGLEDIFFERENTIALCOLUMNS(gridDims) computes the
%   single-differential weight matrix along the columns for the given grids.
%
%   Inputs:
%   -------
%   gridDims : Nx2 matrix
%       Each row specifies the [rows, cols] for a separate grid.
%       Example: [8, 8; 8, 8] represents two 8x8 grids.
%
%   Outputs:
%   --------
%   S : matrix
%       The single-differential weight matrix along columns. Size is NxN,
%       where N is the total number of electrodes across all grids.

% Validate inputs
numGrids = size(gridDims, 1);
totalElectrodes = sum(prod(gridDims, 2));
gridSplit = [1; cumsum(prod(gridDims, 2))];
gridSplit = gridSplit(1:(end-1))';

% Initialize S
S = zeros(totalElectrodes);

% Iterate over each grid
for g = 1:numGrids
    rows = gridDims(g, 1);
    cols = gridDims(g, 2);
    startIdx = gridSplit(g);
    endIdx = startIdx + rows * cols - 1;

    % Generate single-differential columns for this grid
    localS = generateGridDifferentialColumns(rows, cols);

    % Assign to the global matrix
    S(startIdx:endIdx, startIdx:endIdx) = localS;
end
end

function S = generateGridDifferentialColumns(rows, cols)
% GENERATEGRIDDIFFERENTIALCOLUMNS Generate single-differential matrix for columns.
%
%   Inputs:
%   -------
%   rows : integer
%       Number of rows in the grid.
%   cols : integer
%       Number of columns in the grid.
%
%   Outputs:
%   --------
%   S : matrix
%       Single-differential weight matrix for columns.

numElectrodes = rows * cols;
S = zeros(numElectrodes);

for i = 1:rows
    for j = 1:cols
        idx = sub2ind([rows, cols], i, j);

        % Add weight for column differential
        if j < cols
            neighborIdx = sub2ind([rows, cols], i, j+1);
            S(idx, neighborIdx) = -1;
            S(idx, idx) = 1; % Differential weight
        end
    end
end
end
