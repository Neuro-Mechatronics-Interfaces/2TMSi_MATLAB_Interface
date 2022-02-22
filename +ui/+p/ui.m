function varargout = ui(varargin)
%UI Parameters for functions in `+ui` package
%
%  pars = ui.pars.ui();
%  [var1,var2,...] = ui.p.ui('var1Name','var2Name',...);

pars = struct;

pars.Top = 0.15; % Offset from TOP border ([0 1])
pars.Bot = 0.30; % Offset from BOTTOM border ([0 1])
pars.Left = 0.225;  % Offset from LEFT border ([0 1])
pars.Right = 0.15; % Offset from RIGHT border ([0 1])
pars.HorizontalAlignment = 'left';
pars.VerticalAlignment = 'bottom';
pars.Position = [0 0 1 1];
pars.XLim = 'auto';
pars.YLim = 'auto';
% Axes parameter <'Name',value> pairs (used as pars.Axes{:})
pars.Axes = {...
   'FontName','Arial',...
   'FontSize',12,...
   'NextPlot','add',...
   'Color','w',...
   'XColor','k',...
   'YColor','k',...
   'LineWidth',1,...
   'Units','Normalized'...
   };

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