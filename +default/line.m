function h = line(x,y,varargin)
%LINE Returns default line primitive object handle
%
%  h = default.line(h); % -> Can format line directly (but should only give
%                       %     one input argument for this to work.
%  h = default.line(x,y);
%  h = default.line(ax,x,y,'Name',value,...);
%
% Inputs
%  x - Line x-values
%  y - Line y-values. Should have same number elements as `x`
%
% Output
%  h - Graphics line object
%
% See also: Contents, matlab.graphics.primitive.Line

switch nargin
   case 0
      ax = default.axes();
      x = nan(1,2);
      y = nan(1,2);
   case 1
      if isa(x,'matlab.graphics.primitive.Line')
         h = x;
         ax = h.Parent;
         set(h,'LineWidth',1.5,'Color','k','LineStyle','-',...
            'DisplayName',inputname(1),...
            'Tag',sprintf('Line-%02d',numel(ax.Children)));
         return;
      end
      
      if isa(x,'matlab.graphics.axis.Axes')
         ax = x;
         x = nan(1,2);
         y = nan(1,2);
      else
         ax = gca;
      end
      
      if isnumeric(x)
         sz = size(x);
         iShort = find(sz <= 2,1,'first');
         if isempty(iShort)
            error('Must provide data as array if only giving single input (i.e. 2 columns or 2 rows of numeric values for <x,y> pairs)');
         end
         if sz(iShort)==2
            switch iShort
               case 1 % Then data given as rows
                  y = x(2,:);
                  x = x(1,:);
               case 2 % Then data given as columns
                  y = x(:,2);
                  x = x(:,1);
               otherwise
                  error('Invalid size of input data ([%d %d]). Check dimensions.',sz);

            end            
         end
      else
         error('Invalid data type for input: did not expect %s',class(x));
      end
   case 2
      if isa(x,'matlab.graphics.axis.Axes')
         ax = x;
         x = y;
         if isnumeric(x)
            sz = size(x);
            iShort = find(sz == 2,1,'first');
            if isempty(iShort)
               error('Must provide data as array if only giving single input (i.e. 2 columns or 2 rows of numeric values for <x,y> pairs)');
            end
            switch iShort
               case 1 % Then data given as rows
                  y = x(2,:);
                  x = x(1,:);
               case 2 % Then data given as columns
                  y = x(:,2);
                  x = x(:,1);
               otherwise
                  error('Invalid size of input data ([%d %d]). Check dimensions.',sz);

            end            

         else
            error('Invalid data type for input: did not expect %s',class(x));
         end
         
      else
         ax = gca;
         if isnumeric(x)
            sz = size(x);
            iShort = find(sz <= 2,1,'first');
            if isempty(iShort)
               error('Must provide data as array if only giving single input (i.e. 2 columns or 2 rows of numeric values for <x,y> pairs)');
            end
            if sz(iShort)==2
               switch iShort
                  case 1 % Then data given as rows
                     varargin = [y, varargin];
                     y = x(2,:);
                     x = x(1,:);
                     
                  case 2 % Then data given as columns
                     varargin = [y, varargin];
                     y = x(:,2);
                     x = x(:,1);
                     
                  otherwise
                     error('Invalid size of input data ([%d %d]). Check dimensions.',sz);

               end            
            end
         else
            error('Invalid data type for input: did not expect %s',class(x));
         end
      end
   otherwise
      if isa(x,'matlab.graphics.axis.Axes')
         ax = x;
         x = y;
         y = varargin{1};
         varargin(1) = [];
         if isnumeric(x)
            sz = size(x);
            iShort = find(sz <= 2,1,'first');
            if isempty(iShort)
               error('Must provide data as array if only giving single input (i.e. 2 columns or 2 rows of numeric values for <x,y> pairs)');
            end
            if sz(iShort)==2
               switch iShort
                  case 1 % Then data given as rows
                     varargin = [y, varargin];
                     y = x(2,:);
                     x = x(1,:);
                     
                  case 2 % Then data given as columns
                     varargin = [y, varargin];
                     y = x(:,2);
                     x = x(:,1);
                     
                  otherwise
                     error('Invalid size of input data ([%d %d]). Check dimensions.',sz);

               end            
            end
         else
            error('Invalid data type for input: did not expect %s',class(x));
         end
      else
         ax = gca;
         if isnumeric(x)
            sz = size(x);
            iShort = find(sz <= 2,1,'first');
            if isempty(iShort)
               error('Must provide data as array if only giving single input (i.e. 2 columns or 2 rows of numeric values for <x,y> pairs)');
            end
            if sz(iShort)==2
               switch iShort
                  case 1 % Then data given as rows
                     varargin = [y, varargin];
                     y = x(2,:);
                     x = x(1,:);
                     
                  case 2 % Then data given as columns
                     varargin = [y, varargin];
                     y = x(:,2);
                     x = x(:,1);
                     
                  otherwise
                     error('Invalid size of input data ([%d %d]). Check dimensions.',sz);

               end            
            end
         else
            error('Invalid data type for input: did not expect %s',class(x));
         end
      end
end

h = line(...
   ax,x,y,...
   'LineWidth',1.5,...
   'Color','k',...
   'LineStyle','-',...
   'DisplayName','',...
   'Tag',sprintf('Line-%02d',numel(ax.Children)+1),...
   varargin{:});

end