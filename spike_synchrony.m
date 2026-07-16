function s = spike_synchrony(a, b, tau)
%SPIKE_SYNCHRONY  Symmetric synchrony score in [0,1].
% s = matches / min(numel(a), numel(b)), where a match is |a_i - b_j| <= tau.
% a,b: integer sample indices (column vectors). Assumes both sorted; if not, sorts internally.

    if isempty(a) || isempty(b)
        s = 0; return
    end
    a = a(:); b = b(:);
    if ~issorted(a), a = sort(a); end
    if ~issorted(b), b = sort(b); end

    i = 1; j = 1; m = 0;
    na = numel(a); nb = numel(b);

    % Two-pointer sweep
    while i <= na && j <= nb
        d = a(i) - b(j);
        if d < -tau
            i = i + 1;
        elseif d >  tau
            j = j + 1;
        else
            % match; advance both (greedy one-to-one)
            m = m + 1;
            i = i + 1;
            j = j + 1;
        end
    end

    s = m / max(1, min(na, nb));
end
