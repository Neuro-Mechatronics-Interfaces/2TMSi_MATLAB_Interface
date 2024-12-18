function data = handle_spatial_ref(data, S, apply_car, textiles, interpolate_grid)
%HANDLE_SPATIAL_REF  Handle spatial referencing
arguments
    data (:,:) double % nSamples x nChannels highpass-filtered data
    S (64,64) double % Spatial projection array
    apply_car (1,1) logical = true; 
    textiles (1,1) logical = true;
    interpolate_grid (1,1) logical = false;
end

if interpolate_grid
    n = size(data,1);
    if textiles
        if apply_car
            mu1 = mean(data(:,1:32),1)';
            mu2 = mean(data(:,33:64),1)';
        else
            mu1 = zeros(32,1);
            mu2 = zeros(32,1);
        end
        tmp = reshape(data(:,1:32)' - mu1, 8, 4, n);
        tmp2 = reshape(data(:,33:64)' - mu2, 8, 4, n);
        for ik = 1:n
            tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
            tmp2(:,:,ik) = fillmissing2(tmp2(:,:,ik),'linear');
        end
        data(:,1:32) = reshape(tmp,32,n)';
        data(:,33:64) = reshape(tmp2,32,n)';
    else
        if apply_car
            mu = mean(data,1)';
        else
            mu = zeros(64,1);
        end
        tmp = reshape(data' - mu, 8, 8, n);
        for ik = 1:n
            tmp(:,:,ik) = fillmissing2(tmp(:,:,ik),'linear');
        end
        data = reshape(tmp,64,n)';
    end
end

data = (S * data')';

end