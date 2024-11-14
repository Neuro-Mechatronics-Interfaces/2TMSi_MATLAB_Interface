function [PNR, PNR_Label] = batch_compute_PNR_and_Label(data)
%BATCH_COMPUTE_PNR_AND_LABEL Compute PNR on batch loaded/cleaned data
%
% Syntax:
%   [PNR, PNR_Label] = batch_compute_PNR_and_Label(data);
%
% Example
%   data = load('C:\Data\Shared\MCP01_2024_04_12\MotorUnits Decomposition\Max\Decomposition Output Cleaned\MCP01_2024_04_12_19_synchronized_offset0_length142.459_runs50_manual-clean.mat');
%   [PNR, PNR_Label] = batch_compute_PNR_and_Label(data);

N = numel(data.MUPulses);
PNR = nan(N,1);
PNR_Label = cell(1,N);
for ii = 1:N
    PNR(ii) = ckc.compute_PNR(data.MUPulses{ii},data.IPTs(ii,:),data.fsamp);
    PNR_Label{ii} = sprintf('%s (%4.1f dB)', data.MUIDs{ii}, round(PNR(ii),1));
end
end