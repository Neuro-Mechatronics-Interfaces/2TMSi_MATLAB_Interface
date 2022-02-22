% +DEFAULT Package to return default versions of objects I like
%     Each function should be named after a Matlab built-in. Since they do
%     not allow superclassing of a lot of the built-in graphics objects,
%     this seems it may be the easiest way to achieve the same end.
%
%
% Methods (I/O)
%   savefig                   - Default figure-saving behavior
%
% Containers
%   axes                      - Return default axes object handle
%   figure                    - Return default figure handle
%
% Graphics Objects
%   bar                       - Returns bar with preferred default values
%   histogram                 - Return default histogram object for given axes and data
%   legend                    - Return default Legend object handle
%   line                      - Returns default line primitive object handle
%   patch                     - Returns patch with preferred default values