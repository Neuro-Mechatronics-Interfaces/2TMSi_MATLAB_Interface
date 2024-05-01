function data = prepare_for_mvc(data, time, force, target_profile, options)
arguments
    data
    time
    force
    target_profile
    options.Fc = 100;
end
warning('off','MATLAB:structOnObject');
data = struct(data);
warning('on','MATLAB:structOnObject');
[b,a] = butter(3,options.Fc/(data.sample_rate/2),'high');
[data.iUni, data.iBip, data.iTrig, data.iCounter] = get_saga_channel_masks(data.channels);
data.samples(data.iUni,:) = filtfilt(b,a,data.samples(data.iUni,:)')';
data.t = (0:(size(data.samples,2)-1))./data.sample_rate;
iStart = find(bitand(data.samples(data.iTrig,:),2^0)==0); 
iStart = iStart([false,diff(iStart)>1]); 
tStart = data.t(iStart(1));
data.force = struct('t', time+tStart, 'value', force);
data.target = struct('t', target_profile(:,1)+tStart, 'value', target_profile(:,2));

end