clear;
clc;

fig = init_pressure_tracking_fig();

%%
while isvalid(fig)
    pkt = WinTabMex(5);
    if ~isempty(pkt)
        tmp = WinTabMex(5);
        while ~isempty(tmp) % Always grab the last event in queue.
            pkt = tmp;
            tmp = WinTabMex(5);
        end
        fig.UserData.PressureLine.h.YData(fig.UserData.PressureLine.idx) = pkt(9);
        fig.UserData.PressureLine.idx = rem(fig.UserData.PressureLine.idx,1000)+1;
        fig.UserData.PressureLine.h.YData(fig.UserData.PressureLine.idx) = nan;
        
        if pkt(9) > 0
            fig.UserData.PressureSpots.h.XData(fig.UserData.PressureSpots.idx) = pkt(1);
            fig.UserData.PressureSpots.h.YData(fig.UserData.PressureSpots.idx) = pkt(2);
            fig.UserData.PressureSpots.h.CData = circshift(fig.UserData.PressureSpots.h.CData,-1);
            fig.UserData.PressureSpots.h.SizeData(fig.UserData.PressureSpots.idx) = pkt(9)/10;
            fig.UserData.PressureSpots.idx = rem(fig.UserData.PressureSpots.idx,1000)+1;
        end
    end
    drawnow();
end