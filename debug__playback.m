%DEBUG__PLAYBACK  Test script for debugging playback without making app every time.

clc;
if (exist('fig','var')~=0) && isstruct(fig)
    try %#ok<TRYNC> 
        delete(fig.A);
        delete(fig.B);
    end
end
clear client fig ax h c L tmp;

cfg = io.yaml.loadFile(parameters('config'), "ConvertToArray", true);
tag = ["A", "B"];

client = struct;
fig = struct;
ax = struct;
h = struct;
c = struct;

for iTag = 1:numel(tag)
    client.(tag(iTag)) = tcpclient( ...
        cfg.Host.visualizer.(tag(iTag)), cfg.TCP.tmsi.visualizer.(tag(iTag)), ...
        "Timeout", cfg.SAGA.(tag(iTag)).Channels.n.samples / cfg.Default.Sample_Rate);
    fig.(tag(iTag)) = uifigure(...
        'Name', sprintf('[DEBUG] SAGA-%s Playback',(tag(iTag))), ...
        'Color','w', ...
        'Units', 'inches', ...
        'Position', [4.25+0.25*iTag 1.75+2.15*iTag 12.50 6.00], ...
        'Icon', 'record-player.png'); 
    ax.(tag(iTag)) = tiledlayout(fig.(tag(iTag)), 5, 5);
    nexttile(ax.(tag(iTag)), 7, [3 3]);

    h.(tag(iTag)) = charts.Snippet_Array_8_8_L_Chart( ...
        'XData', 1:cfg.SAGA.(tag(iTag)).Channels.n.samples, ...
        'YData', zeros(cfg.SAGA.(tag(iTag)).Channels.n.samples, 64), ...
        'Parent', ax.(tag(iTag)));
%     h.Layout.Tile = 7;
%     h.Layout.TileSpan = [3 3];

    client.(tag(iTag)).UserData = struct(...
        'fig',fig.(tag(iTag)), ...
        'ax',ax.(tag(iTag)), ...
        'h',h.(tag(iTag)), ...
        'n', struct('channels', ...
                    cfg.SAGA.(tag(iTag)).Channels.n.byte_stream_channels, ...
                    'samples', cfg.SAGA.(tag(iTag)).Channels.n.samples),...
        'logger', mlog.Logger(sprintf('DEBUG_SAGA_%s', tag(iTag)), fullfile(pwd, 'logs')), ...
        'tag',tag(iTag));
    client.(tag(iTag)).configureCallback("terminator", @debug_tmsi_stream);
end