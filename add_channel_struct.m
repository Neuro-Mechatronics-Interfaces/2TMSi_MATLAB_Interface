function ch = add_channel_struct(ch, name, unit, tag, sn)
%ADD_CHANNEL_STRUCT Adds a new channel to the active-channels channel structure array returned from TMSiSAGA.Device.getActiveChannels().
%
%   ch = ADD_CHANNEL_STRUCT(ch, name, unit, tag, sn) appends a new channel
%   structure to the provided array of channel structures, defining
%   properties such as name, unit, tag, and serial number.
%
%   Input:
%       ch   - (1,:) struct Array of existing channel structures.
%       name - (string) Name of the new channel.
%       unit - (string) Unit of measurement for the new channel. Default: '-'.
%       tag  - (string) Tag identifier for the channel. Default: "X".
%       sn   - (int64) Serial number associated with the channel. Default: -1.
%
%   Output:
%       ch - Updated array of channel structures including the newly added channel.
%
%   Example:
%       ch = device.getActiveChannels();
%       channels = add_channel_struct(channels, 'JoyPx', '-', "J", -1);
%
%   See also: ACTIVE_CHANNELS_2_SYNC_CHANNELS

arguments
    ch  (1,:) struct
    name {mustBeTextScalar}
    unit {mustBeTextScalar} = '-';
    tag {mustBeTextScalar} = "X";
    sn (1,1) int64 = -1
end

new_ch = struct('ChanNr', numel(ch)+1, 'ChanDivider', 0, 'AltChanName', name, 'name', name, 'type', 3, 'sn', sn, 'tag', tag, 'unit_name', unit);
ch = [ch, new_ch];

end