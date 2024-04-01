function D = objective_function(x, S, k, lambda, gamma)
    % Reshape the parameters to obtain W and H
    W = reshape(x,[],k);
    H = S\W;
    vH = nan(1,k);
    for iK = 1:k
        vH(iK) = var(H(abs(H(:,iK))>eps,iK),[],1);
    end

    % Calculate the reconstruction error
    D = norm(S - W*(H')) / sqrt(numel(S)) + lambda*norm(W, 'fro') + gamma*sum(vH);
end