function idx = find_channel_by(channels, field, val)
%FIND_CHANNEL_BY Identify TMSi SAGA channel from channels struct by field.
arguments
    channels
    field {mustBeMember(field,{'name', 'tag', 'unit', 'sn'})}
    val
end

switch field
    case 'name'
        idx = find(arrayfun(@(s)contains(s.alternative_name,val),channels));
    case 'tag'
        idx = find(arrayfun(@(s)strcmpi(s.tag,val),channels));
    case 'unit'
        idx = find(arrayfun(@(s)strcmpi(s.unit_name,val),channels));
    case 'sn'
        idx = find(arrayfun(@(s)s.sn==val,channels));

end


end