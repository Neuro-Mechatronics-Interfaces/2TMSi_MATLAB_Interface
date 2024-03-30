function runLocalInstructions(timerObj, options)
%RUNLOCALINSTRUCTIONS Runs sequence instructing user to perform a series of gestures/movements.

arguments
    timerObj
    options.File {mustBeTextScalar} = "test.mat";
    options.Instructions {mustBeTextScalar} = 'unilateral_hand_sequence'
    options.PoseDuration = 4;
    options.SamplePeriod = 0.05;
    options.PrepPeriod = 1.0;
end

m = matfile(options.File, 'Writable', true);
m.Y = zeros(0,1);
m.X = zeros(0,timerObj.UserData.NTotal);
m.Pose = zeros(0,1,'int32');

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
    prog.Value = ii / nTotalInstructions;
end
stop(timerObj);
prog.Message = "Complete!";
pause(0.1);
delete(m);
delete(fig);

end