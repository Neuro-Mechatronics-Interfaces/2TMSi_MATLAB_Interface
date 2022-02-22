function h = histogram(ax,x,varargin)
%HISTOGRAM Return default histogram object for given axes and data
%
%  h = default.histogram(x); % -> Sets ax using `default.axes()`
%  h = default.histogram(ax,x);
%  h = default.histogram(ax,x,'Name',value,...);
%
% Inputs
%  name     - Name of figure ('Name' figure property)
%  varargin - 'Name',value keyword argument pairs for Matlab axes builtin
%                 
% Output
%  h        - Formatted Matlab histogram primitive chart object handle
%
% See also: Contents, matlab.graphics.chart.primitive.Histogram

switch nargin
   case 0
      ax = default.axes();
      x  = nan(1,2);
      name = 'Untitled';
   case 1
      if isa(ax,'matlab.graphics.axis.Axes')
         x = nan(1,2);
         name = ax.Tag;
      elseif isa(ax,'char') || isa(ax,'string')
         varargin = [ax, varargin];
         ax = default.axes();
         x = nan(1,2);
         name = 'Untitled';
      else
         x = ax;
         ax = default.axes();
         name = inputname(1);
      end
   otherwise
      if isa(ax,'matlab.graphics.axis.Axes')
         if ~isnumeric(x)
            varargin = [x, varargin];
            x = nan(1,2);
            name = 'Untitled';
         else
            name = inputname(2);
         end
      elseif isa(ax,'char') || isa(ax,'string')
         varargin = [ax, x, varargin];
         ax = default.axes();
         x = nan(1,2);
         name = 'Untitled';
      else
         varargin = [x, varargin];
         x = ax;
         ax = gca;
         name = inputname(1);
      end
end

h = histogram(ax,x,...
   'Tag',sprintf('Histogram-%02d',numel(ax.Children)+1),...
   'DisplayName',name,...
   'FaceColor','#444',...
   'EdgeColor','#666',...
   'FaceAlpha',0.6,...
   'EdgeAlpha',0.8,...
   varargin{:});


end