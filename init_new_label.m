function param = init_new_label(param, new_state)
%INIT_NEW_LABEL  Initialize new labeled data parameters.
param.label.A = true;
param.label.B = true;
param.labeled_data.A.(new_state) = randn(param.n_total.A, param.n_samples_label);
param.labeled_data.B.(new_state) = randn(param.n_total.B, param.n_samples_label);
param.labeled_samples_acquired.A = 0;
param.labeled_samples_acquired.B = 0;
end