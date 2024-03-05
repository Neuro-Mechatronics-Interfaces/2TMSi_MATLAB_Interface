function refresh_graphic(src, ~)
data = read(src, src.UserData.n, "double");
k = src.UserData.n/4;
vec = 1:k;
for ii = 1:4
    mask = vec + (ii-1)*k;
    set(src.UserData.h(data(mask(1))),'YData',data(mask(2:end))+data(mask(1)));
end
end