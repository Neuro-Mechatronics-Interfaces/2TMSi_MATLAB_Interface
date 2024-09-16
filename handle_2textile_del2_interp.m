function data = handle_2textile_del2_interp(data, interpolate_grid)

arguments
    data (:,:) double
    interpolate_grid (1,1) logical = false;
end

n = size(data,1);
tmp = reshape(data(:,1:32)', 8, 4, n);
tmp2 = reshape(data(:,33:64)', 8, 4, n);
if interpolate_grid
    for ik = 1:n
        tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
        tmp2(:,:,ik) = fillmissing2(tmp2(:,:,ik),'linear');
    end
end
data(:,1:32) = reshape(del2(tmp),32,n)';
data(:,33:64) = reshape(del2(tmp2),32,n)';

end