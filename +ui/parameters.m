function pars = parameters(name, varargin)
%PARAMETERS Returns parsed default parameters struct.
%
%   p = ui.parameters(name, varargin);
%
% Inputs
%   name - Name of the file (without '.m') from `+p` parameters sub-package
%   varargin - Optional 'Name', value parameter pairs to override defaults
%
% Output
%   p - Parameters struct with defaults and updated values.

if nargin < 1
    name = 'ui';
elseif iscell(name)
    varargin = name;
    name = 'ui';
end

pars = ui.p.(name);
f = fieldnames(pars);
for iV = 1:2:numel(varargin)
   idx = strcmpi(f, varargin{iV});
   if sum(idx)==1
      pars.(f{idx}) = varargin{iV+1}; 
   end
end

end