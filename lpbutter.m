function x = lpbutter (x, cutoff_frequency,fsamp);
if cutoff_frequency == fsamp/2;
    x=x;
else
    %mx = median(abs(x));
    [b,a] = butter(4,cutoff_frequency/fsamp*2,'low');
    x = filtfilt(b,a,double(x));
    %x = x/median(abs(x))*mx;
end