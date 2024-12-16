function ch = add_channel_struct(ch, name, unit, tag, sn)

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