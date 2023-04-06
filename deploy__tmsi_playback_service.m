%DEPLOY__TMSI_PLAYBACK_SERVICE  Script that is executed by bat file for shortcut access.
clear; clc;
% % Toggle comments of hard-coded vs. gui to expedite debugging. % %

% % BEGIN HARD-CODED % % %
SUBJ = 'Forrest';        %
YYYY = 2022;             %
MM = 11;                 %
DD = 8;                  %
BLOCK = 8;               %
% % END HARD-CODED % % % %

% % % % BEGIN SELECTOR-GUI % % % % % % % % % % % % % % % % % % % % % % % % 
% fprintf(1, 'Please select playback file.');                            %
% [SUBJ, YYYY, MM, DD, ~, BLOCK] = MetaDataHandler.quick_selector_gui(...%
%     'Array', ["A", "B"], ...                                           %
%     'Name', 'Select Playback File', ...                                %
%     'Icon', 'record-player.png');                                      %
% % % % END SELECTOR-GUI % % % % % % % % % % % % % % % % % % % % % % % % %

fprintf(1,'[PLAYBACK]\tStarting playback for %s_%04d_%02d_%02d: Block-%d ...\n', SUBJ, YYYY, MM, DD, BLOCK);
try
    deploy__tmsi_playback2(SUBJ, YYYY, MM, DD, BLOCK); 
    fprintf(1,'\n[PLAYBACK]\t\t->\tPlayback terminated successfully.\t\t<-\t\n\n\n');
    pause(1.5);
catch me
    if exist('node','var')~=0
        delete(node);
    end
    if exist('device','var')~=0
        delete(device);
    end
    disp(me);
    for ii = 1:numel(me.stack)
        fprintf(1,'%s:: <%s> :: Line %d\n', ...
            me.stack(ii).file, me.stack(ii).name, me.stack(ii).line);
    end
    pause(15.0);
end
