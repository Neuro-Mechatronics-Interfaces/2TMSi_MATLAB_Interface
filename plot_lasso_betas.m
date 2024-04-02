function fig = plot_lasso_betas(betas, options)
%PLOT_LASSO_BETAS  Plot time-sequence
arguments
    betas (:,1) double
    options.Colormap {mustBeTextScalar} = "bluered";
    options.ColorbarTitle {mustBeTextScalar} = "";
    options.CLim (1,2) double = [-0.1, 0.1];
    options.FigurePosition (1,4) double = [400   100   720   750];
    options.QueryPoints (1,1) double {mustBePositive,mustBeInteger} = 128;
    options.Montage {mustBeTextScalar, mustBeMember(options.Montage,["8x8 Grid","4x8 Grid"])} = "8x8 Grid";
    options.InterpolationMethod {mustBeMember(options.InterpolationMethod,["makima","linear","pchip","spline"])} = "makima";
    options.NChannels (1,1) double {mustBeInteger, mustBeInRange(options.NChannels,1,64)} = 64;
    options.Vector (1,:) double {mustBeInteger} = -10:10;
    options.Subtitle {mustBeTextScalar} = "";
    options.SampleRate (1,1) double = 4000;
end

nTimePoints = numel(options.Vector);
b = reshape(betas, nTimePoints, options.NChannels)';
axTitle = cell(nTimePoints,1);
for ii = 1:nTimePoints
    axTitle{ii} = sprintf('t = %5.2f', round(options.Vector(ii)/(options.SampleRate*1e-3),2));
end
fig = plot_spatial_weights(b, 2, ...
    'AxesTitle', axTitle, ...
    'ColorbarTitle', options.ColorbarTitle, ...
    'Colormap', options.Colormap, ...
    'CLim', options.CLim, ...
    'FigurePosition', options.FigurePosition, ...
    'QueryPoints', options.QueryPoints, ...
    'Montage', options.Montage, ...
    'Subtitle', options.Subtitle, ...
    'InterpolationMethod', options.InterpolationMethod);

end