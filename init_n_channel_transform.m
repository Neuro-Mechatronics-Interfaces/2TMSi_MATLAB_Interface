function T = init_n_channel_transform(n, n_total)
%INIT_N_CHANNEL_TRANSFORM  Initialize matrix for n-channel transformation

arguments
    n (1,1) double {mustBeInteger, mustBePositive}
    n_total (1,1) double {mustBeInteger, mustBePositive} = 64; % Total number of electrodes in transform.
end

T =  [eye(n); zeros(n_total-n, n)];


end