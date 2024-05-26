function [x_s, y_s] = triangulateSource(x_coords, y_coords, amplitudes)
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

    % Initial guess for the source location (mean of sensor coordinates) and signal strength
    initial_guess = [mean(x_coords), mean(y_coords), max(amplitudes) * mean((x_coords - mean(x_coords)).^2 + (y_coords - mean(y_coords)).^2)];

    % Optimization options
    options = optimoptions('fminunc', 'Algorithm', 'quasi-newton', 'Display', 'off');

    % Perform the optimization to find the source location and signal strength
    result = fminunc(@objectiveFunction, initial_guess, options);

    % Extract the source coordinates
    x_s = result(1);
    y_s = result(2);
end
