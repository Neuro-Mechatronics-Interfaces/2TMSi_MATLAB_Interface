function fig = make_ui_figure(figure_name, tag, data, varargin)
%MAKE_UI_FIGURE - Return figure handle to UI figure with specific name, tag
%
% Syntax:
%   fig = make_ui_figure(figure_name);
%   fig = make_ui_figure(figure_name, tag);
%   fig = make_ui_figure(figuer_name, tag, data);
%   fig = make_ui_figure(figure_name, tag, data, {'Position', [0.2 0.2 0.4 0.4]});
%
% Inputs:
%   figure_name - String or character array input that is name on title bar
%   tag - Optional tag to add as "Tag" property for figure.
%   data - Optional data struct to add as "UserData" property for figure.
%   varargin - Optional {'Name', value} cell array pairs to add as extra
%               `figure` arguments.
if nargin < 2
    tag = ''; 
end
if nargin < 3
    data = struct; 
end
figure_name = string(figure_name);
if numel(figure_name) > 1
    fig = gobjects(size(figure_name));
    nRow = floor(sqrt(numel(figure_name)));
    nCol = ceil(numel(figure_name)/nRow);
    h = 1 / nRow;
    w = 1 / nCol;
    ii = 0;
    for iRow = 1:nRow
        for iCol = 1:nCol
            pos = [(iCol-1)*w, 1 - (iRow*h), w, h]; 
            ii = ii + 1;
            fig(ii) = make_ui_figure(figure_name(ii), tag, data, varargin{:}, ...
                'OuterPosition', pos);
            if ii == numel(figure_name)
                break; 
            end
        end
    end
    return;
end

fig = figure(...
    'Name', figure_name, ...
    'Color', 'w', ...
    'Units', 'Normalized', ...
    'OuterPosition', [0 0 1 1], ...
    'Tag', tag, ...
    'UserData', data, ...
    varargin{:});
end