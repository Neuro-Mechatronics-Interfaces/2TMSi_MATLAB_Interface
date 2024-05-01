function T = cleanExperimentTable(T,options)
%CLEANEXPERIMENTTABLE  Cleans table from Meta experiments
arguments
    T
    options.SubFolderProximalFlexor (1,1) string = "TMSi Saga 1 Flx Proximal";
    options.SubFolderProximalExtensor (1,1) string = "TMSi Saga 5 Ext Proximal";
    options.SubFolderDistalFlexor (1,1) string = "TMSi Saga 3 Flex Distal";
    options.SubFolderDistalExtensor (1,1) string = "TMSi Saga 4 Ext Distal";
    options.DeviceFlexDist (1,1) string = "dev1";
    options.DeviceFlexProx (1,1) string = "dev1";
    options.DeviceExtDist (1,1) string = "dev2";
    options.DeviceExtProx (1,1) string = "dev2";
    options.Subject (1,1) string = "MCP01";
    options.Year (1,1) double = 2024;
    options.Month (1,1) double = 4;
    options.Day (1,1) double = 12;
    options.GesturesSubfolder {mustBeTextScalar} = "Gestures GUI";
    options.FeedbackSubfolder {mustBeTextScalar} = "EMG feedback GUI";
    options.DataRoot {mustBeTextScalar} = "C:/Data/Shared";
    options.Poly5FormatIdentifierDistalFlexor = '*Tr*_%03d*.poly5';
    options.Poly5FormatIdentifierDistalExtensor = '*Tr*_%03d*.poly5';
    options.Poly5FormatIdentifierProximalFlexor = '*Tr*_%03d*.poly5';
    options.Poly5FormatIdentifierProximalExtensor = '*Tr*_%03d*.poly5';
    options.ProximalOnPrakarshGUI (1,1) logical = true;
end
TANK = sprintf('%s_%04d_%02d_%02d',options.Subject,options.Year,options.Month,options.Day);
TANK_FOLDER = fullfile(options.DataRoot,TANK);
if exist(TANK_FOLDER,'dir')==0
    error("No folder named %s. Check options are configured correctly.",TANK_FOLDER);
end

if ismember('Number',T.Properties.VariableNames)
    T.Properties.VariableNames{strcmpi(T.Properties.VariableNames,'Number')} = 'Trial';
end
T(ismissing(T.Trial),:) = []; % Remove empty rows
N = size(T,1);
if ismember('Task',T.Properties.VariableNames)
    T.Task = string(T.Task);
    if ~ismember('Joint', T.Properties.VariableNames) || ~ismember('Movement', T.Properties.VariableNames)
        Joint = cell(N,1);
        Movement = cell(N,1);
        for ii = 1:N
            tmp = strsplit(char(T.Task(ii)),' ');
            if tmp{1}(1) == '('
                Joint{ii} = lower(tmp{2});
                Movement{ii} = lower(tmp{3});
            else
                Joint{ii} = lower(tmp{1});
                Movement{ii} = lower(tmp{2});
            end
            Joint{ii}(1) = upper(Joint{ii}(1));
            Movement{ii}(1) = upper(Movement{ii}(1));
        end
        T.Joint = string(Joint);
        T.Movement = string(Movement);
    end
else
    if ismember('Joint',T.Properties.VariableNames)
        T.Joint = string(T.Joint);
    end
    if ismember('Movement',T.Properties.VariableNames)
        T.Movement = string(T.Movement);
    end
    if ismember('Joint',T.Properties.VariableNames) && ismember('Movement',T.Properties.VariableNames)
        T.Task = strings(N,1);
        for ii = 1:N
            T.Task(ii) = sprintf("%s %s",T.Joint(ii), T.Movement(ii));
        end
    end

end

if ismember('Arm',T.Properties.VariableNames)
    T.Arm = string(T.Arm);
else
    T.Arm = repmat("Right",N,1);
end
if ismember('Experiment',T.Properties.VariableNames)
    T.Experiment = string(T.Experiment);
    tossDistal = false;
else
    T.Experiment = repmat("Fitts",N,1);
    tossDistal = true;
end
if ismember('TMSiFileFlexProx',T.Properties.VariableNames)
    if all(isempty(T.TMSiFileFlexProx))
        T.TMSiFileFlexProx = [];
    else
        T.TMSiFileFlexProx = string(T.TMSiFileFlexProx);
    end
end
if ismember('TMSiFileFlexDist',T.Properties.VariableNames)
    if tossDistal
        T.TMSiFileFlexDist = [];
    else
        if all(isempty(T.TMSiFileFlexDist))
            T.TMSiFileFlexDist = [];
        else
            T.TMSiFileFlexDist = string(T.TMSiFileFlexDist);
        end
    end
end
if ismember('TMSiFileExtProx',T.Properties.VariableNames)
    if all(isempty(T.TMSiFileExtProx))
        T.TMSiFileExtProx = [];
    else
        T.TMSiFileExtProx = string(T.TMSiFileExtProx);
    end
end
if ismember('TMSiFileExtDist',T.Properties.VariableNames)
    if tossDistal
        T.TMSiFileExtDist = [];
    else
        if all(isempty(T.TMSiFileExtDist))
            T.TMSiFileExtDist = [];
        else
            T.TMSiFileExtDist = string(T.TMSiFileExtDist);
        end
    end
end
if any(contains(T.Experiment,"Gestures"))

    gestures_order_file = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,"trial_order*"));
    gestures_order = readtable(fullfile(gestures_order_file(1).folder,gestures_order_file(1).name),'ReadVariableNames',false);
    gestures_order.Properties.VariableNames = {'Joint', 'Movement'};
    i_gesture = 0;
end

for ii = 1:N
    if ismember('Task',T.Properties.VariableNames)
        tmp = strsplit(string(T.Task(ii))," ");
        tmp = lower(tmp);
        for ik = 1:numel(tmp)
            tmp2 = char(tmp(ik));
            tmp2(1) = upper(tmp2(1));
            tmp(ik) = tmp2;
        end
        T.Task(ii) = strjoin(tmp, " ");
    end
    if options.ProximalOnPrakarshGUI
        if contains(T.Experiment(ii),"Gesture")
            i_gesture = i_gesture + 1;
            if ismember('Task',T.Properties.VariableNames)
                T.Task(ii) = sprintf("%s %s", gestures_order.Joint{ii}, gestures_order.Movement{ii});
            end
            if ismember('Task', T.Properties.VariableNames)
                Ff = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderProximalFlexor,T.Task(ii),"*.poly5"));
                Fe = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderProximalExtensor,T.Task(ii),"*.poly5"));
            else
                Ff = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderProximalFlexor,sprintf('%s %s', T.Joint(ii), T.Movement(ii)),"*.poly5"));
                Fe = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderProximalExtensor,sprintf('%s %s', T.Joint(ii), T.Movement(ii)),"*.poly5"));
            end
        else
            Ff = dir(fullfile(TANK_FOLDER,options.FeedbackSubfolder, options.SubFolderProximalFlexor, sprintf("trial_%d_*",T.Trial(ii))));
            Fe = dir(fullfile(TANK_FOLDER,options.FeedbackSubfolder, options.SubFolderProximalExtensor, sprintf("trial_%d_*",T.Trial(ii))));
        end
        if ismember('TMSiFileFlexDist',T.Properties.VariableNames)
            if startsWith(T.TMSiFileFlexDist(ii),"MCP")
                T.TMSiFileFlexDist(ii) = fullfile(options.SubFolderDistalFlexor, options.SubFolderDistalFlexor, T.TMSiFileFlexDist(ii));
            else
                fname = fullfile(TANK_FOLDER,options.SubFolderDistalFlexor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderDistalFlexor,T.TMSiFileFlexDist(ii)));
                if exist(fname,'file')==0
                    D = dir(fullfile(TANK_FOLDER, options.SubFolderDistalFlexor, sprintf(options.Poly5FormatIdentifierDistalFlexor,T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileFlexDist(ii) = fullfile(options.SubFolderDistalFlexor, D(end).name);
                    end
                else
                    T.TMSiFileFlexDist(ii) = fullfile(options.SubFolderDistalFlexor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderDistalFlexor,T.TMSiFileFlexDist(ii)));
                end
            end
        end

        if ismember('TMSiFileFlexProx',T.Properties.VariableNames)
            if contains(T.Experiment(ii),"Gesture")
                i_flex_dist = contains({Ff(end).name},options.DeviceFlexProx);
                if sum(i_flex_dist) > 0
                    tmp = fullfile(Ff(i_flex_dist).folder,Ff(i_flex_dist).name);
                    T.TMSiFileFlexProx(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileFlexProx(ii),filesep)
                        tmp = char(T.TMSiFileFlexProx(ii));
                        T.TMSiFileFlexProx(ii) = tmp(2:end);
                    end
                end
            else
                i_flex_dist = contains({Ff(end).name},'FLX');
                if sum(i_flex_dist) > 0
                    tmp = fullfile(Ff(i_flex_dist).folder,Ff(i_flex_dist).name);
                    T.TMSiFileFlexProx(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileFlexProx(ii),filesep)
                        tmp = char(T.TMSiFileFlexProx(ii));
                        T.TMSiFileFlexProx(ii) = tmp(2:end);
                    end
                else
                    D = dir(fullfile(TANK_FOLDER, options.FeedbackSubfolder, options.SubFolderProximalFlexor, sprintf('trial_%d_*',T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileFlexProx(ii) = fullfile(options.FeedbackSubfolder, options.SubFolderProximalFlexor, D(end).name);
                    end
                end
            end
        end

        if ismember('TMSiFileExtDist',T.Properties.VariableNames)
            if startsWith(T.TMSiFileExtDist(ii),"MCP")
                T.TMSiFileExtDist(ii) = fullfile(options.SubFolderDistalExtensor, T.TMSiFileExtDist(ii));
            else
                fname = fullfile(TANK_FOLDER,options.SubFolderDistalExtensor, sprintf('%s_%04d_%02d_%02d_%s_%d.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderDistalFlexor,T.Trial(ii)));
                if exist(fname,'file')==0
                    D = dir(fullfile(TANK_FOLDER,options.SubFolderDistalExtensor, sprintf(options.Poly5FormatIdentifierDistalExtensor,T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileExtDist(ii) = fullfile(options.SubFolderDistalExtensor, D(end).name);
                    end
                else
                    T.TMSiFileExtDist(ii) = fullfile(options.SubFolderDistalExtensor, sprintf('%s_%04d_%02d_%02d_%s_%d.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderDistalFlexor,T.Trial(ii)));
                end
            end
        end

        if ismember('TMSiFileExtProx',T.Properties.VariableNames)
            if contains(T.Experiment(ii),"Gesture")
                i_ext_dist = contains({Fe(end).name},options.DeviceExtProx);
                if sum(i_ext_dist) > 0
                    tmp = fullfile(Fe(i_ext_dist).folder,Fe(i_ext_dist).name);
                    T.TMSiFileExtProx(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileExtProx(ii),filesep)
                        tmp = char(T.TMSiFileExtProx(ii));
                        T.TMSiFileExtProx(ii) = tmp(2:end);
                    end
                end
            else
                i_ext_dist = contains({Fe(end).name},'EXT');
                if sum(i_ext_dist) > 0
                    tmp = fullfile(Fe(i_ext_dist).folder,Fe(i_ext_dist).name);
                    T.TMSiFileExtProx(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileExtProx(ii),filesep)
                        tmp = char(T.TMSiFileExtProx(ii));
                        T.TMSiFileExtProx(ii) = tmp(2:end);
                    end
                else
                    D = dir(fullfile(TANK_FOLDER, options.FeedbackSubfolder, options.SubFolderProximalExtensor, sprintf('trial_%d_*',T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileExtProx(ii) = fullfile(options.FeedbackSubfolder, options.SubFolderProximalExtensor, D(end).name);
                    end
                end
            end
        end
    else % Distal is on Prakarsh GUI
        if contains(T.Experiment(ii),"Gesture")
            i_gesture = i_gesture + 1;
            if ismember('Task',T.Properties.VariableNames)
                T.Task(ii) = sprintf("%s %s", gestures_order.Joint{ii}, gestures_order.Movement{ii});
            end
            if ismember('Task', T.Properties.VariableNames)
                Ff = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderDistalFlexor,T.Task(ii),"*.poly5"));
                Fe = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderDistalExtensor,T.Task(ii),"*.poly5"));
            else
                Ff = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderDistalFlexor,sprintf('%s %s', T.Joint(ii), T.Movement(ii)),"*.poly5"));
                Fe = dir(fullfile(TANK_FOLDER,options.GesturesSubfolder,options.SubFolderDistalExtensor,sprintf('%s %s', T.Joint(ii), T.Movement(ii)),"*.poly5"));
            end
        else
            Ff = dir(fullfile(TANK_FOLDER,options.FeedbackSubfolder, options.SubFolderDistalFlexor, sprintf("trial_%d_*",T.Trial(ii))));
            Fe = dir(fullfile(TANK_FOLDER,options.FeedbackSubfolder, options.SubFolderDistalExtensor, sprintf("trial_%d_*",T.Trial(ii))));
        end
        if ismember('TMSiFileFlexProx',T.Properties.VariableNames)
            if startsWith(T.TMSiFileFlexProx(ii),"MCP")
                T.TMSiFileFlexProx(ii) = fullfile(options.SubFolderProximalFlexor, options.SubFolderProximalFlexor, T.TMSiFileFlexProx(ii));
            else
                fname = fullfile(TANK_FOLDER,options.SubFolderProximalFlexor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderProximalFlexor,T.TMSiFileFlexProx(ii)));
                if exist(fname,'file')==0
                    D = dir(fullfile(TANK_FOLDER, options.SubFolderProximalFlexor, sprintf(options.Poly5FormatIdentifierProximalFlexor,T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileFlexProx(ii) = fullfile(options.SubFolderProximalFlexor, D(end).name);
                    end
                else
                    T.TMSiFileFlexProx(ii) = fullfile(options.SubFolderProximalFlexor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderProximalFlexor,T.TMSiFileFlexProx(ii)));
                end
            end
        end

        if ismember('TMSiFileFlexDist',T.Properties.VariableNames)
            if contains(T.Experiment(ii),"Gesture")
                i_flex_dist = contains({Ff(end).name},options.DeviceFlexDist);
                if sum(i_flex_dist) > 0
                    tmp = fullfile(Ff(i_flex_dist).folder,Ff(i_flex_dist).name);
                    T.TMSiFileFlexDist(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileFlexDist(ii),filesep)
                        tmp = char(T.TMSiFileFlexDist(ii));
                        T.TMSiFileFlexDist(ii) = tmp(2:end);
                    end
                end
            else
                i_flex_dist = contains({Ff(end).name},'FLX');
                if sum(i_flex_dist) > 0
                    tmp = fullfile(Ff(i_flex_dist).folder,Ff(i_flex_dist).name);
                    T.TMSiFileFlexDist(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileFlexDist(ii),filesep)
                        tmp = char(T.TMSiFileFlexDist(ii));
                        T.TMSiFileFlexDist(ii) = tmp(2:end);
                    end
                else
                    D = dir(fullfile(TANK_FOLDER, options.FeedbackSubfolder, options.SubFolderDistalFlexor, sprintf('trial_%d_*',T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileFlexDist(ii) = fullfile(options.FeedbackSubfolder, options.SubFolderDistalFlexor, D(end).name);
                    end
                end
            end
        end

        if ismember('TMSiFileExtProx',T.Properties.VariableNames)
            if startsWith(T.TMSiFileExtProx(ii),"MCP")
                T.TMSiFileExtProx(ii) = fullfile(options.SubFolderProximalExtensor, T.TMSiFileExtProx(ii));
            else
                fname = fullfile(TANK_FOLDER,options.SubFolderProximalFlexor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderProximalFlexor,T.TMSiFileFlexProx(ii)));
                if exist(fname,'file')==0
                    D = dir(fullfile(TANK_FOLDER,options.SubFolderProximalExtensor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderProximalFlexor,T.TMSiFileExtProx(ii))));
                    if numel(D) == 1
                        T.TMSiFileExtProx(ii) = fullfile(options.SubFolderProximalExtensor, D(end).name);
                    end
                else
                    T.TMSiFileExtProx(ii) = fullfile(options.SubFolderProximalExtensor, sprintf('%s_%04d_%02d_%02d_%s_%s.poly5',options.Subject,options.Year,options.Month,options.Day,options.SubFolderProximalFlexor,T.TMSiFileExtProx(ii)));
                end
            end
        end

        if ismember('TMSiFileExtDist',T.Properties.VariableNames)
            if contains(T.Experiment(ii),"Gesture")
                i_ext_dist = contains({Fe(end).name},options.DeviceExtDist);
                if sum(i_ext_dist) > 0
                    tmp = fullfile(Fe(i_ext_dist).folder,Fe(i_ext_dist).name);
                    T.TMSiFileExtDist(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileExtDist(ii),filesep)
                        tmp = char(T.TMSiFileExtDist(ii));
                        T.TMSiFileExtDist(ii) = tmp(2:end);
                    end
                end
            else
                i_ext_dist = contains({Fe(end).name},'EXT');
                if sum(i_ext_dist) > 0
                    tmp = fullfile(Fe(i_ext_dist).folder,Fe(i_ext_dist).name);
                    T.TMSiFileExtDist(ii) = strrep(tmp,TANK_FOLDER,"");
                    if startsWith(T.TMSiFileExtDist(ii),filesep)
                        tmp = char(T.TMSiFileExtDist(ii));
                        T.TMSiFileExtDist(ii) = tmp(2:end);
                    end
                else
                    D = dir(fullfile(TANK_FOLDER, options.FeedbackSubfolder, options.SubFolderDistalExtensor, sprintf('trial_%d_*',T.Trial(ii))));
                    if numel(D) == 1
                        T.TMSiFileExtDist(ii) = fullfile(options.FeedbackSubfolder, options.SubFolderDistalExtensor, D(end).name);
                    end
                end
            end
        end
    end
end

if ismember('Task', T.Properties.VariableNames)
    T = movevars(T,'Task',"Before",'Arm');
end

end