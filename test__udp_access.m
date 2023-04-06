%TEST__UDP_ACCESS  Test UDP access (to be used with bat file)
udp = udpport("LocalHost", "0.0.0.0", "LocalPort", 3030);
udp.configureCallback("terminator", @callback.echo);

fig = uifigure("Name", "Close to end UDP Test", 'Color', 'k');
waitfor(fig);

clear udp fig;