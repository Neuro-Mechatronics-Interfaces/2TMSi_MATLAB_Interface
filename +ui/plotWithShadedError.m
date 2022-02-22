function [h,lsig] = plotWithShadedError(x,y,err,varargin)
%PLOTWITHSHADEDERROR  Add shaded confidence bounds to data
%
%  h = ui.plotWithShadedError(x,data);
%  --> If no `y` is given, then extrapolate from `data` along with `err`
%  --> Uses `nanmean` and `nanstd` to compute mean and standard deviation
%        (see: math.mat2cb) 
%
%  h = ui.plotWithShadedError(x,y,err);
%  --> Can provide `err` directly as a matrix with either 2 rows or 2
%      columns, which indicate the lower and upper bounds at each
%      observation. Note: order does not matter for upper vs lower, as long
%      as it is the same for each sample.
%
%  h = ui.plotWithShadedError(ax,x,y,err);
%  --> First argument can always be an axes handle specifying which axes to
%        place the shaded error plot on
% 
%  h = ui.plotWithShadedError(ax,data);
%  --> Extrapolate `x`, `y`, and `err` from `data` assuming that columns 
%        are grouped variables (samples) and rows different time-series 
%        instants (observations).
%
%  h = ui.plotWithShadedError(ax,x,data);
%  --> Extrapolates `y`, `err` from `data` using size of `x`
%
%  h = ui.plotWithShadedError(x,y,err,'Name',value,...);
%  h = ui.plotWithShadedError(ax,x,y,err,'Name',value,...);
%  h = ui.plotWithShadedError(ax,x,data,'Name',value,...);
%  --> Any of the above syntaxes allow specification of parameters using
%        <'Name',value> input argument pair syntax.
%
%  [h,lsig] = ...
%  --> Additionally, return `lsig` object from `addSignificanceLine` (or
%        empty object if input format did not include full dataset for
%        comparison). Requires 'H0' parameter to be set.
%
%  -- OUTPUT --
%     h  :  'matlab.graphics.primitive.Group' object
%     --> Contains a line and a patch representing the "spread" along the 
%         plotted line of the data of interest.
%
% class(h.Children(1)) == 'matlab.graphics.chart.primitive.Line'
% class(h.Children(2)) == 'matlab.graphics.primitive.Patch'

% PARSE INPUT
if nargin < 2
   error(['ui:' mfilename ':TooFewInputs'],...
      ['\n\t->\t<strong>[ui.PLOTWITHSHADEDERROR]:</strong> ' ...
      'ui.plotWithShadedError requires at least 2 input arguments\n']);
end

if nargin == 2  % If only 2 inputs, depend on class of first arg
   pars = getParameters('ShadedErrorPlot');
   if isa(x,'matlab.graphics.axis.Axes')
      ax = x;
      x = 1:size(y,2);
   else % Otherwise, assume `x` and `y` supplied correctly: compute `err`
      ax = gca;
   end
   data = y;
   dim = abs(find(size(x) == size(data))-2)+1;
   if pars.UseMedian
      [~,~,~,y,err] = math.mat2cb(data,dim,pars.StandardDeviations);
   else
      [err,y] = math.mat2cb(data,dim,pars.StandardDeviations);
   end
end

if nargin == 3
   pars = getParameters('ShadedErrorPlot');
   if isa(x,'matlab.graphics.axis.Axes')
      ax = x;
      x = y;
      data = err;
      dim = abs(find(size(x) == size(data))-2)+1;
	  if pars.UseMedian
	     [~,~,~,y,err] = math.mat2cb(data,dim,pars.StandardDeviations);
	  else
         [err,y] = math.mat2cb(data,dim,pars.StandardDeviations);
	  end
   else
      ax = gca;
      data = [];
   end
end

% Parse whether AXES was given as one of the inputs
if nargin > 3
   
   if isa(x,'matlab.graphics.axis.Axes')
      ax = x;
      x = y;
      if ischar(varargin{1})
         data = err;
         pars = getParameters('ShadedErrorPlot',varargin{:});
         dim = abs(find(size(x) == size(data))-2)+1;
         if isempty(dim)
            data = data.';
            dim = abs(find(size(x) == size(data))-2)+1;
         end
         if isempty(dim) || (numel(dim)>1) || (max(dim) <= 0)
            h = [];
            lsig = [];
            return;
         end
		 if pars.UseMedian
		    [~,~,~,y,err] = math.mat2cb(data,dim,pars.StandardDeviations);
		 else
		   [err,y] = math.mat2cb(data,dim,pars.StandardDeviations);
		 end
      else
         y = err;
         err = varargin{1};
         varargin(1) = [];
         pars = getParameters('ShadedErrorPlot',varargin{:});
         data = [];
      end
   else
      pars = getParameters('ShadedErrorPlot',varargin{:});
      ax = gca;
      data = [];
   end
end
% Create output matlab.graphics.primitive.Group object
h = hggroup(ax,...
   'DisplayName',pars.DisplayName,...
   'Tag',pars.Tag,...
   'UserData',pars.UserData);

% Make PATCH X & Y coordinates from combination of y + error
if iscolumn(x)
   x = x.';
end
if iscolumn(y)
   y = y.'; % Get correct orientation
end
if (size(err,1) > 1) && (size(err,2) > 1)
   if (size(err,2) == 2)
      err = err.'; % Transpose
   end
   if err(1,1) > err(2,1)
      err = flipud(err); % "Lower" bounds are first row
   end
   
   ly = err(1,:);
   uy = err(2,:);
else
   err = reshape(err,1,numel(err));
   uy = y + err;
   ly = y - err;
end

pY = [uy, fliplr(ly), uy(1)];
pX = [x, fliplr(x), x(1)];

F = [1:numel(pY),1];
V = [pX.',pY.'];

sh = patch(ax,...
   'Faces',F,'Vertices',V,...
   'FaceColor',pars.FaceColor,...
   'FaceAlpha',pars.FaceAlpha,...
   'EdgeColor',pars.EdgeColor,...
   'Tag',pars.Tag,...
   'DisplayName',pars.DisplayName,...
   'Parent',h);
sh.Annotation.LegendInformation.IconDisplayStyle = 'off';

% Plot LINE
if isnan(pars.MarkerIndices)
   pars.MarkerIndices = 1:length(x);
end

l = line(gca,x,y,...
   'Marker',pars.Marker,...
   'MarkerIndices',pars.MarkerIndices,...
   'MarkerFaceColor',pars.MarkerFaceColor,...
   'MarkerEdgeColor',pars.MarkerEdgeColor,...
   'MarkerSize',pars.MarkerSize,...
   'LineWidth',pars.LineWidth,...
   'LineStyle',pars.LineStyle,...
   'Color',pars.Color,...
   'Tag',pars.Tag,...
   'DisplayName',pars.DisplayName,...
   'Parent',h);
l.Annotation.LegendInformation.IconDisplayStyle = 'on';
h.Annotation.LegendInformation.IconDisplayStyle = pars.Annotation;

% Add significance testing line (if applicable; otherwise return [] lsig)
if isempty(pars.H0) || isempty(data)
   lsig = [];
   return;
end

alpha = pars.SignificanceLine.Alpha;
sigPars = pars.SignificanceLine;
h0 = pars.H0;
lsig = ui.addSignificanceLine(ax,x,data,h0,alpha,sigPars);

% Helper methods
   function pars = getParameters(fname,varargin)
      %GETPARAMETERS  Helper function to parse parameters for this method
      %
      %  pars = getParameters(fname);
      %  >> pars = getParameters('ShadedErrorPlot');
      
      pars = ui.parameters(fname,varargin{:});
      pars.SignificanceLine.TestFcn = pars.TestFcn;
   end

end