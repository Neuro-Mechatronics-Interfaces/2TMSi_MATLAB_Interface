function [name, fname] = meta_wb_table_2_name(C)
%META_WB_TABLE_2_NAME Return cell array of names for each table row entry.
name = cell(size(C,1),1);
fname = cell(size(name));
for ii = 1:size(C,1)
    if contains(C.Experiment{ii},'Gesture')
        name{ii} = sprintf('Trial-%d: %s %s %s', C.Trial(ii), C.Arm{ii}, C.Joint{ii}, C.Movement{ii});
        fname{ii} = sprintf('Trial-%03d_%s-%s-%s_GESTURE', C.Trial(ii), C.Arm{ii}, C.Joint{ii}, C.Movement{ii});
    else
        name{ii} = sprintf('Trial-%d: %s %s %s Modulation %d%% MVC', C.Trial(ii), C.Arm{ii}, C.Joint{ii}, C.Movement{ii}, round(C.Level(ii)*100));
        fname{ii} = sprintf('Trial-%03d_%s-%s-%s_MOD-%03d-MVC', C.Trial(ii), C.Arm{ii}, C.Joint{ii}, C.Movement{ii}, round(C.Level(ii)*100));
    end
end


end