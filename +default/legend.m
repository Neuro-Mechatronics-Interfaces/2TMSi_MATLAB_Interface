function h = legend(varargin)
%LEGEND Return default Legend object handle
%
%  h = default.legend();
%  h = default.legend(ax,'Name',value,...);
%
% Inputs
%  Any inputs to standard 'legend' function. Just be sure to pass
%  'Name',value keyword pairs with char (not string) for the key.
%
%  See also: legend
%
% Output
%  h - Formatted legend object.
%
% See also: Contents, matlab.graphics.illustration.Legend

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

h = legend(varargin{:},...
   'TextColor','black',...
   'FontName','Arial',...
   'FontSize',12,...
   'EdgeColor','none',...
   optArgs{:});

end