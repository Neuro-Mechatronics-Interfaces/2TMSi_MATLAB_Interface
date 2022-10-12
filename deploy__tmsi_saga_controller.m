%DEPLOY__TMSI_SAGA_CONTROLLER - Script that runs GUI application for execution by Windows .bat executable. 
disp("Opening controller application...");
app = gui__tmsi_client; 
waitfor(app);
disp("Controller application closed.");