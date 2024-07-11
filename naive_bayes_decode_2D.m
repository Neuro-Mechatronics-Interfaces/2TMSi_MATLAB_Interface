function xy_decode = naive_bayes_decode_2D(beta0, beta, uni_env, options)

arguments
    beta0 (2,1) double
    beta (2,128) double
    uni_env (128,:) double
    options.PositiveThreshold (2,1) double = [0.5; 0.65];
    options.NegativeThreshold (2,1) double = [-0.5; -0.75];
end

xy_hat = beta * uni_env + beta0;

xy_decode = -1.*double(xy_hat < options.NegativeThreshold) + double(xy_hat > options.PositiveThreshold);
end