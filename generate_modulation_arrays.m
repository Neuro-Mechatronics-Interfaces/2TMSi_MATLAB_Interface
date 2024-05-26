function [rgFM, rgAM] = generate_modulation_arrays(text, notes, octaveUp, damping)
rgFM = [];
rgAM = [];
fm = 1;
am = 1;
octave = -octaveUp;
pause = 0;
for i = 1:length(text)
    if pause > 0
        pause = pause - 1;
        i = i - 1;
        am = am * damping;
    else
        sign = text(i);
        if sign == '|'
            pause = 4;
            octave = -octaveUp;
        elseif sign == '+'
            octave = octave + 1;
            continue;
        elseif sign == '-'
            octave = octave - 1;
            continue;
        elseif i < length(text) && text(i + 1) == '#'
            sign = strcat(sign, '#');
            i = i + 1;
        end
        note = find(strcmp(notes, sign));
        if isempty(note)
            am = am * damping;
        else
            fm = 2^(octave + (note - 9) / 12);
            am = 1;
        end
    end
    fm = min(max(fm, 0), 1);
    rgFM = [rgFM, 2 * fm - 1];
    am = min(max(am, 0), 1);
    rgAM = [rgAM, 2 * am - 1];
end
end