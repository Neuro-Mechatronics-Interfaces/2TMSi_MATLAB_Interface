function [x,y,focus] = parse_queued_pattern(self)
%PARSE_QUEUED_PATTERN  Parse queued pattern data

pdata = SAGA_Data_Server.parse_pattern_volume_string(self.Queued.Stim.pattern);
x = pdata.x;
y = pdata.y;
focus = pdata.focusing_level;
self.meta_data(self.Stimulus, :) = [x, y, focus, self.Queued.Stim.amplitude, self.block];

end