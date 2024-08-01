function Xs = prepare_for_seqnet(X, seqLength)

arguments
    X (128,:) double
    seqLength (1,1) {mustBePositive, mustBeInteger} = 100;
end

% Determine the total number of sequences
N = size(X, 2);
numSeq = floor(N / seqLength);

% Split X and Y into sequences
Xs = cell(1, numSeq);
for i = 1:numSeq
    Xs{i} = X(:, (i-1)*seqLength + 1 : i*seqLength);
end

end