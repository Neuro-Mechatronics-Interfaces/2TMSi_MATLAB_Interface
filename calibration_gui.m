function calibration_gui(emg_stream, options)
    arguments
        emg_stream; % Handle to the LSL EMG stream
        options.Duration (1,1) double = 60; % Duration of the calibration in seconds
        options.TargetFrequency (1,1) double = 0.5; % Frequency of target movement (Hz)
    end

    fig = uifigure('Name', 'EMG Calibration', 'Position', [100, 100, 800, 600]);
    ax = uiaxes('Parent', fig, 'Position', [50, 50, 700, 500]);
    target = plot(ax, 0, 0, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
    xlim(ax, [-1, 1]);
    ylim(ax, [-1, 1]);

    % Timer to update target position
    t = timer('ExecutionMode', 'FixedRate', 'Period', 0.02, ...
              'TimerFcn', @(~,~) updateTarget(target, options.TargetFrequency));

    % Start timer and capture EMG signals
    start(t);
    emg_data = capture_emg(emg_stream, options.Duration);

    % Stop timer
    stop(t);
    delete(t);

    % Save captured EMG data for training
    save('emg_calibration_data.mat', 'emg_data');
end

function updateTarget(target, freq)
    t = datetime('now', 'Format', 'ss.SSSS');
    t = seconds(t - datetime(t.Year, t.Month, t.Day));
    x = cos(2 * pi * freq * t);
    y = sin(2 * pi * freq * t);
    target.XData = x;
    target.YData = y;
end

function emg_data = capture_emg(emg_stream, duration)
    emg_data = [];
    % Capture EMG data for the specified duration
    tic;
    while toc < duration
        chunk = emg_stream.pull_chunk();
        emg_data = [emg_data, chunk];
        pause(0.01);
    end
end
