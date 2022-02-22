function varargout = ShadedErrorPlot(varargin)
%SHADEDERRORPLOT  Parameters associated with `gfx.ShadedErrorPlot`
%
%  pars = defs.ShadedErrorPlot();
%  [var1,var2,...] = defs.ShadedErrorPlot('var1Name','var2Name',...);

pars = struct;

% Numeric parameter defaults for error plot
pars.StandardDeviations = 1;
pars.H0 = []; % Can be set to do hypothesis test using addSignificanceLine
pars.TestFcn = @ttest2; % e.g. @ttest2 | @signrank | @ranksum

% Parameters for 'matlab.graphics.primitive.Line' properties
pars.DisplayName = '';
pars.Tag = '';
pars.UserData = [];
pars.FaceColor = [0.66 0.66 0.66];
pars.EdgeColor = 'none';
pars.Marker = 'none';
pars.MarkerEdgeColor = 'none';
pars.MarkerFaceColor = 'none';
pars.MarkerIndices = nan;
pars.MarkerSize = 6;
pars.LineWidth = 1.25;
pars.LineStyle = '-';
pars.Color = 'k';
pars.Annotation = 'off';
pars.UseMedian = false;
% Parameters for 'matlab.graphics.primitive.Patch' properties
pars.FaceAlpha = 0.5;

% Also holds struct for SignificanceLine parameters
pars.SignificanceLine = p__.defs.SignificanceLine();

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
      for iV = 1:nargout
         idx = strcmpi(F,varargin{iV});
         if sum(idx) == 1
            fprintf('<strong>%s</strong>:',F{idx});
            disp(pars.(F{idx}));
         end
      end
   end
end
end