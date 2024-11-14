function x = notch_filt (x, cutoff_frequency,fsamp);
    for i=1:length(cutoff_frequency)
        Wo = cutoff_frequency(i)/(fsamp/2);  BW = Wo/35;
        [b,a] = iirnotch(Wo,BW);  
        x = filtfilt(b,a,double(x));
    end
end