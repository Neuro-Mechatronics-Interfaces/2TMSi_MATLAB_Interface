%EXAMPLE_BATCH_DECOMPOSITION_EXPORT Shows how to export for batch CKC decomposition.

close all force;
clear;
clc;

SUBJ = "MCP02";
YYYY = 2024;
MM = 3;
DD = 27;
INPUT_ROOT = sprintf("C:/Data/Shared/%s_%04d_%02d_%02d",SUBJ,YYYY,MM,DD);
% OUTPUT_SUBFOLDER = "MotorUnits Decomposition/Max/Decomposition Input";
OUTPUT_SUBFOLDER = "MotorUnits Decomposition/Decomposition Input";
% BITMASK = [2^8, 2^0, 2^8, 2^0]; % MCP01_2024_04_12
% INVERTLOGIC = [true, false, true, false]; % MCP01_2024_04_12
% BITMASK = [2^0, 2^0, 2^0, 2^0];  % MCP01_2024_02_20
% INVERTLOGIC = [true, false, true, false]; % MCP01_2024_02_20
BITMASK = [2^0, 2^2, 2^0, 2^2]; % MCP02_2024_03_27
INVERTLOGIC = [false, true, false, true]; % MCP02_2024_03_27

C = readtable(sprintf("%s/%s_%04d_%02d_%02d_Experiments-cleaned.csv", ...
                INPUT_ROOT, SUBJ, YYYY, MM, DD),'Delimiter',',', ...
                'ReadVariableNames',true,'VariableNamesRow',1);
desc = meta_wb_table_2_name(C);
N = size(C,1);
fprintf(1,'Pre-processing %d recordings...000%%\n',N);
for k = 1:N
    try
        poly5_files = [C.TMSiFileExtProx(k), ...
            C.TMSiFileExtDist(k), ...
            C.TMSiFileFlexProx(k), ...
            C.TMSiFileFlexDist(k)];
        if contains(C.Experiment{k},'Gesture')
            invertLogic = true(1,numel(INVERTLOGIC));
            syncSignal = [];
            syncTarget = [];
        else
            invertLogic = INVERTLOGIC;
            [p,~,~] = fileparts(fullfile(INPUT_ROOT,poly5_files(find(~INVERTLOGIC,1,'first'))));
            F = dir(fullfile(p,sprintf('trial_%d*_dev1_.mat',C.Trial(k))));
            if isempty(F)
                continue;
            end
            tmp = load(fullfile(F.folder, F.name));
            syncSignal = [tmp.time; tmp.force];
            syncTarget = tmp.target_profile';
            syncTarget(3:2:end,1) = syncTarget(3:2:end,1) + (1/2000);
        end
        ckc.pre_process_256_poly5(fullfile(INPUT_ROOT,OUTPUT_SUBFOLDER,sprintf('%s_%04d_%02d_%02d_%d_synchronized.mat',SUBJ,YYYY,MM,DD,C.Trial(k))), ...
            poly5_files{1}, ...
            poly5_files{2}, ...
            poly5_files{3}, ...
            poly5_files{4}, ...
            'DataRoot',INPUT_ROOT, ...
            'Description', desc{k}, ...
            'TriggerBitMask', BITMASK, ...
            'InvertSyncLogic',invertLogic, ...
            'Sync', syncSignal, ...
            'SyncTarget', syncTarget);
    catch me
        if ~strcmpi(me.identifier,"io:load_align_saga_data_many:no_sync")
            rethrow(me);
        end
    end
    fprintf(1,'\b\b\b\b\b%03d%%\n', round(100*k/N));
end