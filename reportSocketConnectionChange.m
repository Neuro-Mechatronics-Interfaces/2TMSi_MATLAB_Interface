function reportSocketConnectionChange(src, event)
if strcmp(event.EventName, 'connected')
    disp('Client connected!');
    writeline(src, "200");
elseif strcmp(event.EventName, 'disconnected')
    disp('Client disconnected!');
    writeline(src, "1000");
end


end
