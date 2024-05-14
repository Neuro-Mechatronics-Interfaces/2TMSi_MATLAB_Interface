%EXAMPLE_INITIALIZE_DECOMPOSITION  Example initializing decomposition for CKC using Max technique.
clear;
clc;

% TANK = "Max_2024_03_30";
% BLOCK = 22;
% SAGA = "B";

TANK = "MCP02_2024_03_27";
BLOCK = 4;
SAGA = "B";
AUX_SCALE = 45;

FIGURE_OUTPUT_FOLDER = sprintf("figures/%s/%s-%02d",TANK,SAGA,BLOCK);
N_PC = [24];

data = TMSiSAGA.Poly5.read(sprintf('%s_%s_%d.poly5', TANK, SAGA, BLOCK)); 
uni = ckc.preproc__hpf_exclude_interp_del2(data.samples(2:65,:));

%% Initialize decomposition
if exist('R_inv','var')==0
    [IPTs, MUPulses, info, t, R_inv] = ckc.initialize_decomposition(uni, data.sample_rate, 'NumPCs', N_PC);
else
     [IPTs, MUPulses, info, t, R_inv] = ckc.initialize_decomposition(uni, data.sample_rate, 'NumPCs', N_PC, 'InverseCovarianceMatrix',R_inv);
end


%% Plot figures
% Display IPTs
[fig, MU_ID, recruitmentOrder] = ckc.plotIPTsFast(t, MUPulses, IPTs, 'Title', TANK);
utils.save_figure(fig,FIGURE_OUTPUT_FOLDER,"Fast-IPTs");

% Display the instantaneous discharge rates
fig = ckc.plotIDR(MUPulses,MU_ID,[uni(4,:); data.samples(73,:).*AUX_SCALE], data.sample_rate, 'Title',TANK);
utils.save_figure(fig,FIGURE_OUTPUT_FOLDER,"Instantaneous Discharge Rates");