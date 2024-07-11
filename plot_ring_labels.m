function [fig,L,vec,ax] = plot_ring_labels(iRing, channelOrder, theta, proxdist,options)
%PLOT_RING_LABELS  Plot labels for ring layout 
arguments
    iRing (1,1) {mustBeInteger}
    channelOrder (1,128) {mustBePositive, mustBeInteger}
    theta (1,16) double
    proxdist (1,8) {mustBeInteger}
    options.Parent = [];
    options.XRadius = 1;
    options.TextXRadius = 0.925;
    options.YRadius = 1;
    options.TextYRadius = 0.925;
end

if isempty(options.Parent)
    fig = figure('Name', 'Ring Layout EMG', 'Color', 'w');
    L = tiledlayout(fig,'flow');
    ax = nexttile(L);
    set(ax, 'NextPlot', 'add', 'XColor', 'none', 'YColor', 'none');

else
    ax = options.Parent;
    L = [];
    fig = ax.Parent;
end

k = find(proxdist == iRing, 1, 'first');
if isempty(k)
    error("Invalid ring value: %d", iRing);
end
vec = (1:16) + (k-1)*16;
rx = options.XRadius .* cos(theta);
tx = options.TextXRadius.*cos(theta);
ry = options.YRadius .* sin(theta);
ty = options.TextYRadius.*sin(theta);

if theta(1) < 0
    plot(ax, rx(1:8), ry(1:8), 'bo-', 'DisplayName', 'Extensors');
    text(ax, tx(1:8), ty(1:8), num2str(channelOrder(vec(1:8))'), 'FontName', 'Consolas', 'FontSize', 6, 'Color', 'b');
    plot(ax, rx(9:16), ry(9:16), 'ro-', 'DisplayName', 'Flexors');
    text(ax, tx(9:16), ty(9:16), num2str(channelOrder(vec(9:16))'), 'FontName', 'Consolas', 'FontSize', 6, 'Color', 'r');
else
    plot(ax, rx(1:8), ry(1:8), 'ro-', 'DisplayName', 'Flexors');
    text(ax, tx(1:8), ty(1:8), num2str(channelOrder(vec(1:8))'), 'FontName', 'Consolas', 'FontSize', 6, 'Color', 'r');
    plot(ax, rx(9:16), ry(9:16), 'bo-', 'DisplayName', 'Extensors');
    text(ax, tx(9:16), ty(9:16), num2str(channelOrder(vec(9:16))'), 'FontName', 'Consolas', 'FontSize', 6, 'Color', 'b');
end
end