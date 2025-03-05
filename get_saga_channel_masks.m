function [iUni,iBip,iTrig,iCounter] = get_saga_channel_masks(channels, options)
%GET_SAGA_CHANNEL_MASKS Return logical indexing vector for different channel types based on channel names.
%
% Syntax:
%   [iUni, iBip, iTrig, iCounter] = get_saga_channel_masks(channels);
%   [...] = get_saga_channel_masks(channels,'Name',value,...);
%
% Inputs:
%   channels - Struct array with field `alternative_name` (or `name`). 
%   
% Options:
%   TriggerChannelIndicator {mustBeTextScalar} = 'TRIG';
%   CounterChannelIndicator {mustBeTextScalar} = 'COUNTER';
%   ReturnNumericIndices (1,1) logical = true;
%
% Output:
%   iUni - Indexing/logical mask for Unipolar grid channels (no CREF). 
%   iBip - Indexing/logical mask for Bipolar electrode channels.
%   iTrig - Indexing/logical mask for TRIGGER channels.  
%   iCounter - Indexing/logical mask for COUNTER channels. 
%
% See also: Contents
arguments
    channels
    options.TriggerChannelIndicator {mustBeTextScalar} = 'TRIG';
    options.CounterChannelIndicator {mustBeTextScalar} = 'COUNTER';
    options.ReturnNumericIndices (1,1) logical = true;
end
if isstruct(channels)
    if isfield(channels(1), 'alternative_name')
        ch_name = {channels.alternative_name};
    else
        ch_name = {channels.name};
    end
else
    ch_name = channels;
end
iUni = (contains(ch_name,'R') & contains(ch_name,'C') & ~contains(ch_name,'E')) | (contains(ch_name,'UNI'));
iBip = contains(ch_name,'BIP');
iTrig = contains(ch_name,options.TriggerChannelIndicator);
iCounter = contains(ch_name,options.CounterChannelIndicator);
if ~options.ReturnNumericIndices
    return;
end
iUni = find(iUni);
iBip = find(iBip);
iTrig = find(iTrig);
iCounter = find(iCounter);
end