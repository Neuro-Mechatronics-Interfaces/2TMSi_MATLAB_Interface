%DEPLOY__TMSI_SAGA_CONTROLLER - Script that runs GUI application for execution by Windows .bat executable. 
clear; clc;
fprintf(1, "Opening (NHP) 2-TMSi-SAGA controller application...\n");
config_file = parameters('config');
fprintf(1,'\t->\tUsing %s configuration.\n', config_file);
config = parse_main_config(config_file);
app = TMSi_Client(config); 
fprintf(1, "\n\n\t\t->\t[%s] Controller running.\t\t<-\t\n\n\n", string(datetime('now')));
waitfor(app);
disp("TMSi-SAGA controller application closed.");