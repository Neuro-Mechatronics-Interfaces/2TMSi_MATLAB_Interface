function uni = apply_del2_textiles(uni)

for ii = 1:32:size(uni,1)
    vec = ii:(ii+32-1);
    % for ik = 1:size(uni,2)
    %     uni(vec,ik) = reshape(del2(reshape(uni(vec,ik),8,4)),32,1);
    % end
    uni(vec,:) = reshape(del2(reshape(uni(vec,:),8,4,[])),32,[]);
end

end