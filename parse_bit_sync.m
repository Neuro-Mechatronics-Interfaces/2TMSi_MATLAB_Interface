function [onset, offset, sync_data] = parse_bit_sync(varargin)
%PARSE_BIT_SYNC  Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector
%
% Syntax:
%   [onset, offset] = parse_bit_sync(data_vector, sync_bit, out_path, invert_logic=true, trig_chan='TRIGGER');
%
% Inputs:
%   x - data vector or struct
%   sync_bit     - bit number to detect event timestamps
%   out_path     - path to root directory for animal data
%   invert_logic - boolean to invert TTL bit detection threshold (default=true)
%   trig_chan    - channel name from muscle map file containing trigger event data
%
% Example1:
%   [onset, offset] = parse_bit_sync(x);
%
% Example2:
%   [onset, offset, sync_data] = parse_bit_sync(x, 10, false, 'TRIGGER');
%
% Outputs:
%   onset - The sample indices of detected LOW-to-HIGH TTL sync transitions.
%   offset - The sample indices of detected HIGH-to-LOW TTL sync transitions.
%   sync_data - The data used to generate `onset` and `offset` vectors.
%
% See also: Contents, plot_emg_averages

% sync_bit ex: 9 or 10
% Check if intput is either struct or array
if numel(varargin)>0
    data = varargin{1};
    %sync_bit = 10; % default is 10
    inverted_logic = true;
end
%if numel(varargin)>1
%    sync_bit = varargin{2};
%end
if numel(varargin)>3
    inverted_logic = varargin{4};
end
if numel(varargin)<4
    trig_channel = 'TRIGGER';
else
    trig_channel = varargin{5};
end
if isstruct(data)
    if isfield(data, 'samples')
        channels = horzcat(data.channels{:});
        itrig_channel = contains({channels.alternative_name}, trig_channel);
        trig_channel_data = data.samples(itrig_channel, :);
    else
        error('Missing `samples` field of first input argument.'); 
    end
elseif isa(data, 'TMSiSAGA.Data') % Note that output of TMSiSAGA.Poly5.read is one of their data classes, not a struct.
    channels = horzcat(data.channels{:});
    itrig_channel = contains({channels.alternative_name}, trig_channel);
    trig_channel_data = data.samples(itrig_channel, :);
elseif isnumeric(data) && (size(data,2)==1)
    trig_channel_data = data';
else
    error('Data passed should be a struct containing fields "samples", "channels" and "sample_rate"');
end

save_output = false;
if numel(varargin)>1
    if isnumeric(varargin{2})
        sync_bit = varargin{2}; % default is 10
    else
        sync_bit = 10; % use default value of 10
        fprintf(1, 'Using default sync bit value of <strong>%d</strong>.\n', sync_bit);
        out_path = varargin{2};
        save_output = true && isa(data, 'TMSiSAGA.Data');
    end
end
if max(trig_channel_data)>1
    sync_data = (bitand(trig_channel_data, 2^sync_bit) == 2^sync_bit);
    if inverted_logic == true
        sync_data = ~sync_data;
    end
    sync_data = double(sync_data);
else
    sync_data = double(~trig_channel_data);
end
onset = find([false, diff(sync_data) < 0]);
offset = find([diff(sync_data) > 0, false]);

if nargin > 2
    out_path = varargin{3};
    save_output = true && isa(data, 'TMSiSAGA.Data');
end

if save_output
    if (numel(offset) < 10) && (exist(fullfile(out_path, sprintf('%s_sync.mat', data.name)), 'file')~=0)
        warning('Only %d triggers parsed from bit sync signal for %s! Skipped saving empty vector.', numel(offset), data.name);
        return;
    else
        if exist(out_path, 'dir') == 0
            try
                mkdir(out_path);
            catch me
                warning(me.message);
            end
        end
        out_f = fullfile(out_path, sprintf('%s_sync.mat', data.name));
        save(out_f, 'onset', 'offset', 'sync_data', '-v7.3');
    end
end

end


