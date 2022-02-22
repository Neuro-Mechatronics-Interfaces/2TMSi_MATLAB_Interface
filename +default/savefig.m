function savefig(fig,filename,tag)
%SAVEFIG Default figure-saving behavior
%
%  default.savefig(fig); -> % figure with handle `fig` to "Untitled__.fig"
%
%  default.savefig('name'); % saves current figure to "name.fig"
%
%  default.savefig(fig,filename,tag);
%  -> default.savefig(fig,'figures/path','file1');
%
% Inputs
%  fig         - Figure handle
%  filename    - Name of output file (char array or string)
%  tag         - Bit to "tag" onto standard name set by filename (for
%                 convenience, by default this is empty)
%
% Output
%  - none -
%
% See also: Contents, savefig

switch nargin
   case 0
      error('Requires at least one input argument.');
   case 1
      if isa(fig,'matlab.ui.Figure')
         outPath = pwd;
         filename = sprintf('Untitled_%s',...
            char(datetime('now','Format','yyyy-MM-d_HHmmss')));
      else
         [outPath,filename] = parseName(fig);
         fig = gcf;
      end
   case 2
      if isa(fig,'matlab.ui.Figure')
         [outPath,filename,~] = fileparts(filename);
      else
         [outPath,filename] = parseName(fig,filename);
         fig = gcf;
      end
      
   case 3
      if ~isa(fig,'matlab.ui.Figure')
         error('Too many input arguments. With three args, first arg to default.savefig must be a figure handle.');
      end
      [outPath,filename] = parseName(filename,tag);
   otherwise
      error('Too many input arguments. default.savefig takes up to 3 args.');
end

outPath = strrep(outPath,"\","/");
F = dir(outPath);

if isempty(F) && ~isempty(outPath) && outPath~=""
   mkdir(outPath);
end

fname = fullfile(outPath,filename);
set(fig, 'Renderer', 'painters');
if isempty(fig.UserData) || isstruct(fig.UserData)
   fig.UserData = struct(...
       'VectorGraphicsExported', true, ...
       'VectorGraphicsName', fname, ...
       'VectorGraphicsExportFcn', @()default.savefig(fig, filename, tag) ...
       ); 
end
saveas(fig,fname,"fig");
saveas(fig,fname,"svg");
saveas(fig,fname,"png");
delete(fig);

% Helper function
   function [outPath,filename] = parseName(filename,tag)
      %PARSENAME Simple name parser for using `tag`
      %
      %  [outPath,filename] = parseName(filename);
      %  [outPath,filename] = parseName(filename,tag); % Both work
      %
      % See also: default.savefig
      
      [outPath,f,~] = fileparts(filename);
      
      if isempty(outPath) || outPath==""
         outPath = pwd;
      end
      
      if nargin < 2
         filename = f;
      else
         filename = strcat(f,"_",tag);
      end
   end
end