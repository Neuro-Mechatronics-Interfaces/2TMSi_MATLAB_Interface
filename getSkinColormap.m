function cdata = getSkinColormap(skinColor)
%GETSKINCOLORMAP Returns colormap for mapping different skin tones using base grayscale gifs.
switch skinColor
    case "Grey"
        cdata = gray(256);
    case "White"
        cdata = double(cm.umap(validatecolor("#f7b08f")))./255.0;
        cdata = [interp1(1:64,cdata(1:64,:),linspace(1,64,3*64)); cdata(65:3:150,:); cdata(151:185,:)];
    case "Tan"
        cdata = double(cm.umap(validatecolor("#cf8d6d")))./255.0;
        cdata = [interp1(1:32,cdata(1:32,:),linspace(1,32,3*32)); interp1(33:128,cdata(33:128,:),linspace(33,128,256-3*32))];
    case "Brown"
        cdata = double(cm.umap(validatecolor("#4a2412")))./255.0;
        cdata = interp1(1:130,[0,0,0;cdata(1:128,:);1,1,1],linspace(1,130,256));
    case "Black"
        cdata = double(cm.umap(validatecolor("#4f362a")))./255.0;
        cdata = interp1(1:130,[0,0,0;cdata(1:128,:);1,1,1],linspace(1,130,256));
end

end