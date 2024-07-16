function T = calculate_transformation_matrix(x1, y1, x2, y2)
% CALCULATE_TRANSFORMATION_MATRIX Compute the transformation matrix
% that maps (x1, y1) to [1; 0] and (x2, y2) to [0; 1].
%
% Arguments:
%   x1, y1 - Coordinates of the first point
%   x2, y2 - Coordinates of the second point
%
% Returns:
%   T - 2x2 transformation matrix

% Construct the matrix with the original points
A = [x1, x2; y1, y2];

% Define the target unit vectors
B = [1, 0; 0, 1];

% Calculate the transformation matrix
T = A \ B;
end
