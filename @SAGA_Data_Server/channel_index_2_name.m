function [tag, chname] = channel_index_2_name(ch)           
%CHANNEL_INDEX_2_NAME Parses the string representation of SAGA (tag) and channel name given channel index and assuming fixed indexing scheme
%
% Syntax:
%   [tag,chname] = SAGA_Data_Server.channel_index_2_name(ch);
%
% Inputs
%   ch - Channel index (between 1 and 136, for all UNI and BIP channels on
%                       two SAGAs where 1:64 is UNI from "A", 65:68 is BIP
%                       from "A", 69:132 is UNI from "B", and 133:136 is
%                       BIP from "B").
%
% Output
%   tag - "A" or "B"
%   chname - "UNI-%02d" or "BIP-%02d" with a relative indexing of the
%               channel-type, within each SAGA (e.g. index 135 is BIP-03).
%
% See also: Contents, SAGA_Data_Server

if ch < 70
    tag = "A";
else
    tag = "B";
    ch = ch - 69;
end

if ch < 65
    s = "UNI";
else
    s = "BIP";
    ch = ch - 64;
end

chname = sprintf("%s-%02d", s, ch);

end