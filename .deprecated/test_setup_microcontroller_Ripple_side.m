%% PRINT THE NAMES OF COM PORTS TO GET AN IDEA OF WHAT IS WHERE...
clc;
clear;
serialportlist

%% SETUP FOR THE TMSi MICRONTROLLER INTERFACE
MEGA2560 = Microcontroller("Ripple", "COM7", "Ripple Serial Monitor");

% Increase the train length to 100.
MEGA2560.setTrainLength(100);

% Change the parameter key to 3.
MEGA2560.setParameterKey(3);

% Log some note.
MEGA2560.note('Mats you smell funny.');

%% EXAMPLE OF RUNNING INTERFACE VIA ASYNCHRONOUS CALLBACKS
MEGA2560.begin(); % Tell interface to begin recording
pause(2); 

% % % < E.G. COUNT NUMBER OF STIMS DELIVERED HERE > % % %
MEGA2560.next(); % Tell interface to stop recording
pause(2);

% % % < E.G. END CONDITION OF MAIN LOOP HERE > % % %
MEGA2560.shutdown();
disp('Completed test successfully!');