function t_str = seconds_2_str(n_sec)
%SECONDS_2_STR  Return string with formatted number of seconds elapsed.

if n_sec > 60
    n_min = n_sec / 60;
    t_str = sprintf('%4.1f mins', round(n_min,1));
else
    t_str = sprintf('%4.1f sec', round(n_sec,1));
end

end