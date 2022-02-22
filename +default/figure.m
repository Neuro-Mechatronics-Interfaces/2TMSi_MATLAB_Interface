function fig = figure(name,varargin)
%FIGURE Return default figure handle
%
%  fig = default.figure(); % -> To use 'Name',value keyword pairs, must
%                          %    provide a value for `name` (can specify as
%                          %    '' to use default)
%  fig = default.figure(name);
%  fig = default.figure(name,'Name',value,...);
%
% Inputs
%  name     - Name of figure ('Name' figure property)
%  varargin - 'Name',value keyword argument pairs for Matlab figure builtin
%                 
% Output
%  fig      - Formatted Matlab figure handle
%
% See also: Contents, matlab.ui.Figure

if (nargin < 1) || isempty(name) || name==""
   name = "Untitled Figure";
end

r = groot;
if size(r.MonitorPositions,1) > 1
   pos = [1.2  0.22  0.29  0.39];
else
   pos = [ 0.59  0.38  0.29  0.39];
end
pos(1:2) = pos(1:2) + randn(1,2).*0.0025; % Jitter figure position

fig = figure(...
   'Name',name,...
   'Units','Normalized',...
   'Position',pos,...
   'Color','w',...
   'PaperOrientation','portrait',...
   'PaperSize',[8.5 11],...
   'PaperUnits','inches',...
   varargin{:}); % Insert the rest as "Name",value keyword pairs

end