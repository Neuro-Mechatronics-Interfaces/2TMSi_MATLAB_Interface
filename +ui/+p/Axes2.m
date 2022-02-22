function varargout = Axes2(varargin)
%AXES2  Parameters for 2D axes labeling, etc.
%
%  pars = defs.Axes2();
%  [var1,var2,...] = defs.Axes2('var1Name','var2Name',...);

pars.LINE_WIDTH = 1;
pars.TITLE_FONT = 'Arial';   
pars.TITLE_SIZE = 16;         
pars.TITLE_COLOR = 'k';
pars.TITLE_WEIGHT = 'bold';
pars.XCOLOR = 'k';
pars.XDIR = 'normal';   % 'normal' or 'reverse'
pars.XLIM = 'auto';
pars.XLABEL_FONT = 'Arial';
pars.XLABEL_SIZE = 14;
pars.XLABEL_WEIGHT = 'normal';
pars.XSCALE = 'linear'; % 'linear' or 'log'
pars.XTICK = 'auto';
pars.XTICKLAB = 'auto';
pars.YCOLOR = 'k';
pars.YDIR = 'normal';   % 'normal' or 'reverse'
pars.YLIM = 'auto';
pars.YLABEL_FONT = 'Arial';
pars.YLABEL_SIZE = 14;
pars.YLABEL_WEIGHT = 'normal';
pars.YSCALE = 'linear'; % 'linear' or 'log'
pars.YTICK = 'auto';
pars.YTICKLAB = 'auto';

if nargin < 1
   varargout = {pars};   
else
   F = fieldnames(pars);   
   if (nargout == 1) && (numel(varargin) > 1)
      varargout{1} = struct;
      for iV = 1:numel(varargin)
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{1}.(F{idx}) = pars.(F{idx});
         end
      end
   elseif nargout > 0
      varargout = cell(1,nargout);
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx)==1
            varargout{iV} = pars.(F{idx});
         end
      end
   else
      for iV = 1:nargin
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(pars.(F{idx}));
         end
      end
   end
end

end