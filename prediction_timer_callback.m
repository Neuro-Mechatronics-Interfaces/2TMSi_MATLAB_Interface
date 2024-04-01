function prediction_timer_callback(timerObj, ~)

keys_to_check = [1:6,8:11];
key_codes = '4682yblaxr';

if ~isempty(timerObj.UserData.Net)
    delete(timerObj.UserData.h.bar);
    timerObj.UserData.h.history = 0.2 * timerObj.UserData.Net([timerObj.UserData.A.y; timerObj.UserData.B.y])' + 0.8 * timerObj.UserData.h.history;
    timerObj.UserData.h.bar = bar(timerObj.UserData.h.ax, 1:12, timerObj.UserData.h.history, 'FaceColor', 'k');
    drawnow();
end

% if ~isempty(timerObj.UserData.Net) && ~isempty(timerObj.UserData.XBoxClient)
%     pred = timerObj.UserData.Net([timerObj.UserData.A.y; timerObj.UserData.B.y]);
%     client = timerObj.UserData.XBoxClient;
%     for ii = 1:10
%         if timerObj.UserData.History(ii)
%             if pred(keys_to_check(ii)) < 0.5
%                 writeline(client, [key_codes(ii), '1']);
%             end
%             timerObj.UserData.History(ii) = false;
%         else
%             if pred(keys_to_check(ii)) > 0.5
%                 writeline(client, [key_codes(ii), '0']);
%             end
%             timerObj.UserData.History(ii) = true;
%         end
%     end
% end

end