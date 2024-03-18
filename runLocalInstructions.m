function runLocalInstructions(timerObj, options)

arguments
    timerObj
    options.File {mustBeTextScalar} = "test.mat";
    options.Instructions (:,1) string = ["Lift left index." ; ...
                                         "Press left index."; ...
                                         "Lift left middle finger."; ...
                                         "Press left middle finger."; ...
                                         "Lift left ring finger."; ...
                                         "Press left ring finger."; ...
                                         "Lift right index."; ...
                                         "Press right index."; ...
                                         "Lift right middle finger."; ...
                                         "Press right middle finger."; ...
                                         "Lift right ring finger."; ...
                                         "Press right ring finger."; ...
                                         "Rest"; ...
                                         "Flex right wrist."; ...
                                         "Extend right wrist."; ...
                                         "Flex left wrist."; ...
                                         "Extend left wrist."; ...
                                         "Ulnar deviate right wrist."; ...
                                         "Radial deviate right wrist."; ...
                                         "Ulnar deviate left wrist."; 
                                         "Radial deviate left wrist."];
    options.PoseDuration = 4;
    options.SamplePeriod = 0.05;
    options.PrepPeriod = 1.0;
end

m = matfile(options.File, 'Writable', true);
m.Y = zeros(0,1);
m.X = zeros(0,timerObj.UserData.NTotal);
m.Pose = zeros(0,1,'int32');

fig = uifigure('Name', 'Local Instruction Sequence', 'Color', 'w');
prog = uiprogressdlg(fig);
prog.Message = "Starting sequence.";
nTotalInstructions = numel(options.Instructions);
pause(options.PoseDuration*0.25);
stop(timerObj);
timerObj.TimerFcn = @(src,~)save_data_callback(src,m);
timerObj.Period = options.SamplePeriod;
start(timerObj);
for ii = 1:nTotalInstructions
    prog.Message = sprintf("Next: %s", options.Instructions(ii));
    timerObj.UserData.CurrentAssignedPose = -1;
    drawnow();
    pause(options.PrepPeriod);
    prog.Message = sprintf("GO! (%s)", options.Instructions(ii));
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