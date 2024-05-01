function param = init_new_calibration(param, new_state)
%INIT_NEW_CALIBRATION  Initialize new calibration parameters.
param.transform.A.(new_state) = init_n_channel_transform(param.n_spike_channels, param.n_spike_channels);
param.threshold.A.(new_state) = inf(1,param.n_spike_channels);
param.transform.B.(new_state) = init_n_channel_transform(param.n_spike_channels, param.n_spike_channels);
param.threshold.B.(new_state) = inf(1,param.n_spike_channels);
param.calibrate.A = true;
param.calibrate.B = true;
param.calibration_data.A.(new_state) = randn(param.n_samples_calibration, param.n_spike_channels);
param.calibration_data.B.(new_state) = randn(param.n_samples_calibration, param.n_spike_channels);
param.calibration_samples_acquired.A = 0;
param.calibration_samples_acquired.B = 0;
param.reinit_calibration_data = true;
end