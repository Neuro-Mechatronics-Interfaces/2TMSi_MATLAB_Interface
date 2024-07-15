function xyz = labels_2_cartesian(labels,options)

arguments
    labels (1,:) categorical
    options.Mapping (3,:) double = [0  0  0 -1  1  0  0;  ... % x
                                    0 -1  1  0  0  0  0;  ... % y
                                    0  0  0  0  0 -1  1 ];    % z
end

labels = double(labels);
xdata = options.Mapping(1,:);
ydata = options.Mapping(2,:);
zdata = options.Mapping(3,:);
xyz = [xdata(labels); ydata(labels); zdata(labels)];

end