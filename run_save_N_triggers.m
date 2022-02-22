function run_save_N_triggers(device, N, TRIG, fname)
%RUN_SAVE_N_TRIGGERS  Save data after N triggers on channel TRIG

window_seconds = 1.0;

if nargin < 4
    [~, fname] = get_new_names(device);
end

% Measurement configuration
poly5_file = TMSiSAGA.Poly5(fname, [device.sample_rate], getActiveChannels(device));
n_trig = zeros(size(device));

% Initialise the sample buffer and the window_size
sample_buffer = cell(size(device));
window_samples = nan(size(device));
trig_channel = nan(size(device));
for k = 1:numel(device)
    if ~device(k).is_connected
        device(k).connect();
    else
        if device(k).is_sampling
            device(k).stop();
        end
    end
    
    sample_buffer{k} = zeros(numel(device.getActiveChannels()), 0);
    window_samples(k) = round(window_seconds * device.sample_rate);
    trig_channel(k) = find(contains(getName(device(k).getActiveChannels()), "TRIGGERS"), 1, 'first');
end

start(device);
while all(n_trig < N)
    [samples, num_sets] = sample(device);
    for k = 1:numel(device)
        if num_sets(k) > 0
            append(poly5_file(k), samples{k}, num_sets(k)); 
        
            % Append samples to a buffer, so that there is always
            % a minimum of window_samples to process the data
            sample_buffer{k}(:, size(sample_buffer{k}, 2) + size(samples{k}, 2)) = 0;
            sample_buffer{k}(:, end-size(samples{k}, 2) + 1:end) = samples{k};

            if size(sample_buffer{k}, 2) >= window_samples(k)
                trigs = ~bitand(sample_buffer{k}(trig_channel(k), :), 2^(TRIG-1));
                if any(trigs)
                    n_trig = n_trig + 1;
                end                
                % Clear the processed window from the sample buffer
                sample_buffer{k} = sample_buffer{k}(:, window_samples(k) + 1:end);
            end
        end
    end
end
stop(device);

end