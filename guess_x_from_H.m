function x = guess_x_from_H(H,options)

arguments
    H
    options.NGuessesPerFactor = 3;
    options.InitialGuessFraction = 0.25;
    options.MinGuessAmplitude = 0.02;
end

x = [zeros(size(H,1)*options.NGuessesPerFactor, 1), repelem((1:size(H,1))',options.NGuessesPerFactor,1)];

hmax = max(H,[],2);
for iH = 1:size(H,1)
    iAssign = (1:options.NGuessesPerFactor) + options.NGuessesPerFactor*(iH-1);
    minH = min(H(iH,H(iH,:) > 0));
    thresholds = linspace(max(hmax(iH)*options.InitialGuessFraction,minH+0.01),hmax(iH),options.NGuessesPerFactor+1);
    if numel(thresholds) < options.NGuessesPerFactor
        continue;
    end
    x(iAssign,1) = fliplr(thresholds(1:(end-1)))';
end

x(x(:,1) < options.MinGuessAmplitude,:) = [];


end