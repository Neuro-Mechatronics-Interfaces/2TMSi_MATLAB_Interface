function [c,ceq] = expand_recompose_nlcons(W, alpha, is_nonneg)

if is_nonneg
    c = nonnegativity_constraint(W);
else
    c = [];
end
ceq = scaling_constraint(W);
c_sparsity = alpha * sum(W>0,1);
c = [c; c_sparsity'];

end