function H = lsqnonneg_matrix(Y,W)
%LSQNONNEG_MATRIX Apply lsqnonneg factorization to recover encoding matrix, given prior nonnegative weighting matrix W.
n = size(Y,2);
H = nan(size(W,2), n);
for iH = 1:n
    H(:,iH) = lsqnonneg(W,Y(:,iH));
end
end