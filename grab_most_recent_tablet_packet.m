function pkt = grab_most_recent_tablet_packet()
pkt = WinTabMex(5);
if ~isempty(pkt)
    tmp = WinTabMex(5);
    while ~isempty(tmp) % Always grab the last event in queue.
        pkt = tmp;
        tmp = WinTabMex(5);
    end
end
end