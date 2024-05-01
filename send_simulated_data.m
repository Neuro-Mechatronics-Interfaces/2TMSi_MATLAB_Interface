function send_simulated_data(src,~)

if src.UserData.srv.Connected
    writeline(src.UserData.srv, ...
        jsonencode(struct('Name','synth', ...
                    'Data',round([cos(src.UserData.theta);sin(src.UserData.theta)],3)*25, ...
                    'Event', "None")));
    src.UserData.theta = src.UserData.theta + 2*pi*src.Period;
end

end