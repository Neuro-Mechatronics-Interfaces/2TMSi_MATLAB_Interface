function [makeTransition, risingState] = detectRisingStateTransition(trigSamples, slidingThresh, risingThresh, nCur, risingStatePrev, nPrev)

alpha = nCur / (nCur + nPrev);
beta = 1 - alpha;
risingState = alpha * nnz(trigSamples > slidingThresh) / nCur + beta * risingStatePrev;
makeTransition = risingState > risingThresh;

end