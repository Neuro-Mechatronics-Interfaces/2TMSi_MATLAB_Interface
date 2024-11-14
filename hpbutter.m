function x = hpbutter (x, cutoff_frequency,fsamp)
if cutoff_frequency == 0;
    x=x;
else
    %mx = median(abs(x));
    [b,a] = butter(4,cutoff_frequency/fsamp*2,'high');
    x = filtfilt(b,a,double(x));
    %x = x*mx/median(abs(x));
end