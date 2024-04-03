function fig = init_cst_filter_viz(options)

arguments
    options.K = 0;
    options.N = 256;
    options.T = 0.005; % Sample period
    options.LambdaScale = 0.1; % How to scale lambda with each second
end


fig = uifigure('Name', 'CST Filter Stability', 'Color', 'w', ...
    'Position', [70, 100, 560, 840]);
L = uigridlayout(fig,[3 6], ...
    'ColumnWidth', {'1x', '1x','fit'}, ...
    'RowHeight', {'1x', '3x', '3x', '5x', '1x', '1x'}, ...
    'BackgroundColor', 'w');

scaling = options.LambdaScale * options.T; % There are T steps in a second, so each should increment towards the "per second lambda scaling" by this amount.

fig.UserData = struct;
fig.UserData.Variables.lambda = @(k)scaling + scaling*k;
fig.UserData.Variables.k = options.K;
fig.UserData.Variables.n = options.N;
fig.UserData.Variables.T = options.T; % Sample period, seconds
[fig.UserData.h,fig.UserData.w,fig.UserData.p] = compute_system(fig.UserData.Variables.lambda, fig.UserData.Variables.k, fig.UserData.Variables.T, fig.UserData.Variables.n);

fig.UserData.Mag.Axes = uiaxes(L,'FontName','Tahoma','NextPlot','add');
title(fig.UserData.Mag.Axes,"System Response Magnitude","FontName","Tahoma");
ylabel(fig.UserData.Mag.Axes,"||Y(s)|| (dB)", 'FontName','Tahoma');
xlabel(fig.UserData.Mag.Axes, "Frequency(rad/s)", 'FontName', 'Tahoma');
fig.UserData.Mag.Axes.Layout.Row = 2;
fig.UserData.Mag.Axes.Layout.Column = [1 3];

fig.UserData.Phase.Axes = uiaxes(L,'FontName','Tahoma','NextPlot','add','YLim',[-180, 180],'YTick',[-90, 0, 90]);
title(fig.UserData.Phase.Axes,"System Phase","FontName","Tahoma");
ylabel(fig.UserData.Phase.Axes,"Phase (degrees)", 'FontName','Tahoma');
xlabel(fig.UserData.Phase.Axes, "Frequency (deg/s)", 'FontName', 'Tahoma');
fig.UserData.Phase.Axes.Layout.Row = 3;
fig.UserData.Phase.Axes.Layout.Column = [1 3];

fig.UserData.Pole.Axes = uiaxes(L, 'FontName','Tahoma','NextPlot','add', ...
    'XLim', [-1.1, 3.1], 'YLim', [-1.1, 1.1], 'XAxisLocation', 'origin', 'YAxisLocation', 'origin', ...
    'XTick', [-0.5, 0.5, 1.5, 3], ...
    'YTick', [-0.5, 0.5], ...
    'XColor', 'k', 'YColor', 'k', 'Color', [0.9 0.4 0.1]);
fig.UserData.Pole.Axes.Layout.Row = 4;
fig.UserData.Pole.Axes.Layout.Column = [1 3];
title(fig.UserData.Pole.Axes,"System Pole Location","FontName","Tahoma");
theta = linspace(0, 2*pi, 360);
F = [1:360,1];
V = [cos(theta); sin(theta)]';
patch(fig.UserData.Pole.Axes,'Faces',F,'Vertices',V,'EdgeColor','k','LineWidth',1.5,'FaceColor',[0.1 0.3 0.9]);
text(fig.UserData.Pole.Axes,0,0,'Stable','FontName','Tahoma','FontWeight','bold','HorizontalAlignment','center');
text(fig.UserData.Pole.Axes,2,0.5,'Unstable','FontName','Tahoma','FontWeight','bold','HorizontalAlignment','center');

lab = uilabel(L, "Text", "k", 'FontName', 'Tahoma', 'FontSize', 12,'HorizontalAlignment','center');
lab.Layout.Row = 5;
lab.Layout.Column = 1;
fig.UserData.Edit.K = uislider(L, ...
    "Orientation","horizontal", ...
    "MajorTicks", 0:1e5:4e5, ...
    "MajorTickLabels", ["0s", "100s", "200s", "300s", "400s"], ...
    "Limits",[0, 4e5], ...
    "Value", fig.UserData.Variables.k, ...
    "Tag", "k", ...
    "ValueChangedFcn", @updateAndRecomputeSystem);
fig.UserData.Edit.K.Layout.Row = 6;
fig.UserData.Edit.K.Layout.Column = 1;

lab = uilabel(L, "Text", "N", 'FontName', 'Tahoma', 'FontSize', 12,'HorizontalAlignment','center');
lab.Layout.Row = 5;
lab.Layout.Column = 2;
fig.UserData.Edit.N = uieditfield(L,  'numeric','HorizontalAlignment','center', ...
    "FontName", 'Consolas', ...
    "LowerLimitInclusive","on", ...
    "Limits",[32, 2056], ...
    "RoundFractionalValues", "on", ...
    "Value", fig.UserData.Variables.n, ...
    "Tag", "n", ...
    "ValueChangedFcn", @updateAndRecomputeSystem);
fig.UserData.Edit.N.Layout.Row = 6;
fig.UserData.Edit.N.Layout.Column = 2;

lab = uilabel(L, "Text", "T", 'FontName', 'Tahoma', 'FontSize', 12,'HorizontalAlignment','center');
lab.Layout.Row = 5;
lab.Layout.Column = 3;
fig.UserData.Edit.T = uieditfield(L,  'numeric','HorizontalAlignment','center', ...
    "FontName", 'Consolas', ...
    "LowerLimitInclusive","on", ...
    "Limits",[1e-6, 1e3], ...
    "Value", fig.UserData.Variables.T, ...
    "Tag", "T", ...
    "ValueChangedFcn", @updateAndRecomputeSystem);
fig.UserData.Edit.T.Layout.Row = 6;
fig.UserData.Edit.T.Layout.Column = 3;

fig.UserData.Mag.Line = plot(fig.UserData.Mag.Axes, fig.UserData.w/pi, mag2db(abs(fig.UserData.h)), 'Color', 'k');
fig.UserData.Phase.Line = plot(fig.UserData.Phase.Axes, rad2deg(fig.UserData.w), angle(fig.UserData.h), 'Color', 'b');
fig.UserData.Pole.Scatter = scatter(fig.UserData.Pole.Axes, fig.UserData.p, 0,  ...
    'Color', 'k', 'Marker', 'x', 'MarkerEdgeColor','k', ...
    'LineWidth', 2, 'SizeData', 128);

fig.UserData.Title = uilabel(L, "Text", "CST Filter: λ = 0.1", 'FontName','Tahoma','HorizontalAlignment','center','FontSize',18,'FontWeight','bold');
fig.UserData.Title.Layout.Row = 1;
fig.UserData.Title.Layout.Column = [1 3];

    function [h,w,p] = compute_system(lambda, k, T, n)
        if nargin < 4
            n = 256;
        end
        A = exp(lambda(k)*T); 
        B = exp(lambda(k)*T)-1;
        C = 1;
        D = 0;
        sys = idss(A,B,C,D,'Ts',T);
        [b,a] = ss2tf(A,B,C,D);
        [h,w] = freqs(b,a,n);
        [p,~] = pzmap(sys);
    end

    function updateAndRecomputeSystem(src, ~)
        v = src.Parent.Parent.UserData.Variables;
        v.(src.Tag) = src.Value;
        [h,w,p] = compute_system(v.lambda, v.k, v.T, linspace(0, pi, v.n));
        set(src.Parent.Parent.UserData.Mag.Line, ...
            'XData', w/pi, 'YData', mag2db(abs(h)));
        set(src.Parent.Parent.UserData.Phase.Line, ...
            'XData', rad2deg(w), 'YData', angle(h));
        set(src.Parent.Parent.UserData.Pole.Scatter, ...
            'XData', p, 'YData', 0);
        set(src.Parent.Parent.UserData.Title, ...
            'Text', sprintf("CST Filter: λ = %07.4f", v.lambda(v.k)));
        
        src.Parent.Parent.UserData.Variables = v;
    end

end