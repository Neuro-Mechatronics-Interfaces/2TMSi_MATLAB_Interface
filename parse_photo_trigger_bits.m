function [sync, sync_names] = parse_photo_trigger_bits(trigger_channel_data)
%PARSE_PHOTO_TRIGGER_BITS  Parses sync signals from 4 photodetectors on wrist task.
%
% Syntax:
%   [sync, sync_names] = parse_photo_trigger_bits(trigger_channel_data);
%
% Inputs:
%   trigger_channel_data - Data samples from TRIGGERS channel.
%
% Output:
%   sync - TTL streams related to the events in sync_names. 1 indicates
%           that the state is currently true (graphics object indicating
%           that state is currently on the screen).
%                   (if input is a row vector, sync is returned as
%                       4 x nSamples; 
%                   if input is column vector, sync is nSamples x 4).
%
%   sync_names - The names corresponding to the 4 rows or columns of `sync`


n = numel(trigger_channel_data);
b = fliplr(dec2bin(reshape(15 - trigger_channel_data, n,1), 4));
sync = false(n, 4);
for ii = 1:4
    sync(:,ii) = b(:,ii) == '0'; % When TTL is "HIGH" then signal goes "LOW"
end
sync = double(sync);

if size(trigger_channel_data,1)==1
    sync = sync';
end

if nargout > 1
    sync_names = ["InnerVisible", "InnerHit", "OuterVisible", "OuterHit"];
end
end