function [x_s, y_s] = triangulateSourceWithConstraints(x_coords, y_coords, amplitudes, x_center, y_center, R)
    % Ensure the inputs are column vectors
    x_coords = x_coords(:);
    y_coords = y_coords(:);
    amplitudes = amplitudes(:);

    % Define the objective function to minimize
    function error = objectiveFunction(params)
        x_s = params(1);
        y_s = params(2);
        S = params(3);
        estimated_distances = sqrt((x_s - x_coords).^2 + (y_s - y_coords).^2);
        observed_distances = sqrt(S ./ amplitudes);
        error = sum((estimated_distances - observed_distances).^2);
    end

    % Define the nonlinear constraint function
    function [c, ceq] = circleConstraint(params)
        x_s = params(1);
        y_s = params(2);
        % Inequality constraint (should be <= 0 for feasible points)
        c = (x_s - x_center)^2 + (y_s - y_center)^2 - R^2;
        % No equality constraint
        ceq = [];
    end

    % Initial guess for the source location and signal strength
    initial_guess = [mean(x_coords), mean(y_coords), max(amplitudes) * mean((x_coords - mean(x_coords)).^2 + (y_coords - mean(y_coords)).^2)];

    % Optimization options
    options = optimoptions('fmincon', 'Algorithm', 'interior-point', 'Display', 'off');

    % Perform the constrained optimization to find the source location and signal strength
    result = fmincon(@objectiveFunction, initial_guess, [], [], [], [], [], [], @circleConstraint, options);

    % Extract the source coordinates
    x_s = result(1);
    y_s = result(2);
end
