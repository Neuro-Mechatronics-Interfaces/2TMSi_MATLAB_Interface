function heatmapCallback(src,~)
msg = jsondecode(readline(src));
data = src.UserData.H.CData;
if msg.SAGA=="A"
data(:,1:8) = reshape(msg.data(1:64),8,8);
else
data(:,9:16) = reshape(msg.data(1:64),8,8);
end
src.UserData.H.CData = data;
drawnow();


end