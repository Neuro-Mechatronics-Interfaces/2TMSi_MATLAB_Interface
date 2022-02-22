function [h,Yc,Xc] = plotCDF(ax,Y,X,varargin)
%PLOTCDF  Plots cumulative distribution function (CDF) for data in `Y`
%
%  ui.plotCDF(ax,Y,X);
%  [h,Yc,Xc] = ui.plotCDF(ax,Y,X,'Name',value,...);
%
% Inputs
%  ax - Target axes
%  Y  - Vector of values for generating CDF.
%  X  - Vector of "thresholds" for discrete CDF levels: the value
%        plotted for each value of X is the total number of values in the
%        distribution that meet or exceed that element.
%
%  varargin - (optional) 'Name',value keyword pairs corresponding to the
%                          `line` 'Name',value optional parameter pairs.
%                          Other optional parameters include:
%                          * 'Comparator' : (def: 'le')
%
% Output
%  h   - Handle to line object
%  Yc  - Values plotted on y-axis for points in CDF "line" plot.
%  Xc  - Values plotted on x-axis for points in CDF "line" plot.
%
%  ----------
%   Examples
%  ----------
%  [h,Yc,Xc] = ui.plotCDF(gca,randn(1000,1),linspace(-4,4,100));
%  ui.plotCDF(gca,randn(1000,1),linspace(-4,4,100),'Comparator','ge');
%  [h,Yc,Xc] = ui.plotCDF(gca,randn(1000,1),linspace(-4,4,100),...
%                 'LineWidth',2,'Color','k');
%
% See also: cdf, line, le, ge

pars = struct;
pars.Comparator = 'le';

fn = fieldnames(pars);
iRemove = [];
for iV = 1:2:numel(varargin)
   idx = strcmpi(fn,varargin{iV});
   if sum(idx)==1
      pars.(fn{idx}) = varargin{iV+1};
      iRemove = [iV, iV+1];
   end
end
varargin(iRemove) = []; % Removes non-"line"-related varargin elements

Xc = sort(X,'ascend');
Yc = zeros(size(Xc));
for ii = 1:numel(Xc)
   Yc(ii) = sum(feval(pars.Comparator,Y,Xc(ii)));
end

h = line(ax,Xc,Yc,varargin{:});

end