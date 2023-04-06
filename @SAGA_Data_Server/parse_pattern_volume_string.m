function pdata = parse_pattern_volume_string(str, varargin)
%PARSE_PATTERN_VOLUME_STRING  Parses pattern volume string from filenames.
%
% Syntax:
%   pdata = SAGA_Data_Server.parse_pattern_volume_string(str, 'Name', value, ...);
%
% Inputs:
%   str - Pattern volume string (filename; char array or string)
%   varargin - (Optional) 'Name', value input argument pairs.
%
% Output:
%   pdata - Pattern data struct. Has the following fields:
%               'name' - Original string
%               'optimizer' - 'J' or 'Jsafety' or 'HP' etc
%               'focusing_level' - ranges from 5-20 (scalar int)
%               'x' - X-Center location (mm)
%               'y' - Y-Center location (mm)
%               'pattern_units' - The units based on pattern naming (for
%                                   debug primarily).
%
% See also: Contents, SAGA_Data_Server, N3_Online_Stim

if all(~ischar(str)) && (numel(str) > 1)
    pdata = [];
    for ii = 1:numel(str)
        pdata = [pdata; parse_pattern_volume_string(string(str(ii)))]; %#ok<AGROW> 
    end
    return;
end

p = inputParser();
p.addRequired("str", @(in)(all(ischar(in))||isstring(in)));
p.addParameter("delimiter", "_", @(in)(ischar(in)||isstring(in)));
% Use regexp from hell because Mats hates me
p.addParameter("focusing_expr", "(?<focusing>\d+)",@(in)(all(ischar(in))||isstring(in)));
p.addParameter("x_expr","(?<x>(?<=x)-?\d+)(?<unit>[mu]m)",@(in)(all(ischar(in))||isstring(in)));
p.addParameter("y_expr","(?<y>(?<=y)-?\d+)(?<unit>[mu]m)",@(in)(all(ischar(in))||isstring(in)));
p.parse(str, varargin{:});
[~, str, ~] = fileparts(p.Results.str);

pdata = struct('name', string(str), 'optimizer', "Unknown", 'focusing_level', nan, 'x', 0, 'y', 0, 'pattern_units', "mm");

str = string(strrep(str, "_approx.mat", ""));
str_parts = strsplit(str, p.Results.delimiter);

pdata.optimizer = str_parts(1);
tmp = regexp(str_parts(2), p.Results.focusing_expr, 'names');
pdata.focusing_level = str2double(tmp.focusing);
token = regexp(str, p.Results.x_expr, 'names');
if ~isempty(token)
    if strcmpi(token.unit, "mm")
        pdata.x = str2double(token.x);
    else % Then its in microns
        pdata.x = str2double(token.x)*1e-3;
    end
    pdata.pattern_units = token.unit;
end

token = regexp(str, p.Results.y_expr, 'names');
if ~isempty(token)
    if strcmpi(token.unit, "mm")
        pdata.y = str2double(token.y);
    else % Then its in microns
        pdata.y = str2double(token.y)*1e-3;
    end
    pdata.pattern_units = token.unit;
end

end