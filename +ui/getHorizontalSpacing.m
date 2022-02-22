function [x,w] = getHorizontalSpacing(n,varargin)
%GETHORIZONTALSPACING   Get spacing in x-direction for array of graphics
%
%  x 	 = ui.getHorizontalSpacing(n);
%  x 	 = ui.getHorizontalSpacing(n,'NAME',value,...);
%  [x,w] = ui.getHorizontalSpacing(n,'NAME',value,...);
%
%  --------
%   INPUTS
%  --------
%     n     :     Number of elements in graphics array.
%
%  varargin :     (Optional) 'NAME', value input arguments.
%
%                 -> 'LEFT' [def: 0.025] // Offset from left border
%                 (normalized from 0 to 1 as fraction of object width)
%
%                 -> 'RIGHT' [def: 0.475] // Offset from right border
%                 (normalized from 0 to 1 as fraction of object width)
%
%                 -> 'XLIM' [def: NaN] // Coordinate limits
%                 (can be given as scalar, in which case lower lim is
%                 assumed to be zero. Otherwise, should be a two-element
%                 vector where the first is the lower bound and second is
%                 upper bound)
%
%  --------
%   OUTPUT
%  --------
%     x     :     Vector of scalar values normalized between 0 and 1 giving
%                 the first Position argument for Matlab graphics objects
%                 (x position).
%
%     w     :     Scalar singleton normalized between 0 and 1 giving
%                 corresponding 3rd Position argument for Matlab graphics
%                 objects (width).

% Parse inputs
pars = ui.parameters(varargin{:});
if strcmpi(pars.XLim,'auto')
   pars.XLim = pars.Position([1,3]);
end

if abs(pars.Left - 1) > 1
   error(['UI:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UI.GETHORIZONTALSPACING]:</strong> ' ...
         'pars.Left (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Left);
end

if abs(pars.Right - 1) > 1
   error(['UI:' mfilename ':ParameterOutOfBounds'],...
         ['\n\t\t->\t<strong>[UI.GETHORIZONTALSPACING]:</strong> ' ...
         'pars.Right (%7.4f) offset must be in the range [0, 1]\n'],...
         pars.Right);
end

% COMPUTE
if isscalar(pars.XLim) % Assume "bottom" is at origin ([~,0])
   if isnan(pars.XLim)
      right = 1;
   else
      right = pars.XLim;
   end
   left = 0; % Assume starts at origin
   wTotal = right / n; % Total width
   
else
   left = pars.XLim(1);
   right = pars.XLim(2);
   wTotal = diff(pars.XLim) / n;
end

% Compute left offset and right offset as fraction of "total" object width
leftOffset = wTotal * pars.Left;
rightOffset = wTotal * pars.Right;

% Width of each element must account for offset removed (for spacing)
w = wTotal - rightOffset - leftOffset; 

% Get x-coordinate of left edge for first and last element
switch pars.HorizontalAlignment
   case 'right'
      xLeft = left + leftOffset + w;
      xRight = right - rightOffset;
      x = xRight:-wTotal:xLeft;
      x = fliplr(x);
   otherwise
      xLeft = left + leftOffset;
      xRight = right - rightOffset - w;
      x = xLeft:wTotal:xRight; 
end

if numel(x) < n % If there will be clipping, notify user
   warning(['UI:' mfilename ':ExceedsBoundaries'],...
      ['\n\t\t->\t<strong>[UI.GETHORIZONTALSPACING]:</strong> ' ...
      'Requested %g elements, but only %g elements "fit".\n ' ...
      '\t\t\t->\t(Right-most %g element(s) will be clipped)\n'],n,numel(x),...
      n - numel(x));
   x = xLeft:wTotal:((n-1)*wTotal + xLeft);
end

end