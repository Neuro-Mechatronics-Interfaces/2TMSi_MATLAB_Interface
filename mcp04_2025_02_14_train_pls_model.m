%MCP04_2025_02_14_TRAIN_PLS_MODEL

clear;
clc;

SUBJ = "MCP04";
YYYY = 2025;
MM = 2;
DD = 14;

% These are specific to the ordering of gestures ("TRIAL")
BLOCK = [1;4;5;6;7];
ENCODING = [0 -1      0; ... % Right-handed wrist flex
            0  1      0; ... % Right-handed wrist ext
           -1 0       0; ... % Right-handed radial dev
            1  0      0; ... % Right-handed ulnar dev
            0  0      1  ... % Right-handed supination
            ];

[X,Y,BETA] = train_cosmo_decoder(SUBJ,YYYY,MM,DD,BLOCK,ENCODING, ...
    'DataRoot', 'C:/Data/MetaWB', ...
    'DataSubfolder', 'TMSi');

Y_hat = [ones(size(X,1),1),X] * BETA;