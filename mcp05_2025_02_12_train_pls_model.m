%MCP05_2025_02_12_TRAIN_PLS_MODEL

clear;
clc;

SUBJ = "MCP05";
YYYY = 2025;
MM = 2;
DD = 12;

% These are specific to the ordering of gestures ("TRIAL")
BLOCK = (1:6)';
ENCODING = [0 1 0; ... % Left-handed wrist ext
            0 0 1; ... % Left-handed ring flex
            0 -1 0; ... % Left-handed wrist flex
            -1 0 0; ... % Left-handed ulnar dev
            1 0 0; ... % Left-handed radial dev
            0 0.25 0.5; ... % Left-handed thumb ext
            ];

[X,Y,BETA] = train_cosmo_decoder(SUBJ,YYYY,MM,DD,BLOCK,ENCODING, ...
    'DataRoot', 'C:/Data/MetaWB', ...
    'DataSubfolder', 'TMSi');

Y_hat = [ones(size(X,1),1),X] * BETA;