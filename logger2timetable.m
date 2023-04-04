function data = logger2timetable(logger, varargin)
%LOGGER2TIMETABLE  Parse datetime from first part of "Text" table entry on each log row.
%
% Syntax:
%   data = logger2timetable(logger, 'Name',value,...);
%  
% Inputs:
%   logger - mlog.Logger object
%   varargin - Optional 'Name', value pairs:
%           'InputFormat' - Format for input date string
%           'OutputFormat' - Format for output datetime
%
% Output:
%   data - TimeTable with remaining data entries based on " :: " delimiters
%           Variables (columns) are named Var1, Var2, etc.
%
% See also: Contents, txt2datetime

p = inputParser();
p.addRequired('logger', @(in)isa(in, 'mlog.Logger'));
p.addParameter('InputFormat','yyyy-mm-dd_HH:MM:SS.FFF',@(in)(isstring(in)||ischar(in)));
p.addParameter('OutputFormat','uuuu-MM-dd_hh:mm:ss.SSS',@(in)(isstring(in)||ischar(in)));
p.addParameter('VariableNames', {}, @(in)(isstring(in) || iscell(in)));
p.parse(logger, varargin{:});

data = arrayfun(@(in)strsplit(in, " :: "), ...
            logger.MessageTable.Text, ...
            'UniformOutput', false);
txt = cellfun(@(C)C(1), data);
data = cellfun(@(C)cellstr(C(2:end)), data, 'UniformOutput', false);

dt = txt2datetime(txt, ...
    'InputFormat', p.Results.InputFormat, ...
    'OutputFormat', p.Results.OutputFormat);
data = table2timetable(cell2table(vertcat(data{:})), 'RowTimes', dt);
if ~isempty(p.Results.VariableNames)
    data.Properties.VariableNames = p.Results.VariableNames;
elseif size(data,2) == 2
    data.Properties.VariableNames = {'Type', 'Status'};
elseif size(data,2) > 2
    data.Properties.VariableNames(1:2) = {'Type', 'Status'};
end
end