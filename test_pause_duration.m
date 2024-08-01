function tau = test_pause_duration(n_iter, pause_duration, options)

arguments
    n_iter (1,1) {mustBePositive, mustBeInteger} = 10000;   % Number of loop iterations
    pause_duration (1,1) double {mustBePositive} = 0.00005; % Seconds
    options.Verbose (1,1) logical = true;
end

start_tic = tic;
for ii = 1:n_iter
    pause(pause_duration);
end
tau = toc(start_tic);

if options.Verbose
    fprintf(1,'Tested %d iterations of pauses:\n',n_iter);
    fprintf(1,'\t->\tRequested: %.3fms\n',pause_duration*1e3);
    fprintf(1,'\t->\tMeasured: %.3fms\n',(tau/n_iter)*1e3);
end
end