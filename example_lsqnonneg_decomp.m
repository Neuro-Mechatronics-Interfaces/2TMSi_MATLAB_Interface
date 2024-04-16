%EXAMPLE_LSQNONNEG_DECOMP

close all force;
clear;
clc;

POLY5_FILE = 'Max_2024_03_30_B_22.poly5';
N_MUAPS = 6;
FC_HIGH = 100;
T_USE = [4, 5];
N_SAMPLE_PLOTS = 3;

%% Load data and extract only UNI channel data from calibration segment
data = TMSiSAGA.Poly5.read(POLY5_FILE);
t = (0:(size(data.samples,2)-1))/data.sample_rate;
Y = data.samples(2:65,:);
[b,a] = butter(3,FC_HIGH/(data.sample_rate/2),'high');

%% Apply HPF and rectify
% In Stim-Artifact part we will use causal filter instead of filtfilt; so
% we can use that here as well (also it is very slightly faster):
Yf = filter(b,a,Y,[],2);
Yf(:,1:100) = 0; % Due to artifact from filter HPF initialization
t_sel = (t >= T_USE(1)) & (t < T_USE(2));
Yfc = Yf(:,t_sel);
% Yfr = Yf .* double(Yf > 0);
Yfcr = abs(Yfc);

%% Recover calibrated "compensation kernel"
[W,H] = nnmf(Yfcr,N_MUAPS,'Algorithm','als');

%% Extract snippets for MUAP templates
[snips, i_peaks] = nmf_2_templates(H,Yfc);

%% Generate random sampling vector to show subset of templates/filters
k = randsample(size(H,1),N_SAMPLE_PLOTS,false);

%% Plot examples of recovered MUAP Filters/Peak-Trains
close all force;
train_fig = plot_nmf(W,H,k);

%% Plot associated MUAP templates
template_fig = gobjects(numel(k),1);
for ii = 1:numel(k)
    template_fig(ii) = plot_templates(snips{k(ii)}, ...
        'Title', sprintf('MUAP-%d',k(ii)), ...
        'XYFigure',[20+200*(ii-1),50]);
end