function fig = init_ema_filter_viz(options)

arguments
    options.alpha = 0;
    options.N = 256;
    options.T = 0.005; % Sample period
    options.LambdaScale = 0.1; % How to scale lambda with each second
end


fig = uifigure('Name', 'EMA Filter', 'Color', 'w', ...
    'Position', [70, 100, 560, 840]);
L = uigridlayout(fig,[3 6], ...
    'ColumnWidth', {'1x', '1x','fit'}, ...
    'RowHeight', {'1x', '3x', '3x', '5x', '1x', '1x'}, ...
    'BackgroundColor', 'w');

fig.UserData = struct;
fig.UserData.Variables.alpha = options.alpha;
fig.UserData.Variables.n = options.N;
fig.UserData.Variables.T = options.T; % Sample period, seconds
[fig.UserData.h,fig.UserData.w,fig.UserData.p] = compute_system(fig.UserData.Variables.alpha, fig.UserData.Variables.T, fig.UserData.Variables.n);

fig.UserData.Mag.Axes = uiaxes(L,'FontName','Tahoma','NextPlot','add','XLim',[0, 0.5/fig.UserData.Variables.T]);
title(fig.UserData.Mag.Axes,"System Response Magnitude","FontName","Tahoma");
ylabel(fig.UserData.Mag.Axes,"||Y(s)|| (dB)", 'FontName','Tahoma');
xlabel(fig.UserData.Mag.Axes, "Frequency (Hz)", 'FontName', 'Tahoma');
fig.UserData.Mag.Axes.Layout.Row = 2;
fig.UserData.Mag.Axes.Layout.Column = [1 3];

fig.UserData.Phase.Axes = uiaxes(L,'FontName','Tahoma','NextPlot','add','YLim',[-180, 180],'YTick',[-90, 0, 90]);
title(fig.UserData.Phase.Axes,"System Phase","FontName","Tahoma");
ylabel(fig.UserData.Phase.Axes,"Phase (degrees)", 'FontName','Tahoma');
xlabel(fig.UserData.Phase.Axes, "Frequency (Hz)", 'FontName', 'Tahoma');
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

lab = uilabel(L, "Text", "α", 'FontName', 'Tahoma', 'FontSize', 12,'HorizontalAlignment','center');
lab.Layout.Row = 5;
lab.Layout.Column = 1;
fig.UserData.Edit.alpha = uislider(L, ...
    "Orientation","horizontal", ...
    "MajorTicks", 0:0.25:1, ...
    "Limits",[0, 1], ...
    "Value", fig.UserData.Variables.alpha, ...
    "Tag", "alpha", ...
    "ValueChangedFcn", @updateAndRecomputeSystem);
fig.UserData.Edit.alpha.Layout.Row = 6;
fig.UserData.Edit.alpha.Layout.Column = 1;

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

    function [h,w,p] = compute_system(alpha, T , n)
        if nargin < 3
            n = 256;
        end
        A = min(max(alpha,0),1); 
        B = 1-A;
        C = 1;
        D = 0;
        sys = idss(A,B,C,D);
        [b,a] = ss2tf(A,B,C,D);
        [h,w] = freqs(b,a,n);
        [p,~] = pzmap(sys);
    end

    function updateAndRecomputeSystem(src, ~)
        v = src.Parent.Parent.UserData.Variables;
        v.(src.Tag) = src.Value;
        [h,w,p] = compute_system(v.alpha, v.T);
        h_mag = mag2db(abs(h));
        i_fc = find(h_mag < 0.63*max(h_mag),1,'first');
        set(src.Parent.Parent.UserData.Mag.Axes,'XLim',[0,0.5/v.T]);
        set(src.Parent.Parent.UserData.Phase.Axes,'XLim',[0,0.5/v.T]);
        set(src.Parent.Parent.UserData.Mag.Line, ...
            'XData', w * (0.5/v.T), 'YData', h_mag, 'Marker', 'v','MarkerIndices',i_fc);
        set(src.Parent.Parent.UserData.Phase.Line, ...
            'XData', w * (0.5/v.T), 'YData', angle(h));
        set(src.Parent.Parent.UserData.Pole.Scatter, ...
            'XData', p, 'YData', 0);
        set(src.Parent.Parent.UserData.Title, ...
            'Text', sprintf("EMA Filter: α = %07.4f", v.alpha));
        
        src.Parent.Parent.UserData.Variables = v;
    end

end