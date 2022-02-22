function h = bar(varargin)
%BAR Returns bar with preferred default values
%
%  h = default.bar();
%  h = default.bar(ax,'Name',value,...);
%  h = default.bar(ax,x,y,1,'Name',value,...);
%
% See standard syntax from matlab.graphics.chart.primitive.Bar, just be
%  sure to specify 'Name' keys as char, not string.
%
% See also: Contents, bar

optArgs = {};
iArg = 1;
while iArg <= numel(varargin) % Since varargin will shrink, don't use nargin
   if ischar(varargin{iArg})
      optArgs = [varargin(iArg:(iArg+1)), optArgs]; %#ok<AGROW>
      varargin(iArg:(iArg+1)) = []; % Remove from list. Then go to next.
   else
      iArg = iArg + 1; % Only increment by 1 in case of weird input cases
   end
end

h = bar(varargin{:},...
   'BarWidth',1,...
   'FaceColor','#00b359',...
   'FaceAlpha',0.6,...
   'EdgeColor','#008040',...
   'EdgeAlpha',0.8,...
   'LineWidth',1.25,...
   'Tag',sprintf('Bar-%02d',numel(get(gca,'Children'))+1),...
   optArgs{:});


end