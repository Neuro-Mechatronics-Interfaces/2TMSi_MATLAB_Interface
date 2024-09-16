function w = generateSigmoid(n, attenuation, options)
%GENERATESIGMOID Returns a 1 x n sigmoid vector where the first element is 1 and the last element is determined by the attenuation factor in dB.
%
% Syntax:
%   w = generateSigmoid(n, attenuation)
%   w = generateSigmoid(n, attenutation, 'Name', value, ...);
%
% Inputs:
%       n           - (integer) The length of the output sigmoid vector.
%                     Must be greater than 1.
%       attenuation - (double) The attenuation factor in dB, determining
%                     how many decibels below unity-gain (1) the last
%                     element of the sigmoid will be. Must be >= 1 dB.
%                     Default value is 20 dB.
%
% Options:
%   SigmoidInitialValue (1,1) double = 1;
%   SigmoidShapeRange (1,2) double = [6, -6];
% 
% Outputs:
%       w - A 1 x n vector representing a sigmoid curve where the first
%           element is 1, and the last element is the magnitude corresponding
%           to the specified attenuation factor.
%
% Example 1:
%       w = generateSigmoid(100, 40);
%
%       This generates a 1 x 100 sigmoid vector where the first element is 
%       1 and the last element is 0.01 (40 dB below the first element).
%
% Example 2:
%       w = generateSigmoid(30,20, ...
%           'SigmoidInitialValue',100, ...
%           'SigmoidShape',[-12 4]);
%
%       This generates a 1 x 30 sigmoid vector where the last element is 
%       100 and the first element is 10 (20 dB below the first element).
%       The 'SigmoidShape' asymmetry causes the "tail" to be left-skewed.
%
% Notes:
%       The attenuation factor is converted from dB to linear magnitude
%       using the formula:
%           finalValue = 10^(-attenuation/20)
%       which is equivalent to MATLAB's built-in function 
%           finalValue = db2mag(-attenuation)
%
%   The sigmoid curve is generated between two extremes 
%   (set by options.SigmoidShapeRange) and is then scaled such that the 
%   first value is exactly equal to options.SigmoidInitialValue and the 
%   last value is the fraction of options.SigmoidInitialValue specified by
%   the attenuation argument. By default, the first value of
%   options.SigmoidShapeRange is positive and second is negative. Swapping
%   the ordering to negative and positive will cause the "mirrored" shape
%   of the sigmoid function.

arguments
    n (1,1) double {mustBeInteger, mustBeGreaterThan(n,1)}
    attenuation (1,1) double {mustBeGreaterThanOrEqual(attenuation,1)} = 20;
    options.SigmoidInitialValue (1,1) double = 1;
    options.SigmoidShapeRange (1,2) double = [6, -6];
end

% Convert attenuationFactor (in dB) to fraction of initial value.
finalValue = options.SigmoidInitialValue * 10^(-attenuation/20); % equivalent to db2mag(-attenuation)

% Generate a sigmoid curve between 1 and the attenuationMagnitude
x = linspace(options.SigmoidShapeRange(1), options.SigmoidShapeRange(2), n);  % x-axis values for the sigmoid curve
sigmoid = 1 ./ (1 + exp(-x));  % Standard sigmoid function

% Scale the sigmoid so that it starts at 1 and ends at attenuationMagnitude
w = sigmoid * (options.SigmoidInitialValue - finalValue) + finalValue;

end
