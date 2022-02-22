function t = now(varargin)
%NOW  Return datetime for current time with preferred formatting.
t = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss.SSS', varargin{:});

end