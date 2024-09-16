function [makeTransition, fallingState] = detectFallingStateTransition(trigSamples, slidingThresh, fallingThresh, nCur, fallingStatePrev, nPrev)

alpha = nCur / (nCur + nPrev);
beta = 1 - alpha;
fallingState = alpha * nnz(trigSamples > slidingThresh) / nCur + beta * fallingStatePrev;
makeTransition = fallingState < fallingThresh;

end