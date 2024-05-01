function caldata_out = init_caldata_out(ORDERED_TAG, caldata)
caldata_out = struct();
caldata_out.index = struct;
for ii = 1:numel(ORDERED_TAG)
    caldata_out.(ORDERED_TAG(ii)) = [];
    caldata_out.index.(ORDERED_TAG(ii)) = ii;
end
caldata_out.sampling_complete = false(1,numel(ORDERED_TAG));
caldata_out.sample_rate = caldata.sample_rate;
caldata_out.target = caldata.target_data;
caldata_out.time = caldata.target_times;
caldata_out.sample_rate = caldata.sample_rate;
end