function ax = panelizeAxes(parent,nAxes,varargin)
%PANELIZEAXES Returns axes cell array, with panelized axes objects
%
%  ax = ui.panelizeAxes(nAxes);
%  ax = ui.panelizeAxes(parent,nAxes,'Name',value,...);
%  ax = ui.panelizeAxes(parent,nRow,nCol,'Name',value,...);
%
%  --------
%   INPUTS
%  --------
%   parent     :     Handle to container object to panelize (such as
%                    uipanel)
%
%    nAxes     :     Number of axes objects (scalar integer)
%
%	nRow, nCol :     Can be given in place of nAxes (scalar integers)
%
%  varargin    :     (Optional) 'NAME', value input argument pairs.
%
%  --------
%   OUTPUT
%  --------
%    ax        :     Graphics object array of axes object handles
%                    * Bottom-Left axes is ax(1,1)
%                    * Top-Right axes is ax(end,end)

% Parse input classes, number
if isnumeric(parent)
   varargin = [nAxes, varargin];
   nAxes = parent;
   parent = gcf;
end

if numel(varargin) >= 1
   if isnumeric(varargin{1})
      nRow = nAxes;
      nCol = varargin{1};
      nAxes = nRow * nCol;
      varargin(1) = [];
   else
      nRow = floor(sqrt(nAxes));
      nCol = ceil(nAxes/nRow);
   end
else
   nRow = floor(sqrt(nAxes));
   nCol = ceil(nAxes/nRow);
end

% Get default parameters
pars = ui.parameters(varargin{:});

% Based on input dimensions, get grid for [x,y,w,h] coordinates
[x,y,w,h] = ui.getGrid(nRow,nCol,pars);

% Build axes array
ax = gobjects(nRow,nCol);
for iRow = 1:nRow
   for iCol = 1:nCol
      pos = [x(iRow,iCol) y(iRow,iCol) w h];
      ax(iRow,iCol) = axes(...
		parent,...
        pars.Axes{:},...
        'Position',pos,...
        'UserData',[iRow iCol]);
   end
end
ax = flipud(ax);
if nAxes < numel(ax)
   delete(ax((nAxes+1):end));
end

end