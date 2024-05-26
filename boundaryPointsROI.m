function [pointsTheta, pointsPhi] = boundaryPointsROI(mask, theta1, theta2, phi1, phi2)
    % Validate the mask
    if ~islogical(mask)
        error('The input mask must be a binary image.');
    end
    
    % Calculate properties of the binary mask
    props = regionprops(mask, 'Centroid');
    if isempty(props)
        error('No ROI found in the mask.');
    end
    
    % Extract the centroid
    centroid = props.Centroid;

    % Find the boundary of the ROI
    boundaries = bwboundaries(mask);
    boundary = boundaries{1}; % Assuming the mask has a single connected component
    
    % Convert boundary points to complex numbers for easier angle calculation
    boundaryComplex = boundary(:,2) + 1i*boundary(:,1);
    centroidComplex = centroid(1) + 1i*centroid(2);
    
    % Calculate angles of boundary points relative to the centroid
    angles = angle(boundaryComplex - centroidComplex);
    angles = wrapTo2Pi(angles);

    % Helper function to get points between two angles
    function points = getPointsBetweenAngles(angle1, angle2)
        angle1 = wrapTo2Pi(angle1);
        angle2 = wrapTo2Pi(angle2);
        
        if angle1 > angle2
            idx = (angles >= angle1) | (angles <= angle2);
        else
            idx = (angles >= angle1) & (angles <= angle2);
        end

        % Interpolate to get 8 points evenly spaced between these angles
        boundarySegment = boundary(idx, [2,1]);
        t = linspace(1, size(boundarySegment, 1), 8);
        points = interp1(1:size(boundarySegment, 1), boundarySegment, t);
    end
    
    % Get points between theta1 and theta2
    pointsTheta = getPointsBetweenAngles(theta1, theta2);
    
    % Get points between phi1 and phi2
    pointsPhi = getPointsBetweenAngles(phi1, phi2);
end
