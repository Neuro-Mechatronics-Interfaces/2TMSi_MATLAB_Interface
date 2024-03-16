function runInstructionSequence(udpSender, seq, instructionProgress, address, port, options)
%RUNINSTRUCTIONSEQUENCE Run sequence of instructed commands, indicating state in progress bar.
arguments
    udpSender
    seq (:,2) cell
    instructionProgress
    address
    port
    options.LabelSamples (1,1) double {mustBePositive, mustBeInteger} = 8000;
    options.SampleRate (1,1) double {mustBePositive, mustBeInteger} = 4000;
    options.NProgressChunk (1,1) double {mustBePositive, mustBeInteger} = 10;
end

t_pause = (options.LabelSamples / options.SampleRate) / options.NProgressChunk;
instructionProgress.Indeterminate = 'off';

for ii = 1:size(seq,1)
    writeline(udpSender, ...
        sprintf('l.%s:%d', seq{ii,2}, options.LabelSamples), ...
        address, ...
        port);
    pause(0.025);
    instructionProgress.Value = 0;
    instructionProgress.Message = seq{ii,1};
    drawnow();
    for iChunk = 1:options.NProgressChunk
        pause(t_pause);
        instructionProgress.Value = iChunk/options.NProgressChunk;
        drawnow();
    end
end

end