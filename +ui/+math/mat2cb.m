function [cb,mu,sd,med,IQR] = mat2cb(data,dim,nSD)
%MAT2CB  Returns lower and upper limits on confidence bounds of data matrix
%
%  cb = math__.mat2cb(data);
%  --> data : Data matrix to return confidence bounds on
%  --> By default, operates along dim == 1 (treats columns as groups of
%      data points used to compute mean and standard deviation)
%  --> By default, computes bounds using nSD = 1 (mean +/- 1 standard
%        deviation).
%
%  cb = math__.mat2cb(data,dim,nSD);
%  --> `dim` : (optional) scalar dimension along which to operate
%  --> `nSD` : (optional) # of standard deviations
%
%  [cb,mu,sd,med,IQR] = math__.mat2cb(__);
%  --> Optionally, return mean 
%        * (mu; computed using nanmean)
%  --> Optionally, return standard deviation by sample 
%        * (sd; computed using nanstd)
%  --> Optionally, return median
%  --> Optionally, return inter-quartile range

if nargin < 2
   dim = 1;
else
   if dim > 2
      error(['MATH:' mfilename ':InvalidInput'],...
         ['\n\t->\t<strong>[MATH.MAT2CB]:</strong> ' ...
		 '`dim` must be 1 or 2']);
   end
end

if nargin < 3
   nSD = 1;
else
   nSD = nSD(1);
end

sd = nanstd(data,[],dim) .* nSD;
mu = nanmean(data,dim);
med = nanmedian(data,dim);
cb = cat(dim,mu-sd,mu+sd);

% n = size(data,dim);
% lb = max(round(0.025*n),1);
% ub = round(0.975*n);
% data = sort(data,dim,'ascend');
% if lb==ub
%    if dim == 1
%       cb95 = nan(2,size(data,2));
%    else
%       cb95 = nan(size(data,1),2);
%   end
%    return;
% end
% if dim == 1
%    cb95 = data([lb, ub],:);
% else
%    cb95 = data(:,[lb, ub]);
% end

IQR = iqr(data,dim);

end