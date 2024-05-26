function tmp = estimate_muscle_center_batch(T1,T2,options)

arguments
    T1 table
    T2 table
    options.Spacing = 0.5;
    options.LocationStart = 4.5;
    options.Section0_Number = 114;
    options.T1_Number = 113;
    options.T2_Number = 130;
end

tmp = [];
for iMuscle = 1:size(T2,1)
    if ismember(T2.Landmark{iMuscle},T1.Landmark)
        tmp = [tmp; estimate_muscle_center(T1,T2,T2.Landmark{iMuscle}, ...
            'Spacing', options.Spacing, ...
            'LocationStart', options.LocationStart, ...
            'Section0_Number', options.Section0_Number, ...
            'T1_Number', options.T1_Number, ...
            'T2_Number', options.T2_Number)]; %#ok<AGROW>
    end
end

G = findgroups(tmp.Section);
tmp = splitapply(@(Section,Landmark,X,Y){table(Section,Landmark,X,Y)},tmp,G);

end