function zdata = fast_proj(edata, extFact, epsilon)

Rw = (edata * edata') / (size(edata, 2) - 1);
[U,S,~] = svd(Rw);
Pw = U * diag(1 ./ sqrt(diag(S) + epsilon)) * U';
zdata = Pw * edata(:,(extFact+1):(end-extFact+1));

end