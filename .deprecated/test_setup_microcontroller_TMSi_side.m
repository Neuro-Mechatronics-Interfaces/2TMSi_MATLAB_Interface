%% PRINT THE NAMES OF COM PORTS TO GET AN IDEA OF WHAT IS WHERE...
clc;
clear;
serialportlist

%% SETUP FOR THE TMSi MICRONTROLLER INTERFACE
MEGA2560 = Microcontroller("TMSi", "COM5", "TMSi Serial Monitor");

%% EXAMPLE OF RUNNING INTERFACE VIA ASYNCHRONOUS CALLBACKS
MEGA2560.begin(); % Tell interface to begin recording
pause(2); 

% % % < E.G. COUNT NUMBER OF STIMS DELIVERED HERE > % % %
MEGA2560.next(); % Tell interface to stop recording
pause(2);

% % % < E.G. END CONDITION OF MAIN LOOP HERE > % % %
MEGA2560.shutdown();
disp('Completed test successfully!');

