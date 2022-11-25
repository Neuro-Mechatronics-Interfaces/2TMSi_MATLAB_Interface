classdef HandleProperty < dynamicprops
    %HANDLEPROPERTY  Creates a handle with dynamic properties

    methods
        function self = HandleProperty(varargin)
            for iV = 1:2:numel(varargin)
                self.addprop(varargin{iV});
                self.(varargin{iV}) = varargin{iV+1};
            end
        end
    end
end