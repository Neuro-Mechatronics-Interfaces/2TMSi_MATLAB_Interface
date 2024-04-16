function ceq = scaling_constraint(W)
ceq = (sum(W,1) - ones(1,size(W,2)))';
end