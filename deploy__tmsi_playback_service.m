%DEPLOY__TMSI_PLAYBACK_SERVICE  Script that is executed by bat file for shortcut access.
clear; clc;
% % Toggle comments of hard-coded vs. gui to expedite debugging. % %

% % BEGIN HARD-CODED % % %
SUBJ = 'Forrest';        %
YYYY = 2022;             %
MM = 11;                 %
DD = 8;                  %
BLOCK = 9;               %
% % END HARD-CODED % % % %

% % % % BEGIN SELECTOR-GUI % % % % % % % % % % % % % % % % % % % % % % % % 
% fprintf(1, 'Please select playback file.');                            %
% [SUBJ, YYYY, MM, DD, ~, BLOCK] = MetaDataHandler.quick_selector_gui(...%
%     'Array', ["A", "B"], ...                                           %
%     'Name', 'Select Playback File', ...                                %
%     'Icon', 'record-player.png');                                      %
% % % % END SELECTOR-GUI % % % % % % % % % % % % % % % % % % % % % % % % %

fprintf(1,'Starting playback for %s_%04d_%02d_%02d: Block-%d ...\n', SUBJ, YYYY, MM, DD, BLOCK);
deploy__tmsi_playback(SUBJ, YYYY, MM, DD, BLOCK); % This is blocking.
fprintf(1,'\n\t\t->\tPlayback terminated successfully.\t\t<-\t\n\n\n');
pause(1.5);