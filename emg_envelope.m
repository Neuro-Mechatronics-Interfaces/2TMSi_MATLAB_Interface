function E = emg_envelope(X,options)
%EMG_ENVELOPE Return the power envelope for columns of X
arguments
    X
    options.ApplyMaxNorm (1,1) logical = true;
    options.a = [];
    options.b = [];
    options.Fc = 1.5;
    options.SampleRate = 4000;
    options.NInitialSamplesToBlank = 100;
end
if isempty(options.a) || isempty(options.b)
    [b,a] = butter(3,options.Fc/(options.SampleRate/2),'low');
else
    b = options.b;
    a = options.a;
end
Y = abs(X);
Y(1:options.NInitialSamplesToBlank,:) = 0;
E = filtfilt(b,a,Y);
E(:,any(isnan(E),1)) = 0;
if options.ApplyMaxNorm
    maxVal = max(E,[],1);
    maxVal(maxVal == 0) = 1;
    E = E./maxVal;
end
end