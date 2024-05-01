function [state, z] = envelope_proj_2_state(E, z, coeff, mu)
n = numel(mu);
score = [z; (E - mu) * coeff];
z = score((end-1):end, :);
state = [score, [zeros(1,n); diff(score,1,1)], [zeros(2,n); diff(score,2,1)]];
end