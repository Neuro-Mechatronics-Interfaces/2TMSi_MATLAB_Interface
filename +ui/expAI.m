function [fig,outputname] = expAI(fig,filename,varargin)
%EXPAI  Export figure in appropriate format for Adobe Illustrator
%
%  fig = ui.expAI; % Grab current figure and export with default name
%  fig = ui.expAI(filename); % Grab current figure, export given name
%  fig = ui.expAI(fig);      % Export specific figure, default name
%  fig = ui.expAI(fig,filename); % Export specific figure, given name
%  fig = ui.expAI(fig,filename,pars); % Give parameters struct directly
%  fig = ui.expAI(fig,filename,'Name',value,...); % Modify specific pars
%  fig = ui.expAI(fig,filename,pars,'Name',value,...); % etc
%  [fig, outputname] = ...
%
%  -- Inputs --
%  fig : Handle to the figure you wish to export.
%
%  filename : String with output filename (and extension) of figure
%              to export for Adobe Illustrator.
%
%  varargin : Can pass directly as parameters struct output by 
%              >> pars = p__.defs.Exporting_To_IllustratorOptional;
%
%             + Uses <'Name', value> input argument pairs to modify fields
%                of that struct regardless of whether it is provided as an
%                input option.
%
%  -- Output --
%  fig : Handle to exported figure, with modifications.
%
%  outputname : (Optional) Full filename of exported figure.
%
%  Generates a vector graphics file for Adobe Illustrator or comparable
%  image manipulation software. Name of file is given by second output
%  (`outputname`).

% Parse first input
if nargin < 1
   fig = gcf;
   hasFileName = false;
elseif ischar(fig)
   hasFileName = true;
   if nargin > 1
      if isa(filename,'matlab.ui.Figure')
         ftmp = fig;
         fig = filename;
         filename = ftmp; clear ftmp;
      else
         varargin = [filename, varargin];
         filename = fig;
         fig = gcf;
      end
   else
      filename = fig;
      fig = gcf;
   end
elseif ~isa(fig,'matlab.ui.Figure')
   error(['ui:' mfilename ':BadClass'],...
      ['\n\t->\t<strong>[ui.EXPAI]:</strong> ' ...
       'Bad class for first input argument (''%s'').\n' ...
       '\t\t\t(Should be ''matlab.ui.Figure'' or ''char'')\n'],...
       class(fig));
end

% Parse parameters
pars = ui.parameters('Exporting_To_Illustrator',varargin{:});
set(fig, 'Renderer', 'painters', ...
    'PaperSize', pars.PaperSize, ...
    'PaperUnits', pars.PaperUnits, ...
    'PaperOrientation', pars.PaperOrientation, ...
    'PaperType', pars.PaperType);

% Parse second input
if nargin < 2
   if ~hasFileName
      % Put export in current directory
      filename = fullfile(pwd,pars.DefaultName);
   end
end

% Ensure filename has correct extension
[p,f,ext] = fileparts(filename);

% Make sure that it goes in current directory if no full path specified
if isempty(p)
   p = pwd;
end

% Make sure the extension matches the specified formatting
if (pars.AutoFormat.Filename) || isempty(ext)
   if strcmp(pars.FormatType, '-dtiffn')
      ext = '.tif';
   elseif strcmp(pars.FormatType, '-dpsc2')
      ext = '.ps';
   elseif strcmp(pars.FormatType, '-dsvg')
      ext = '.svg';
   elseif strcmp(pars.FormatType, '-dpdf')
      ext = '.pdf';
   elseif strcmp(pars.FormatType, '-depsc')
      ext = '.eps';
   else
      ext = '.ai';
   end
end
outputname = fullfile(p,[f ext]);

% Modify figure parameters
if pars.AutoFormat.Figure
   set(gcf, 'Renderer', pars.Renderer(2:end));
end

% Modify font parameters
if pars.AutoFormat.Font
   c = get(gcf, 'Children');
   for iC = 1:numel(c)
      if ~ismember(class(c(iC)),pars.ClassIgnoreList)
         set(c(iC),'FontName',pars.FontName);
         set(c(iC),'FontSize',pars.FontSize);
         if isa(c(iC),'matlab.graphics.axis.Axes') && pars.AutoFormat.Axes
            xl = get(c(iC),'XLabel');
            set(xl,'FontName',pars.FontName);
            yl = get(c(iC),'YLabel');
            set(yl,'FontName',pars.FontName);
            t = get(c(iC),'Title');
            set(t,'FontName',pars.FontName);
            set(t,'FontSize',pars.FontSize);
            set(c(iC),'LineWidth',max(c(iC).LineWidth,1));
         end
      end
   end
end

% OUTPUT CONVERTED FIGURE
test = ver;
idx = ismember({test.Name},'MATLAB');
if str2double(test(idx).Version) >= 9.7 % Matlab ver R2019b
   print(fig,          ...
         outputname,   ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer);
else
   if isempty(pars.Resize)
      print(pars.UIOpt,        ...
         pars.Resolution,   ...
         fig,          ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer,     ...
         outputname);
   else
      print(pars.UIOpt,        ...
         pars.Resolution,   ...
         fig,          ...
         pars.Resize,       ...
         pars.FormatType,   ...
         pars.FormatOpt{:},    ...
         pars.Renderer,     ...
         outputname);
   end
end

% Update UserData property of figure handle to flag that figure has been
% exported already for Vector Graphics, and associate the `outputname` with
% the actual figure as well.
if isempty(fig.UserData)
   fig.UserData = struct;
   fig.UserData.VectorGraphicsExported = true;
   fig.UserData.VectorGraphicsName = outputname;
   fig.UserData.VectorGraphicsExportFcn = @()ui.expAI(fig, outputname);
elseif isstruct(fig.UserData)
   fig.UserData.VectorGraphicsExported = true;
   fig.UserData.VectorGraphicsName = outputname;
   fig.UserData.VectorGraphicsExportFcn = @()ui.expAI(fig, outputname);
end

if nargout < 1
    [p, f, ~] = fileparts(outputname);
    saveas(fig,  fullfile(p, [f,'.png']));
    savefig(fig, fullfile(p, [f '.fig']));
    delete(fig);
end

end