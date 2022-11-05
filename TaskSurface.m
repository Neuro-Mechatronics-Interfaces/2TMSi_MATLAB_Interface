classdef TaskSurface < matlab.graphics.chartcontainer.ChartContainer
    % c = TaskSurface('X', X, 'Y', Y, 'Name', Value,...)
    %
    % Create a TaskSurface object that contains:
    %
    %   1 moving "cursor" circle patch
    %   1 "primary" target that appears first
    %   1 "secondary" target that appears after some arbitrary hold
    %       duration
    
    events
        enter_t1
        exit_t1
        enter_t2
        exit_t2
        enter_ring
        exit_ring
        enter_idle
        exit_idle
    end
    properties(Access = public)
        transitions struct % State transitions struct array
        In_Idle (1,1) logical = false
        In_T1 (1,1) logical = true
        In_T2 (1,1) logical = false
        In_Ring (1,1) logical = true
        Direction (1,1) double = 1 % 1 -> Center-Out | 0 -> Out-Center
        X (1,1) double = 0.00  % Cursor X-Center
        Y (1,1) double = 0.00  % Cursor Y-Center
        R (1,1) double = 0.15  % Cursor radius
        LineWidth (1,1) double = 3.0 % Line Width of target objects.
        XLim (1, 2) double = [-5.0 5.0] % Scaling to constrain x-axes "spatial" bounds (Volts)
        YLim (1, 2) double = [-5.0 5.0] % Scaling to constrain y-axes "spatial" bounds (Volts)
        Hidden (1,1) logical = false
    end
    properties(Transient,NonCopyable,Access = protected)
        C      (1,1) matlab.graphics.primitive.Patch    % Cursor patch object
        T1     (:,1) matlab.graphics.primitive.Patch    % Primary-target patch object
        T2     (:,1) matlab.graphics.primitive.Patch    % Secondary-target patch object
    end
    properties(GetAccess=public, SetAccess=protected)
        CursorColor (1, 3) double = [1.0 1.0 1.0] % Sets the color of the cursor
        T1FaceColor (:, 3) double = [0.0 0.0 0.0] % Sets color of T1 target fill area
        T1EdgeColor (:, 3) double = [1.0 1.0 1.0] % Sets color of T1 target perimeter
        T2FaceColor (:, 3) double = [0.0 0.0 0.0] % Sets color of T2 target fill area
        T2EdgeColor (:, 3) double = [1.0 1.0 1.0] % Sets color of T2 target perimeter
    end
    properties(Access = protected)
        AllParameters_ = {'alpha', 'cursor_size', 'cursor_color', 'n_pts', 'n_overshoots_allowed', 'outer_ring_radius', 'targets', 'target_size', 'target_edge_color', 'target_fill_color',  'x_lim', 'y_lim'};
        Alpha_ (1,1) double = 0.30;     % EMA Alpha (current sample weight)
        Beta_  (1,1) double = 0.70;     % EMA Beta (past samples weight)
        T1_    (:,4) double = [0.0, 0.0, 0.50, 1] % [Xc, Yc, R, Visible] for T1
        T2_    (:,4) double = [3.0, 0.0, 0.50, 0] % [Xc, Yc, R, Visible] for T2
        Outer_Ring_Radius_ (1,1) double = 3.0  % Radius of outer-ring
        Outer_Ring_Thetas_ (1,:) double = linspace(0, 7*pi/4, 8); % Angles for each outer target
        Outer_Ring_Target_ (1,1) double = 1     % Target index of outer target
        N_     (1,1) double = 180              % Number of points in Patch edges
        N_Overshoots_Allowed_ (1,1) double = 2 % Maximum number of allowed overshoots
        Theta_ (:,1) double = linspace(0, 2*pi, 180)' % Points used to compute Patch edges
        Node_ (1,1)
        PositionSubscriber_ (1,1)
        StatePublisher_ (1,1)
        ParameterSubscriber_ (1,1)
        ParameterRequester_ (1,1)
    end
    methods
        function self = TaskSurface(varargin)
            %TASKSURFACE  Constructor for TaskSurface chart object.
            if numel(varargin) == 0
                fig = uifigure();
                set(fig, 'HandleVisibility', 'on');
                L = tiledlayout(fig,5,8, 'Padding', 'tight');
                figure(fig);
                ax = nexttile(L, 1, [5, 7]);
                set(ax, 'Color', 'k', ...
                    'XColor', 'none', 'YColor', 'none', ...
                    'XLim', [-5 5], 'YLim', [-5 5]);
                axes(ax);
            else
                if isa(varargin{1}, 'matlab.ui.Figure')
                    fig = varargin{1};
                    set(fig, 'HandleVisibility', 'on');
                    L = tiledlayout(fig,5,8, 'Padding', 'tight');
                    figure(fig);
                    ax = nexttile(L, 1, [5, 7]);
                    set(ax, 'Color', 'k', ...
                        'XColor', 'none', 'YColor', 'none', ...
                        'XLim', [-5 5], 'YLim', [-5 5]);
                    varargin(1) = [];
                elseif isa(varargin{1}, 'matlab.graphics.axis.Axes')
                    g = varargin{1};
                    while ~isa(g, 'matlab.ui.Figure')
                        g = g.Parent;
                    end
                    fig = g;
                    set(fig, 'HandleVisibility', 'on');
                    L = tiledlayout(fig,5,8, 'Padding', 'tight');
                    figure(fig);
                    ax = nexttile(L, 1, [5, 7]);
                    set(ax, 'Color', 'k', ...
                        'XColor', 'none', 'YColor', 'none', ...
                        'XLim', [-5 5], 'YLim', [-5 5]);
                    varargin(1) = [];
                else
                    fig = uifigure();
                    set(fig, 'HandleVisibility', 'on');
                    L = tiledlayout(fig,5,8, 'Padding', 'tight');
                    figure(fig);
                    ax = nexttile(L, 1, [5, 7]);
                    set(ax, 'Color', 'k', ...
                        'XColor', 'none', 'YColor', 'none', ...
                        'XLim', [-5 5], 'YLim', [-5 5]);
                    axes(ax);
                end
            end
            self@matlab.graphics.chartcontainer.ChartContainer(varargin{:});
            set(fig,...
                'Name', 'Center-Out Task Surface', ...
                'Position', [240 240 960 720], ...
                'Icon', 'baseline_radio_button_unchecked_black_24dp.png', ...
                'Color', [0.65 0.65 0.65], ...
                'WindowKeyReleaseFcn', @(~,evt)self.handleKeyboardShortcuts(evt));
            self.resetROS2();
            pause(2); 
            self.getParameter(self.AllParameters_);
        end
        
        function delete(self)
            try %#ok<*TRYNC> 
                delete(self.Node_);
            end
            try
                delete(self.PositionSubscriber_);
            end
            try 
                delete(self.ParameterSubscriber_);
            end
            try
                delete(self.StatePublisher_);
            end
            try
                delete(self.ParameterRequester_);
            end
            try
                g = getAxes(self);
                while ~isa(g, 'matlab.ui.Figure')
                    g = g.Parent;
                end
                delete(g);
            end
        end

        function handleKeyboardShortcuts(self, evt)
            switch evt.Key
                case 'space'
                    if self.In_Idle
                        self.setIdle(0);
                        notify(self, "exit_idle");
                    else
                        self.setIdle(1);
                        notify(self, "enter_idle"); % NOTE: NOTIFY IS ONLY CALLED DIRECTLY FROM POINTS WHERE NOTIFY SHOULD HAPPEN (NOT SETIDLE)
                    end
                case 'escape'
                    fprintf(1,'%s::<strong>%s</strong>\n\n',...
                        string(datetime('now','TimeZone','local','Format','HH:mm:ss.SSS')), ...
                        "Center-Out task GUI closed (escape pressed).");
                    delete(self);
                case 'h'
                    disp("Press <strong>spacebar</strong> to pause/unpause the task.");
                    disp("Press <strong>escape</strong> to close the task.");
                otherwise
                    fprintf(1, '\t\t->\t<strong>%s</strong> button released.\n', evt.Key);
            end
        end

        function resetROS2(self)
            try %#ok<*TRYNC> 
                delete(self.Node_);
            end
            try
                delete(self.PositionSubscriber_);
            end
            try 
                delete(self.ParameterSubscriber_);
            end
            try
                delete(self.StatePublisher_);
            end
            try
                delete(self.ParameterRequester_);
            end
            setenv("ROS_DOMAIN_ID", "42");
            self.Node_ = ros2node("wrist"); % 
            self.PositionSubscriber_ = ros2subscriber(self.Node_, ... % ROS2 Node
                "wrist/pos", ... % Topic name
                @(msg)self.setPosition(msg.x, msg.y));
            self.StatePublisher_ = ros2publisher(self.Node_, ...
                "wrist/state", ...
                "lifecycle_msgs/State");
            self.ParameterRequester_ = ros2publisher(self.Node_, ...
                "wrist/preq", ...
                "std_msgs/String");
            self.ParameterSubscriber_ = ros2subscriber(self.Node_, ...
                "wrist/pres", ...
                @(msg)self.setParameter(msg.name, msg.value));
        end

        function setEMA(self, alpha)
            %SETEMA  Set exponential moving average filter parameters
            %
            % Syntax:
            %   self.setEMA(alpha);
            %
            % Inputs:
            %   alpha - scalar double [0 to 1] -- values closer to 1
            %           emphasize the most-recent samples while lower
            %           values will "extend" the smoothing using more
            %           values from the past.
            self.Alpha_ = alpha;
            self.Beta_ = 1 - alpha;
        end

        function setIdle(self, idle_state)
            %SETIDLE  Sets the "IDLE" state (1 -> "IDLE" | 0 -> "NOT IDLE")
            ax = getAxes(self);
            if idle_state == 1
                self.hideT2();
                self.hideT1();
                self.hideCursor();
                self.In_Idle = true;
                ax.Color = [0.35 0.35 0.35];
            else
                self.showT2();
                self.showT1();
                self.showCursor();
                self.In_Idle = false;
                ax.Color = [0.00 0.00 0.00];
            end
        end

        function getParameter(self, name)
            %GETPARAMETER Request a wrist/parameter from the ROS2 network
            if iscell(name)
                for ii = 1:numel(name)
                    self.getParameter(name{ii});
                end
                return;
            end
            parameterRequestMessage = ros2message(self.ParameterRequester_);
            parameterRequestMessage.data = name;
            send(self.ParameterRequester_, parameterRequestMessage);
        end

        function setParameter(self, name, value)
            %SETPARAMETER  Callback to update parameter(s) value(s). 
            %
            % Syntax:
            %   self.setParameter(name, value);
            %
            % Inputs:
            %   name - String or char array of parameter names to set.
            %               -> Can send as an array of strings, or cell
            %                   array of char arrays. In this case, `value`
            %                   input must be cell array of values or
            %                   struct array of rcl_interfaces/Parameter -
            %                   type structs (e.g. with .type field and
            %                   value fields like .double_value or
            %                   .double_array_value). 
            %   value - rcl_interfaces/Parameter - type struct, or the
            %           value directly which corresponds to `name`. See
            %           note in `name` input description regarding passing
            %           array of parameter names and values.
            %
            % See also: Contents
            name = string(name);
            if ~isstruct(value)
                if ~iscell(value)
                    value = {value};
                end
            end
            for ii = 1:numel(name)
                switch name(ii)
                    case "alpha"
                        if isstruct(value(ii))
                            x = value(ii).double_value;
                        else
                            x = value{ii};
                        end
                        self.setEMA(x);
                    case "cursor_color"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.CursorColor = x;
                    case "cursor_size"
                        if isstruct(value(ii))
                            x = value(ii).double_value;
                        else
                            x = value{ii};
                        end
                        self.R = x;
                    case "n_pts"
                        if isstruct(value(ii))
                            x = value(ii).double_value;
                        else
                            x = value{ii};
                        end
                        self.setN(x);
                    case "n_overshoots_allowed"
                        if isstruct(value(ii))
                            x = value(ii).double_value;
                        else
                            x = value{ii};
                        end
                        self.N_Overshoots_Allowed_ = x;
                    case "outer_ring_radius"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.Outer_Ring_Radius_ = x;
                    case "target_size"
                        if isstruct(value(ii))
                            x = value(ii).double_value;
                        else
                            x = value{ii};
                        end
                        self.T1_(:, 3) = x .* ones(size(self.T1_,1),1);
                        self.T2_(:, 3) = x .* ones(size(self.T2_,1),1);
                    case "target_edge_color"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.T1EdgeColor = repmat(x, size(self.T1_,1), 1);
                        self.T2EdgeColor = repmat(x, size(self.T2_,1), 1);
                    case "target_fill_color"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.T1FaceColor = repmat(x, size(self.T1_,1), 1);
                        self.T2FaceColor = repmat(x, size(self.T2_,1), 1);
                    case "targets"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.setOuterRingThetas(x);
                    case "x_lim"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.XLim = x;
                    case "y_lim"
                        if isstruct(value(ii))
                            x = value(ii).double_array_value;
                        else
                            x = value{ii};
                        end
                        self.YLim = x;
                    otherwise
                        warning("Unrecognized parameter response: %s", name(ii));
                end
            end
            self.update();
        end

        function setPosition(self, x, y)
            %SETPOSITION Set position of the cursor object.
            x = self.Alpha_ * x + self.Beta_ * self.X;
            y = self.Alpha_ * y + self.Beta_ * self.Y;
            self.X = x;
            self.Y = y;
            r = self.R;
            t1_d = (self.T1_(1,1) - x)^2 + (self.T1_(1,2) - y)^2;
            t1_r = self.T1_(1,3);
            if  t1_d > ((t1_r+r)^2)
                    self.In_T1 = false;
                    self.T1FaceColor(1,:) = [0.0 0.0 0.0];
                    notify(self, "exit_t1", event.EventData());
                
            elseif t1_d <= ((t1_r+r)^2)
                self.In_T1 = true;
                self.T1FaceColor(1,:) = self.T1EdgeColor(1,:).*0.75;
                notify(self, "enter_t1", event.EventData());
            end
            
            t2_d = ((self.T2_(1,1) - x)^2 + (self.T2_(1,2) - y)^2);
            t2_r = self.T2_(1,3);
            if t2_d > ((t2_r+r)^2)
                    self.In_T2 = false;
                    self.T2FaceColor(1,:) = [0.0 0.0 0.0];
                    notify(self, "exit_t2", event.EventData());
            elseif t2_d <= ((t2_r+r)^2)
                self.In_T2 = true;
                self.T2FaceColor(1,:) = self.T2EdgeColor(1,:).*0.75;
                notify(self, "enter_t2", event.EventData());
            end
            
            if self.In_Ring
                if t1_d > (self.Outer_Ring_Radius_ + r + t2_r)^2
                    self.In_Ring = false;
                    notify(self, "exit_ring", event.EventData());
                end
            elseif t1_d <= (self.Outer_Ring_Radius_ + r + t2_r)^2
                self.In_Ring = true;
                notify(self, "enter_ring", event.EventData());
            end

            self.update();
        end

        function setOuterRingThetas(self, thetas)
            %SETOUTERRINGTHETAS  Sets the possible angular positions for each target.
            self.Outer_Ring_Thetas_ = thetas;
            self.Outer_Ring_Target_ = min(numel(thetas), self.Outer_Ring_Target_);
        end

        function setOuterTargetIndex(self, index)
            %SETOUTERTARGETINDEX  Sets the index of the current target and uses the corresponding theta to compute its position for graphics update.
            self.Outer_Ring_Target_ = index;
            if self.Direction == 1
                self.T1_(1,1:2) = [0.0, 0.0];
                self.T2_(1,1:2) = [...
                    self.Outer_Ring_Radius_*cos(self.Outer_Ring_Thetas_(self.Outer_Ring_Target_)), ...
                    self.Outer_Ring_Radius_*sin(self.Outer_Ring_Thetas_(self.Outer_Ring_Target_)) ...
                    ];
            else
                self.T1_(1,1:2) = [...
                    self.Outer_Ring_Radius_*cos(self.Outer_Ring_Thetas_(self.Outer_Ring_Target_)), ...
                    self.Outer_Ring_Radius_*sin(self.Outer_Ring_Thetas_(self.Outer_Ring_Target_)) ...
                    ];
                self.T2_(1,1:2) = [0.0, 0.0];
            end
            self.update();
        end

        function showCursor(self)
            %SHOWCURSOR  Show the cursor object.
            self.Hidden = false;
            self.update();
        end

        function hideCursor(self)
            %HIDECURSOR  Hide the cursor object.
            self.Hidden = true;
            self.update();
        end

        function showT1(self, idx)
            %SHOWT1  Show all (or some) of the primary targets.
            %
            % Syntax:
            %   self.showT1(); % Shows all T1 targets
            %   self.showT1(idx); % Shows T1 targets indexed by idx.
            %
            % Inputs:
            %   idx - (Optional) if specified, give as numeric 1-indexed
            %           array indicating which T1 targets to show.
            if nargin < 2
                idx = 1:size(self.T1_,1);
            end
            self.T1_(idx, 4) = ones(size(idx));
            self.update();
        end

        function hideT1(self, idx)
            %HIDET1  Hide all (or some) of the primary targets.
            %
            % Syntax:
            %   self.hideT1(); % Hides all T1 targets
            %   self.hideT1(idx); % Hides T1 targets indexed by idx.
            %
            % Inputs:
            %   idx - (Optional) if specified, give as numeric 1-indexed
            %           array indicating which T1 targets to hide.
            if nargin < 2
                idx = 1:size(self.T1_,1);
            end
            self.T1_(idx, 4) = zeros(size(idx));
            self.update();

        end

        function showT2(self, idx)
            %SHOWT2  Show all (or some) of the primary targets.
            %
            % Syntax:
            %   self.showT2(); % Shows all T2 targets
            %   self.showT2(idx); % Shows T2 targets indexed by idx.
            %
            % Inputs:
            %   idx - (Optional) if specified, give as numeric 1-indexed
            %           array indicating which T2 targets to show.
            if nargin < 2
                idx = 1:size(self.T2_,1);
            end
            self.T2_(idx, 4) = ones(size(idx));
            self.update();
        end

        function hideT2(self, idx)
            %HIDET2  Hide all (or some) of the primary targets.
            %
            % Syntax:
            %   self.hideT2(); % Hides all T2 targets
            %   self.hideT2(idx); % Hides T2 targets indexed by idx.
            %
            % Inputs:
            %   idx - (Optional) if specified, give as numeric 1-indexed
            %           array indicating which T2 targets to hide.
            if nargin < 2
                idx = 1:size(self.T2_,1);
            end
            self.T2_(idx, 4) = zeros(size(idx));
            self.update();

        end

        % Set color for a given object type
        function setColor(self, objType, c)
            %SETCOLOR Set color for a given object type
            %   
            % Syntax:
            %   self.setColor(objType, c);
            %
            % Inputs:
            %   objType - Should be either 0, 1, or 2 (scalar numeric)
            %           0: Cursor
            %           1: T1
            %           2: T2
            %   c       - Can be as 1x3 double on range [0, 1], or it can
            %               be given as hex code string or array of strings
            %               for multiple objects (e.g. if you have multiple
            %               T2 targets you should have 1 for each target).
            c = validatecolor(c, 'multiple');
            switch objType
                case 0
                    self.CursorColor = c(1,:);
                case 1
                    self.T1EdgeColor = c;
                case 2
                    self.T2EdgeColor = c;
                otherwise
                    disp(objType);
                    error("Invalid value for objType in setColor. Should be element of [0, 1, 2] set.");
            end
            self.update();
        end

        % Set target data for a given target type
        function setTarget(self, t1_or_2, target_data)
            %SETTARGET Set target data for T1 or T2
            %
            % Syntax:
            %   self.setTarget(t1_or_2, target_data);
            %
            % Inputs:
            %   t1_or_2 - 1 (T1) or 2 (T2) | numeric scalar | which target type
            %   target_data - nTarget x 4 array [x1, y1, r1, v1; x2, y2, r2 v2; ...]
            %       Each row of target_data is the <x,y> position, radius, 
            %       and visibility (1 or 0) of another target of the given 
            %       target type. Most of the time this means it will be a 
            % %     1x4 array.
            if size(target_data,2) ~= 3
                error("The input target_data must be an nTarget x 3 array (dims are %d x %d).", ...
                    size(target_data,1), size(target_data,2));
            end
            ax = getAxes(self);

            if t1_or_2 == 1
                self.T1_ = target_data;
                t1 = self.T1;
                if size(target_data,1) < numel(t1)
                    for ii = size(target_data,1):numel(t1)
                        delete(self.T1(ii));
                    end
                    self.T1(size(target_data,1):numel(t1)) = [];
                elseif size(target_data, 1) > numel(t1)
                    for ii = numel(t1):size(target_data,1)
                        self.T1EdgeColor(ii,:) = [1.0 1.0 1.0];
                        self.T1FaceColor(ii,:) = [0.0 0.0 0.0];
                        self.T1(ii) = matlab.graphics.primitive.Patch(...
                            'Parent', ax, ...
                            'Faces', [1:self.N_, 1], ...
                            'LineWidth', self.LineWidth, ...
                            'Vertices', [self.T1_(ii,3).*cos(self.Theta_) + self.T1_(ii,1), self.T1_(ii,3).*sin(self.Theta_) + self.T1_(ii,2)], ...
                            'EdgeColor', self.T1EdgeColor(ii,:), ...
                            'FaceColor', self.T1FaceColor(ii,:), ...
                            'Visible', matlab.lang.OnOffSwitchState(self.T1_(ii,4)), ...
                            'Tag', sprintf('Circle.T1.%d', ii));
                    end
                    uistack(self.T1, "top");
                    uistack(self.C, "top");
                end
            else
                self.T2_ = target_data;
                t2 = self.T2;
                if size(target_data,1) < numel(t2)
                    for ii = size(target_data,1):numel(t2)
                        delete(self.T2(ii));
                    end
                    self.T2(size(target_data,1):numel(t2)) = [];
                elseif size(target_data,1) > numel(t2)
                    for ii = numel(t2):size(target_data,1)
                        self.T2EdgeColor(ii,:) = [1.0 1.0 1.0];
                        self.T2FaceColor(ii,:) = [0.0 0.0 0.0];
                        self.T2(ii) = matlab.graphics.primitive.Patch(...
                            'Parent', ax, ...
                            'Faces', [1:self.N_, 1], ...
                            'LineWidth', self.LineWidth, ...
                            'Vertices', [self.T2_(ii,3).*cos(self.Theta_) + self.T2_(ii,1), self.T2_(ii,3).*sin(self.Theta_) + self.T2_(ii,2)], ...
                            'EdgeColor', self.T2EdgeColor(ii,:), ...
                            'FaceColor', self.T2FaceColor(ii,:), ...
                            'Visible', matlab.lang.OnOffSwitchState(self.T2_(ii,4)), ...
                            'Tag', sprintf('Circle.T2.%d', ii));
                    end
                    uistack(self.T1, "top");
                    uistack(self.C, "top");
                end
            end
            self.update();
        end

        % Set number of points in the circle perimeters
        function setN(self, N_PTS)
            %SETN Set the number of points in shape boundaries
            ax = getAxes(self);
            self.N_ = N_PTS;
            self.Theta_ = linspace(0, 2*pi, N_PTS)';
            
            t2 = self.T2;
            for ii = 1:numel(size(self.T2_,1))
                self.T2(ii) = matlab.graphics.primitive.Patch(...
                    'Parent', ax, ...
                    'Faces', [1:self.N_, 1], ...
                    'LineWidth', self.LineWidth, ...
                    'Vertices', [self.T2_(ii,3).*cos(self.Theta_) + self.T2_(ii,1), self.T2_(ii,3).*sin(self.Theta_) + self.T2_(ii,2)], ...
                    'EdgeColor', self.T2EdgeColor(ii,:), ...
                    'FaceColor', self.T2FaceColor(ii,:), ...
                    'Visible', matlab.lang.OnOffSwitchState(self.T2_(ii,4)), ...
                    'Tag', sprintf('Circle.T2.%d', ii));
                delete(t2(ii));
            end

            for ii = (size(self.T2_,1)+1):numel(t2)
                delete(t2(ii));
            end
            
            t1 = self.T1;
            for ii = 1:size(self.T1_,1)
                self.T1(ii) = matlab.graphics.primitive.Patch(...
                    'Parent', ax, ...
                    'Faces', [1:self.N_, 1], ...
                    'LineWidth', self.LineWidth, ...
                    'Vertices', [self.T1_(ii,3).*cos(self.Theta_) + self.T1_(ii,1), self.T1_(ii,3).*sin(self.Theta_) + self.T1_(ii,2)], ...
                    'EdgeColor', self.T1EdgeColor(ii,:), ...
                    'FaceColor', self.T1FaceColor(ii,:), ...
                    'Visible', matlab.lang.OnOffSwitchState(self.T1_(ii,4)), ...
                    'Tag', sprintf('Circle.T1.%d', ii));
            end

            for ii = (size(self.T1_,1)+1):numel(t1)
                delete(t1(ii));
            end

            c = self.C;
            self.C = matlab.graphics.primitive.Patch(...
                'Parent', ax, ...
                'Faces', [1:self.N_, 1], ...
                'Vertices', [self.R.*cos(self.Theta_) + self.X, self.R.*sin(self.Theta_) + self.Y], ...
                'EdgeColor', 'none', ...
                'FaceColor', self.CursorColor, ...
                'Tag', 'Circle.Cursor');
            delete(c);
            
            uistack(self.T1, "top");
            uistack(self.C, "top");
        end

        % Set axes x-limits (horizontal voltage scaling)
        function setXLim(self, xl)
            %SETXLIM  Set x-limits
            self.XLim = xl;
            ax = getAxes(self);
            ax.XLim = xl;
            self.update();
        end

        % Set axes y-limits (vertical voltage scaling)
        function setYLim(self, yl)
            %SETYLIM  Set y-limits
            self.YLim = yl;
            ax = getAxes(self);
            ax.YLim = yl;
            self.update();
        end
    end

    methods(Access = protected)
        function setup(self)
            %SETUP  Setup the chart object just before showing it
            ax = getAxes(self);
            set(ax, ...
                'NextPlot', 'add', ...
                'XColor', 'none', ...
                'YColor', 'none', ...
                'Color', 'k', ...
                'XLim', self.XLim, ...
                'YLim', self.YLim, ...
                'Tag', 'TaskSurface.Axes');
            set(gcf, 'Name', 'Center-Out Task Surface', ...
                'Color', [0.65 0.65 0.65]);

            self.T2 = matlab.graphics.primitive.Patch(...
                'Parent', ax, ...
                'Faces', [1:self.N_, 1], ...
                'LineWidth', self.LineWidth, ...
                'Vertices', [self.T2_(1,3).*cos(self.Theta_) + self.T2_(1,1), self.T2_(1,3).*sin(self.Theta_) + self.T2_(1,2)], ...
                'EdgeColor', self.T2EdgeColor(1,:), ...
                'FaceColor', self.T2FaceColor(1,:), ...
                'Visible', matlab.lang.OnOffSwitchState(self.T2_(1,4)), ...
                'Tag', 'Circle.T2.1');
            self.T1 = matlab.graphics.primitive.Patch(...
                'Parent', ax, ...
                'Faces', [1:self.N_, 1], ...
                'LineWidth', self.LineWidth, ...
                'Vertices', [self.T1_(1,3).*cos(self.Theta_) + self.T1_(1,1), self.T1_(1,3).*sin(self.Theta_) + self.T1_(1,2)], ...
                'EdgeColor', self.T1EdgeColor(1,:), ...
                'FaceColor', self.T1FaceColor(1,:), ...
                'Visible', matlab.lang.OnOffSwitchState(self.T1_(1,4)), ...
                'Tag', 'Circle.T1.1');
            self.C = matlab.graphics.primitive.Patch(...
                'Parent', ax, ...
                'Faces', [1:self.N_, 1], ...
                'Vertices', [self.R.*cos(self.Theta_)+self.X, self.R.*sin(self.Theta_)+self.Y], ...
                'EdgeColor', 'none', ...
                'FaceColor', self.CursorColor, ...
                'Tag', 'Circle.Cursor');
            uistack(self.T1, "top");
            uistack(self.C, "top");
        end

        function update(self)
            %UPDATE  This happens anytime a TaskSurface property is updated by the user.
            cursor = self.C;
            set(cursor, ...
                'Vertices', [self.R.*cos(self.Theta_)+self.X, self.R.*sin(self.Theta_)+self.Y], ...
                'FaceColor', self.CursorColor, ...
                'Visible', matlab.lang.OnOffSwitchState(~self.Hidden));
            t1 = self.T1;
            for ii = 1:numel(t1)
                set(t1(ii), ...
                    'LineWidth', self.LineWidth, ...
                    'Vertices', [self.T1_(ii,3).*cos(self.Theta_) + self.T1_(ii,1), self.T1_(ii,3).*sin(self.Theta_) + self.T1_(ii,2)], ...
                    'EdgeColor', self.T1EdgeColor(ii,:), ...
                    'FaceColor', self.T1FaceColor(ii,:), ...
                    'Visible', matlab.lang.OnOffSwitchState(self.T1_(ii,4)));
            end
            t2 = self.T2;
            for ii = 1:numel(t2)
                set(t2(ii), ...
                    'LineWidth', self.LineWidth, ...
                    'Vertices', [self.T2_(ii,3).*cos(self.Theta_) + self.T2_(ii,1), self.T2_(ii,3).*sin(self.Theta_) + self.T2_(ii,2)], ...
                    'EdgeColor', self.T2EdgeColor(ii,:), ...
                    'FaceColor', self.T2FaceColor(ii,:), ...
                    'Visible', matlab.lang.OnOffSwitchState(self.T2_(ii,4)));
            end
        end
    end
end