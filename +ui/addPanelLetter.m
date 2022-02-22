function h = addPanelLetter(ax, panel_letter, varargin)
%ADDPANELLETTER Adds panel letter with default settings to top left of axes
%
% Syntax:
%   h = addPanelLetter(ax, panel_letter, 'Name', value,...);
%
% Inputs
%   ax - Axes handle
%   panel_letter - (string or char) Letter or name of panel
%   varargin - (Optional) 'Name', value pairs, see `subtitle` built-in
%
% Output
%   h - Handle to the text object that is created
%
% See Also: Contents, subtitle

h = subtitle(ax, panel_letter, ...
    'HorizontalAlignment', 'left', ...
    'Units', 'Normalized', 'Position', [0, 1.012 0], ...
    'FontName', 'Arial', 'Color', 'k', ...
    'FontSize', 14, 'FontWeight', 'bold', varargin{:});

end