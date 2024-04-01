function runLocalInstructions(timerObj, options)
%RUNLOCALINSTRUCTIONS Runs sequence instructing user to perform a series of gestures/movements.

arguments
    timerObj
    options.File {mustBeTextScalar} = "test.mat";
    options.Instructions {mustBeTextScalar} = 'unilateral_hand_sequence'
    options.PoseDuration = 4;
    options.SamplePeriod = 0.05;
    options.PrepPeriod = 1.0;
    options.Reps = 2;
end
nExpectedSamples = (options.PrepPeriod + options.PoseDuration)*options.Reps / options.SamplePeriod;
m = matfile(options.File, 'Writable', true);
m.Y = nan(nExpectedSamples,1);
m.X = nan(0,timerObj.UserData.NTotal);
timerObj.UserData.CurrentIndex = 1;


instructions = parse_instruction_sequence(options.Instructions);

fig = uifigure('Name', 'Local Instruction Sequence', 'Color', 'w');
prog = uiprogressdlg(fig);
prog.Message = "Starting sequence.";
nTotalInstructions = numel(instructions);
pause(options.PoseDuration*0.25);
stop(timerObj);
timerObj.TimerFcn = @(src,~)save_data_callback(src,m);
timerObj.Period = options.SamplePeriod;
start(timerObj);
iCount = 0;
for iRep = 1:options.Reps
    for ii = 1:nTotalInstructions
        prog.Message = sprintf("Next: %s", instructions(ii));
        timerObj.UserData.CurrentAssignedPose = -1;
        drawnow();
        pause(options.PrepPeriod);
        prog.Message = sprintf("GO! (%s)", instructions(ii));
        timerObj.UserData.CurrentAssignedPose = ii;
        waitTic = tic;
        while toc(waitTic) < options.PoseDuration
            pause(options.SamplePeriod/2);
        end
        timerObj.UserData.CurrentAssignedPose = 0;
        iCount = iCount + 1;
        prog.Value = iCount / (nTotalInstructions*options.Reps);
    end
end
stop(timerObj);
prog.Message = "Complete!";
pause(0.1);
delete(m);
delete(fig);

end