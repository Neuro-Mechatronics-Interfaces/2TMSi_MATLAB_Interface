function h = patch(varargin)
%PATCH Returns patch with preferred default values
%
%  h = default.patch();
%  h = default.patch(ax,X,Y,...);
%  -> etc. See Matlab `patch` function for details.
%
% See also: Contents, matlab.graphics.primitive.Patch

[ax,args] = checkArgsForAxes(varargin{:});
DEFAULT_ARGS_LIST = { ...
   'DisplayName','',...
   'Tag',sprintf('Patch-%02d',numel(ax.Children)+1),...
   'FaceColor','#3d90e3', ...
   'EdgeColor','#0d559e', ...
   'LineWidth',1.5,...
   'FaceAlpha',0.6,...
   'EdgeAlpha',0.8 ...
};
DEFAULT_COLOR = [0 0 0];

if (numel(args) >= 3) && (isnumeric(args{1}) && isnumeric(args{2}) && isnumeric(args{3}))
   if numel(args{3}) == numel(args{2}) % Then it is 3-D      
      X = args{1};
      Y = args{2};
      Z = args{3};
      if (numel(args) >= 4)
         try
            C = validatecolor(args{4});
            h = patch(ax,...
               X,... % Vertex X coordinate (adjacent vertices are connected)
               Y,... % Vertex Y coordinate
               Z,... % Vertex Z coordinate
               C,... % Color data for 3-D patch
               DEFAULT_ARGS_LIST{1:4},... % Default arguments but no color ones
               args{5:end});
            return;
         catch
            C = DEFAULT_COLOR;
            args = args(4:end);
         end
      else
         C = DEFAULT_COLOR;
         args = {};
      end
      
      h = patch(ax,...
         X,... % Vertex X coordinate (adjacent vertices are connected)
         Y,... % Vertex Y coordinate
         Z,... % Vertex Z coordinate
         C,... % Color data for 3-D patch
         DEFAULT_ARGS_LIST{:},... % Default arguments but no color ones
         args{:});
      
   else % Otherwise it is 2-D
      X = args{1};
      Y = args{2};
      C = args{3};
      
      h = patch(ax,...
         X,... % Vertex X coordinate (adjacent vertices are connected)
         Y,... % Vertex Y coordinate
         C,... % Color data for 3-D patch
         DEFAULT_ARGS_LIST{1:4},... % Default arguments but no color ones
         args{4:end});
   end
elseif (numel(args) >= 2) && (isnumeric(args{1}) && isnumeric(args{2}))
   try
      C = validatecolor(args{3}); % If 2 args only, then this throws to error
      h = patch(ax,...
         args{1},... % Vertex X coordinate (adjacent vertices are connected)
         args{2},... % Vertex Y coordinate
         C,...
         DEFAULT_ARGS_LIST{1:4},...
         args{3:end});
   catch
      C = DEFAULT_COLOR;
      h = patch(ax,...
         args{1},... % Vertex X coordinate (adjacent vertices are connected)
         args{2},... % Vertex Y coordinate
         C,...
         DEFAULT_ARGS_LIST{:},...
         args{3:end});
   end
   
else % Set faces and vertices but overwrite if they are provided in args
   try
      C = validatecolor(args{1});
      h = patch(ax,...
         'Faces',nan,'Vertices',nan(1,2),...
         DEFAULT_ARGS_LIST{1:4},...
         'FaceColor',C,...
         args{2:end});
   catch
      h = patch(ax,...
         'Faces',nan,'Vertices',nan(1,2),...
         DEFAULT_ARGS_LIST{:},...
         args{:});
   end
end

   function [ax,remainingArgs] = checkArgsForAxes(varargin)
      %CHECKARGSFORAXES Check arguments list for axes object
      %
      %  [ax,remainingArgs] = checkArgsForAxes(varargin{:});
      
      idx = cellfun(@(C)isa(C,'matlab.graphics.axis.Axes'),varargin);
      if isempty(idx) || ~any(idx)
         ax = gca;
         remainingArgs = varargin;
         return;
      end
      ax = varargin{find(idx,1,'last')}; % Last argument overrides all
      varargin(idx) = []; % Remove axes arguments
      remainingArgs = varargin; % Assign output
   end
end