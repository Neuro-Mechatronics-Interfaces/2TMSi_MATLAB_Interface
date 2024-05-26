function tmp = estimate_muscle_center(T1,T2,muscle,options)

arguments
    T1 table
    T2 table
    muscle {mustBeMember(muscle,{'BR','ECRL','ECRB','PQ','EI','ED','EDM','APL','EPL','FPL','PT','SUP','ECU','FCU','FCR','FDS','FDP'})}
    options.Spacing = 0.5;
    options.LocationStart = 4.5;
    options.Section0_Number = 114;
    options.T1_Number = 113;
    options.T2_Number = 130;
end

iMuscle1 = strcmpi(T1.Landmark,muscle);
if sum(iMuscle1)==0
    error("No such muscle in T1: %s", muscle);
end
iMuscle2 = strcmpi(T2.Landmark,muscle);
if sum(iMuscle2)==0
    error("No such muscle in T2: %s", muscle);
end
M_X = (T2.X(iMuscle2)-T1.X(iMuscle1))/(options.Spacing*(options.T2_Number-options.T1_Number));
M_Y = (T2.Y(iMuscle2)-T1.Y(iMuscle1))/(options.Spacing*(options.T2_Number-options.T1_Number));
fx = @(z)(z-options.LocationStart)*M_X+T1.X(iMuscle1);
fy = @(z)(z-options.LocationStart)*M_Y+T1.Y(iMuscle1);

Section = ((options.T1_Number+1):(options.T2_Number-1))';
z = (Section-Section(1)).*options.Spacing + options.LocationStart;
X = round(fx(z));
Y = round(fy(z));
Landmark = repmat(string(muscle),numel(X),1);
tmp = table(Section,Landmark,X,Y);

end