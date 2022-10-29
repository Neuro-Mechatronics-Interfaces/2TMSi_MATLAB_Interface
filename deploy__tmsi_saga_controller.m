%DEPLOY__TMSI_SAGA_CONTROLLER - Script that runs GUI application for execution by Windows .bat executable. 
fprintf(1, "Opening TMSi-SAGA recording controller application...");
app = TMSi_Client(); 
fprintf(1, "complete.\n");
waitfor(app);
disp("TMSi-SAGA controller application closed.");