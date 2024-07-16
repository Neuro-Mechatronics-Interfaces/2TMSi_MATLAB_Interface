function xyz = labels_2_cartesian(labels,options)

arguments
    labels (1,:) categorical
    options.Mapping (3,:) double = [0  0  0 -1  1  0  0;  ... % x
                                    0 -1  1  0  0  0  0;  ... % y
                                    0  0  0  0  0 -1  1 ];    % z
    % options.Mapping (6,:) double = [zeros(6,1), eye(6)];
    % options.Mapping (2,:) double = [0 1 0; 0 0 1]; % xy 1d 
end

labels = double(labels);
xdata = options.Mapping(1,:);
ydata = options.Mapping(2,:);
zdata = options.Mapping(3,:);
xyz = [xdata(labels); ydata(labels); zdata(labels)];
% xpdata = options.Mapping(1,:);
% xndata = options.Mapping(2,:);
% ypdata = options.Mapping(3,:);
% yndata = options.Mapping(4,:);
% zpdata = options.Mapping(5,:);
% zndata = options.Mapping(6,:);
% xyz = [xpdata(labels); xndata(labels); ypdata(labels); yndata(labels); zpdata(labels); zndata(labels)];
% xdata = options.Mapping(1,:);
% ydata = options.Mapping(2,:);
% xyz = [xdata(labels); ydata(labels); zeros(size(labels))];
end