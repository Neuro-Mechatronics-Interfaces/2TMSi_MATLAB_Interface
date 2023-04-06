function [xg, yg] = parse_pattern_grid(pdata)
%PARSE_PATTERN_GRID  Parse meshgrid for putting pattern responses into grid
%
% Syntax:
%   [xg, yg] = parse_pattern_grid(pdata);
%
% Example:
%   F = dir('patterns/HP_25/*.txt');
%   pdata = [];
%   for iF = 1:numel(F)
%       pdata = [pdata; parse_pattern_volume_string(F(iF).name)];
%   end
%   [xg, yg] = parse_pattern_grid(pdata);
%
% Inputs:
%   pdata - Pattern data struct array. Has the following fields:
%               'name' - Original string
%               'optimizer' - 'J' or 'Jsafety' or 'HP' etc
%               'focusing_level' - ranges from 5-20 (scalar int)
%               'x' - X-Center location (mm)
%               'y' - Y-Center location (mm)
%               'pattern_units' - The units based on pattern naming (for
%                                   debug primarily).
% Output:
%   [xg, yg] - X/Y meshgrid for gridded pattern responses. This can be used
%               for example to generate a square-grid to be used with cdata
%               of an image to display how the responses look.

ux = sort(unique([pdata.x]), 'ascend');
uy = sort(unique([pdata.y]), 'ascend');

dx = min(diff(ux))/2;
dy = min(diff(uy))/2;

xg = (ux(1)-dx):dx:(ux(end)+dx);
yg = (uy(1)-dy):dy:(uy(end)+dy);

end