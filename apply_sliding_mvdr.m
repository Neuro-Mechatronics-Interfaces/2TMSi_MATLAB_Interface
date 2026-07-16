function [ySel, tSel] = apply_sliding_mvdr(X, w, tRel, cAbs, nNew)
%APPLY_SLIDING_MVDR  Score MVDR only where the window END lies in the last nNew rows of X. No absolute indexing; robust to any absStartIdx bookkeeping.
%
% Returns:
%   ySel : (nSel x 1) scores for newly appended times
%   tSel : (nSel x 1) buffer row indices where ySel is defined

[T, ~] = size(X);
tRel = tRel(:);  cAbs = cAbs(:);
Tloc = numel(tRel);
Cloc = numel(cAbs);
offMin = min(tRel);
offMax = max(tRel);

% New rows that were just appended:
newRows = (T - nNew + 1 : T).';             % buffer indices where window END should land

% y(t) corresponds to window rows t + tRel.
% If the END of the window is at row r (i.e., r = t + offMax), then t = r - offMax.
tCand = newRows - offMax;

% Keep only t whose whole window fits inside X
tValidLo = 1 - offMin;
tValidHi = T - offMax;
tSel = tCand(tCand >= tValidLo & tCand <= tValidHi);
if isempty(tSel)
    ySel = zeros(0,1,'like',X);
    return
end

% Build the windowed patch for all selected times in one shot
nSel  = numel(tSel);
ttMat = tSel + tRel.';                      % (nSel x Tloc)

P = zeros(nSel, Tloc*Cloc, 'like', X);      % time-major within channel
for j = 1:Cloc
    col  = cAbs(j);
    idx  = ttMat + (col-1)*T;               % linear indices into X
    pj   = reshape(X(idx), nSel, Tloc);
    cols = (j-1)*Tloc + (1:Tloc);
    P(:, cols) = pj;
end

ySel = P * reshape(w, Tloc*Cloc, 1);        % (nSel x 1)
end
