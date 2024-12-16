function S = generateLaplacianMatrix(gridDims)
% GENERATELAPLACIANMATRIX Generate the spatial weight matrix for a discrete 2D Laplacian.
%
%   S = GENERATELAPLACIANMATRIX(gridDims) computes the Laplacian
%   weight matrix for the given electrode grids.
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
%       The spatial weight matrix for the Laplacian. Size is NxN, where N
%       is the total number of electrodes across all grids.
%
%   Example:
%   --------
%   % For two 8x8 grids
%   gridDims = [8, 8; 8, 8];
%   S = generateLaplacianMatrix(gridDims, gridSplit);

% Validate inputs
numGrids = size(gridDims, 1);
totalElectrodes = sum(prod(gridDims, 2));
gridSplit = [1; cumsum(prod(gridDims,2))];
gridSplit = gridSplit(1:(end-1))';

% Initialize S
S = zeros(totalElectrodes);

% Iterate over each grid
for g = 1:numGrids
    rows = gridDims(g, 1);
    cols = gridDims(g, 2);
    startIdx = gridSplit(g);
    endIdx = startIdx + rows * cols - 1;

    % Generate Laplacian weights for this grid
    localS = generateGridLaplacian(rows, cols);

    % Assign to the global matrix
    S(startIdx:endIdx, startIdx:endIdx) = localS;
end
end

function S = generateGridLaplacian(rows, cols)
% GENERATEGRIDLAPLACIAN Generate Laplacian weight matrix for a single grid.
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
%       Laplacian weight matrix for the grid.

numElectrodes = rows * cols;
S = zeros(numElectrodes);

% Map linear indices to 2D coordinates
for i = 1:rows
    for j = 1:cols
        idx = sub2ind([rows, cols], i, j);

        % Get neighbors
        neighbors = [];
        if i > 1, neighbors(end+1) = sub2ind([rows, cols], i-1, j); end % Up
        if i < rows, neighbors(end+1) = sub2ind([rows, cols], i+1, j); end % Down
        if j > 1, neighbors(end+1) = sub2ind([rows, cols], i, j-1); end % Left
        if j < cols, neighbors(end+1) = sub2ind([rows, cols], i, j+1); end % Right

        % Add weights to S
        S(idx, neighbors) = -1 / length(neighbors);
        S(idx, idx) = 1; % Central weight
    end
end
end
