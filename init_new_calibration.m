function param = init_new_calibration(param, new_state)
%INIT_NEW_CALIBRATION  Initialize new calibration parameters.
param.transform.A.(new_state) = init_n_channel_transform(param.n_spike_channels, param.n_total.A);
param.threshold.A.(new_state) = inf(param.n_spike_channels,1);
param.transform.B.(new_state) = init_n_channel_transform(param.n_spike_channels, param.n_total.B);
param.threshold.B.(new_state) = inf(param.n_spike_channels,1);
param.calibrate.A = true;
param.calibrate.B = true;
param.calibration_data.A = randn(param.n_total.A, param.n_samples_calibration);
param.calibration_data.B = randn(param.n_total.B, param.n_samples_calibration);
param.calibration_samples_acquired.A = 0;
param.calibration_samples_acquired.B = 0;
end