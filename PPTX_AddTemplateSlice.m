function PPTX_AddTemplateSlice(pptx,x,w,options)
%PPTX_ADDTEPMLATESLICE  Adds template cross-sectional image to Powerpoint slide
arguments
    pptx
    x (1,1) double {mustBeInRange(x,0,13)}
    w (16,1) double
    options.ArmTemplateFile {mustBeFile} = 'Arm-Template.png';
    options.ArmTemplatePosition (1,4) double = [0,1.0,1.5,1.0];
    options.ArrowFile {mustBeFile} = 'MyArrow.png';
    options.HorizontalPosition (1,1) double = 0; % Inches
    options.SlideDimensions (1,2) double = [10, 7.5]; % Inches
    options.ImageSize (1,2) double = [5, 5]; % Inches
    options.SlicesRoot {mustBeFolder} = "C:/Data/Anatomy/Human Arm/Sections";
    options.Slice0 (1,1) {mustBeInteger} = 105;
    options.SliceSpacing (1,1) double = 0.5; % cm
    options.SliceMax (1,1) {mustBeInteger} = 130;
    % options.SliceNameExpr {mustBeTextScalar} = "Slice_%d.png";
    options.SliceNameExpr {mustBeTextScalar} = "R_Forearm_section_%d.png";
    % options.SliceCenterXY (1,2) = [1100,1575];
    options.SliceCenterXY (2,2) = [485, 240; 500, 310];
    % options.SliceRadius (1,1) double = 1000;
    options.SliceRadius (2,1) double = [140;140];
    options.SliceElectrodeRanges (2,2) double = [-2.9953,-1.2352;29*pi/15,pi/2-pi/60];
    % options.SliceElectrodeRanges (2,2) double = [5*pi/6,pi;3*pi/2,13*pi/6];
    options.SliceElectrodesPerGrid (1,1) {mustBePositive, mustBeInteger} = 8;
    options.SourceColor = [];
end
[fname,A,~,transparency,cdata] = ARM_GetSlice(x,...
    'SlicesRoot',options.SlicesRoot,...
    'Slice0',options.Slice0,...
    'SliceSpacing',options.SliceSpacing, ...
    'SliceMax', options.SliceMax, ...
    'SliceNameExpr', options.SliceNameExpr);

xp = options.HorizontalPosition;
yp = (options.SlideDimensions(2) - options.ImageSize(2))/2;
fig = figure('Name','Template Slice','Color','w','Units','inches','Position',[0.2,0.2,options.ImageSize+0.5]);
ax = axes(fig,'NextPlot','add','XColor','none','YColor','none','Color','none','YDir','reverse');
imagesc(ax,A,'AlphaData',transparency);

[xy_a,xy_b] = boundaryPointsROI(logical(transparency),options.SliceElectrodeRanges(1,1),options.SliceElectrodeRanges(1,2),...
    options.SliceElectrodeRanges(2,1),options.SliceElectrodeRanges(2,2));

h = scatter(ax,xy_a(:,1),xy_a(:,2),'LineWidth',2.5,'SizeData',32,'SizeDataMode','manual', ...
    'Marker', 's', 'MarkerEdgeColor',cdata(1,:),'MarkerFaceColor',cdata(1,:),'MarkerFaceAlpha',0.5);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
h = scatter(ax,xy_b(:,1),xy_b(:,2),'LineWidth',2.5,'SizeData',32,'SizeDataMode','manual', ...
    'Marker', 's', 'MarkerEdgeColor',cdata(2,:),'MarkerFaceColor',cdata(2,:),'MarkerFaceAlpha',0.5);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';



[~,f,~] = fileparts(fname);
T = readtable(fullfile(options.SlicesRoot,"Landmarks.xlsx"),'Sheet',f);
% [x_s, y_s] = triangulateSource([xy_a(:,1);xy_b(:,1)],[xy_a(:,2);xy_b(:,2)],w(:));
mu_c = mean(options.SliceCenterXY,1);
[x_s,y_s] = triangulateSourceWithConstraints([xy_a(:,1);xy_b(:,1)],[xy_a(:,2);xy_b(:,2)],w(:),mu_c(1),mu_c(2),mean(options.SliceRadius));
d = sqrt(sum(([T.X,T.Y]-[x_s,y_s]).^2,2));
[~,iMin] = min(d);
h = scatter(ax,T.X(iMin),T.Y(iMin),'Marker','*','SizeData',24,'MarkerEdgeColor','w','LineWidth',2);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
delta = [T.X(iMin),T.Y(iMin)] - [x_s,y_s];
theta_t = wrapTo2Pi(atan2(delta(2),delta(1)));
xt = delta(1)*0.5 + x_s;
yt = delta(2)*0.5 + y_s;
rd = sqrt(sum(delta.^2));
if theta_t > pi
    theta_delt = theta_t + pi/2;
else
    theta_delt = theta_t - pi/2;
end
xt0 = cos(theta_delt)*rd*0.5;
yt0 = sin(theta_delt)*rd*0.5;

if isempty(options.SourceColor)
    [~,iMax] = max(w);
    if iMax>8
        c_s = cdata(2,:);
    else
        c_s = cdata(1,:);
    end
else
    c_s = options.SourceColor;
end

h = scatter(ax,x_s,y_s,'Marker','o','SizeData',sum(w),'MarkerFaceAlpha',0.75,'MarkerEdgeColor',c_s,'MarkerFaceColor',c_s,'LineWidth',1.5);
h.Annotation.LegendInformation.IconDisplayStyle = 'off';
text(ax,xt+xt0,yt+yt0,T.Landmark{iMin},'FontSize',14,'FontWeight','bold','FontName','Tahoma','Color','w','Rotation',rad2deg(theta_delt));

pptx.addPicture(fig, 'Position', [xp, yp, options.ImageSize]);

pptx.addPicture(options.ArmTemplateFile, 'Position', options.ArmTemplatePosition);
pptx.addPicture(options.ArrowFile,'Position',[0.2+0.4*x/12.5, 1.11 + 0.17*x/12.5, 0.15, 0.25]);
delete(fig);

end