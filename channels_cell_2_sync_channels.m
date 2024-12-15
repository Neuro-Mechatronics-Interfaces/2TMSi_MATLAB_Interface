function ch = channels_cell_2_sync_channels(dev_ch)
if ~iscell(dev_ch)
    dev_ch = {dev_ch};
end
ch = [];
offset = 0;
for iCh = 1:numel(dev_ch)
    tmp = dev_ch{iCh}.toStruct(offset);
    ch = [ch, tmp];
    offset = numel(ch);
end
end