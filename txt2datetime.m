function dt = txt2datetime(txt, varargin)
%TXT2DATETIME  Text-to-datetime utility for formatting in this repo.
%
% Syntax:
%   dt = txt2datetime(txt);
%   dt = txt2datetime(txt,'InputFormat',<value>,'OutputFormat',<value>);
%
% Example 1:
%   dt = txt2datetime({'2023-03-15_12:58:49.767', ...
%                      '2023-03-15_12:58:49.768'});
%   In this case, dt is a 1x2 array of datetimes separated by 
%       1-millisecond.
%
% Example 2:
%   dt = txt2datetime(["12:58:49.766", ...
%                      "12:58:49.769"], ...
%                     'InputFormat', "HH:MM:SS.FFF");
%   In this case, dt is a 2x1 array of datetimes separated by
%       3-milliseconds.
%
% Inputs:
%   txt - The date string like from a log field or whatever
%
% Output:
%   dt  - Datetime scalar or array of same size as input (unless it's a
%               single char array, then a scalar is returned).
%
% See also: Contents

p = inputParser();
p.addRequired('txt',@(in)(isstring(in)||ischar(in)||iscell(in)));
p.addParameter('InputFormat','yyyy-mm-dd_HH:MM:SS.FFF',@(in)(isstring(in)||ischar(in)));
p.addParameter('OutputFormat','uuuu-MM-dd_hh:mm:ss.SSS',@(in)(isstring(in)||ischar(in)));
p.parse(txt, varargin{:});

txt = string(txt);
fmt_in = p.Results.InputFormat;
fmt_out = p.Results.OutputFormat;

dt = datetime( datenum( datestr(txt,fmt_in), fmt_in), ...
            'ConvertFrom','datenum','Format',fmt_out);

end