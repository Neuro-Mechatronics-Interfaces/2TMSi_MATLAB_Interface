function assertion = decode_rms_assertion(trig_val, prev_assertion, falling_threshold, rising_threshold)
%DECODE_RMS_ASSERTION Simple threshold-crossing with potentially asymmetry in thresholds for rising vs falling edge assertion/de-assertion.
arguments
    trig_val (1,1) double
    prev_assertion (1,1) logical
    falling_threshold (1,1) double
    rising_threshold (1,1) double
end

if prev_assertion % If button is pressed, check if we should un-press it.
    if trig_val < falling_threshold
        assertion = false;
    else
        assertion = true;
    end
else
    if trig_val > rising_threshold
        assertion = true;
    else
        assertion = false;
    end
end

end