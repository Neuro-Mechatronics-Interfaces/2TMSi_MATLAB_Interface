function [S, labels, Y, instructionList] = parse_instruction_triggers(samples,options)
%PARSE_INSTRUCTION_TRIGGERS  Parses instruction trigger labels/sequence.
%
% Syntax:
%   [S, labels, Y, instructionList] = parse_instruction_triggers(samples, 'Name', value, ...);
%
% Inputs:
%   samples - Trigger channel time-series data
%   
% Options:
%   'RestBit' (1,1) {mustBeInteger} = 1
%   'LabelsFile' {mustBeTextScalar} = 'configurations/instructions/InstructionList_Wrist2D.mat' - Set as '' to skip labeling.
%
% Output:
%   S - Table where rows have the Instruction class and start/stop samples
%   labels - Same size as input vector, but with values of zero at rest and
%               values according to `S.Instruction_Class` where not at
%               rest.
%   Y - Continuous multidimensional covariates with assumed structure
%           during discrete labeled epochs.
%
% See also: Contents

arguments
    samples (1,:) {mustBeNumeric}
    options.RestBit {mustBeInteger} = 1;
    options.KeepFirstRest (1,1) logical = true;
    options.LabelsFile {mustBeTextScalar} = 'configurations/instructions/InstructionList_Wrist2D.mat';
end

allBitsPresent = max(samples);
AT_REST = find(bitand(samples, 2^options.RestBit)==0);
enteringRest = AT_REST([options.KeepFirstRest, diff(AT_REST) > 1]);

NOT_AT_REST = find(bitand(samples, 2^options.RestBit) == 2^options.RestBit);
exitingRest = NOT_AT_REST([options.KeepFirstRest && NOT_AT_REST(1)~=1, diff(NOT_AT_REST)>1]);
N = numel(exitingRest);

Instruction_Starts = nan(N,1);
Instruction_Ends = nan(N,1);
Instruction_Value = nan(N,1);

for ii = 1:N
    Instruction_Starts(ii) = exitingRest(ii);
    Instruction_Ends(ii) = enteringRest(ii+1)-1;
    val = allBitsPresent - samples(exitingRest(ii)-1+find(samples(exitingRest(ii):enteringRest(ii+1))~=allBitsPresent,1,'first'));
    Instruction_Value(ii) = nextpow2(val);
end
Instruction_Class = findgroups(Instruction_Value);
S = table(Instruction_Value, Instruction_Class, Instruction_Starts, Instruction_Ends);
labels = zeros(size(samples));

for ii = 1:size(S,1)
    labels(1,S.Instruction_Starts(ii):S.Instruction_Ends(ii)) = S.Instruction_Class(ii);
end
Y = zeros(numel(unique(labels)),size(labels,2));

for ii = 2:size(Y,1)
    LABEL_HIGH = find(labels==(ii-1));
    label_rising = LABEL_HIGH([true, diff(LABEL_HIGH) > 1]);
    LABEL_LOW = find(labels~=(ii-1));
    label_falling = LABEL_LOW([true, diff(LABEL_LOW) > 1]);
    for ik = 1:numel(label_rising)
        i_rise = label_rising(ik);
        i_fall = label_falling(find(label_falling > i_rise, 1, 'first'));
        i_mid = round((i_rise+i_fall)/2);
        Y(ii,i_rise:i_mid) = linspace(0,1,numel(i_rise:i_mid));
        Y(ii,(i_mid+1):i_fall) = fliplr(linspace(0,1,numel((i_mid+1):i_fall)));
    end
end
Y(1,labels==0) = 1;

if strlength(options.LabelsFile) < 1
    instructionList = [];
    labels = categorical(labels);
else
    instructionList = string(getfield(load(options.LabelsFile, 'instructionList'),'instructionList'));
    if instructionList(1) == "REST"
        actualInstructions = reshape(instructionList(2:2:end),1,[]);
        restInstruction = instructionList(1);
    else
        restInstruction = "Rest";
        actualInstructions = instructionList;
    end
    labels = categorical(labels,0:max(labels),[restInstruction,actualInstructions]);
end
end