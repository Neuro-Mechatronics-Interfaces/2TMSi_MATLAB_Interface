function PPTX_AddTemplateArm(pptx,options)
%PPTX_ADDTEPMLATEARM  Adds template arm image to Powerpoint slide
arguments
    pptx
    options.File {mustBeTextScalar} = 'Arm-Template.png';
    options.SlideDimensions (1,2) double = [10, 7.5]; % Inches
    options.ImageSize (1,2) double = [4, 2.5]; % Inches
    options.SetImageSize (1,1) logical = true;
end

if options.SetImageSize
    x = options.SlideDimensions(1)/2 - options.ImageSize(1)/2;
    y = options.SlideDimensions(2)/2 - options.ImageSize(2)/2;
    pptx.addPicture(options.File, 'Position', [x, y, options.ImageSize]);
else
    pptx.addPicture(options.File);
end

end