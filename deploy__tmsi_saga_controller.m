%DEPLOY__TMSI_SAGA_CONTROLLER - Script that runs GUI application for execution by Windows .bat executable. 
fprintf(1, "Opening controller application...");
app = gui__tmsi_client; 
fprintf(1, "complete.\n");
waitfor(app);
disp("Controller application closed.");