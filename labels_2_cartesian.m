function xy = labels_2_cartesian(labels,options)

arguments
    labels (1,:) categorical
    options.Mapping (2,:) double = [0  0  0 -1  1;  ... % x
                                    0 -1  1  0  0];     % y
end

labels = double(labels);
xdata = options.Mapping(1,:);
ydata = options.Mapping(2,:);
xy = [xdata(labels); ydata(labels)];

end