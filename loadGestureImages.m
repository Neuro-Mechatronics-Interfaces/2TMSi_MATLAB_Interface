function gestureImages = loadGestureImages(options)
%LOADGESTUREIMAGES  Pre-loads gesture gif image dataset into cell array.
%
% Syntax:
%   gestureImages = loadGestureImages('Name', value, ...);
arguments
    options.Folder {mustBeFolder} = fullfile(pwd,'configurations/gifs/pro/gray');
    options.Gestures (1,:) string {mustBeMember(options.Gestures, ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"])} = ["Wrist Extension", "Wrist Flexion", "Radial Deviation", "Ulnar Deviation"]; % ["Hand Closing", "Hand Opening", "Pinch", "Radial Deviation", "Supination", "Pronation", "Ulnar Deviation", "Wrist Extension", "Wrist Flexion", "Index Extension", "Index Flexion", "Middle Extension", "Middle Flexion", "Pinky Extension", "Pinky Flexion", "Ring Extension", "Ring Flexion", "Thumb Extension", "Thumb Flexion"]; % ["Index Extension", "Middle Extension", "Ring Extension"];
    options.Mirror (1,1) logical = false;
end

nInstruct = numel(options.Gestures);
gestureImages = cell(numel(options.Gestures),1);
fprintf(1,'Loading Images...000%%\n');
for ii = 1:nInstruct
    switch options.Gestures{ii}
        case 'Pronation'
            gestureImages{ii} = imread(fullfile(options.Folder,'Supination.gif'), 'Frames','all') + 60; % Lighten everything
            nFrameCur = size(gestureImages{ii},4);
            gestureImages{ii} = gestureImages{ii}(:,:,:,[ceil(nFrameCur/2):nFrameCur,1:floor(nFrameCur/2)]);
            gestureImages{ii}(gestureImages{ii} < 80) = 0;
            gestureImages{ii} = uint8(round(double(gestureImages{ii}).^1/8.*4));
            gestureImages{ii} = 4.*(gestureImages{ii} - 32);
            gestureImages{ii} = uint8(round(32.*log(double(gestureImages{ii})+1)));
        case 'Supination'
            gestureImages{ii} = imread(fullfile(options.Folder,'Supination.gif'),'Frames','all') + 60; % Lighten everything
            gestureImages{ii}(gestureImages{ii} < 80) = 0;
            gestureImages{ii} = uint8(round(double(gestureImages{ii}).^1/8.*4));
            gestureImages{ii} = 4.*(gestureImages{ii} - 32);
            gestureImages{ii} = uint8(round(32.*log(double(gestureImages{ii})+1)));
        otherwise
            gestureImages{ii} = imread(fullfile(options.Folder,sprintf('%s.gif',options.Gestures{ii})), ...
                'Frames','all');
    end
    if options.Mirror
        gestureImages{ii} = fliplr(gestureImages{ii});
    end
    fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*ii/nInstruct));
end

end