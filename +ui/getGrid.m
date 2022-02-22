function [x,y,w,h] = getGrid(nRow,nCol,varargin)
%GETGRID  Returns [x,y,w,h] graphics position vector for (nRow,nCol)
%
%  [x,y,w,h] = ui.getGrid(nRow);
%  * Returns coordinates assuming only 1 column
%
%  [x,y,w,h] = ui.getGrid([],nCol);
%  * Returns coordinates assuming only 1 row
%
%  [x,y,w,h] = ui.getGrid(nRow,nCol);
%  * Returns coordinates for nRow and nCol, assuming normalized units
%     spaced between [0, 1]
%
%  [x,y,w,h] = ui.getGrid(__,'NAME',value,...);
%  -- 'NAME' options --
%  --> 'Position' : (Normalized) coordinates of grid within parent container
%  --> 'Top' : (default: 0.025; offset normalized to derived grid height)
%  --> 'Bot' : (default: 0.025; offset normalized to derived grid height)
%  --> 'Left' : (default: 0.025; offset normalized to derived grid width)
%  --> 'Right' : (default: 0.025; offset normalized to derived grid width)
%
%  Outputs:
%  x : <MESHGRID MATRIX> X-coordinate of each grid element
%  y : <MESHGRID MATRIX> Y-coordinate of each grid element
%  w : <SCALAR> Width of each grid element
%  h : <SCALAR> Height of each grid element
%
%  <x(1,1), y(1,1)> coordinate pair denotes the position of the first grid
%  element; this will be at the "lower-left" corner of the full grid.

% Parse fixed arguments
if nargin < 2
   nCol = 1;
elseif isempty(nCol)
   nCol = 1;
elseif ischar(nCol)
   varargin = [nCol, varargin];
   nCol = 1;
end

if nargin < 1
   nRow = 1;
elseif isempty(nRow)
   nRow = 1;
end

% Parse variable arguments
pars = ui.parameters(varargin{:});

% Get spacing
[yVec,h] = ui.getVerticalSpacing(nRow,pars);
[xVec,w] = ui.getHorizontalSpacing(nCol,pars);

% Return meshgrid based on spacing vectors
[x,y] = meshgrid(xVec,yVec);
end