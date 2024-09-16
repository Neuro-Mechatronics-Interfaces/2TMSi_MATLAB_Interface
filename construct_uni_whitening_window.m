function Wz = construct_uni_whitening_window(extFact, windowingVector)

Wz = zeros(64,extFact*64);
for iCh = 1:64
    vec = (iCh-1)*extFact + (1:extFact);
    Wz(iCh,vec) = windowingVector;
end

end