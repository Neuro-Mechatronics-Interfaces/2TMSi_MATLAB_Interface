function [meta, stim] = getMetadata(fname)
%GETMETADATA Return metadata related to specific experimental recording.
%
%   [meta, stim] = getMetadata(fname);
%       --> ONLY WORKS IF METADATA HAS BEEN ENTERED TO metadata.xlsx <--
%
% Example 1 -- (plexon recording pl2 file on raptor):
%   [meta, stim] = getMetadata('R:\NMLShare\raw_data\primate\Rupert\Rupert_2021_07_09\Rupert_2021_07_09_0.pl2');
%
% Example 2 -- (TMSi SAGA recording poly5 file on raptor):
%   [meta, stim] = getMetadata('R:\NMLShare\raw_data\primate\Rupert\Rupert_2021_07_16\Rupert_2021_07_16_9');
%
% Inputs
%   fname - Filename of plexon recording, or filename of metadata
%               spreadsheet. If this is the metadata spreadsheet, result is
%               the table of data from the metadata spreadsheet. Otherwise,
%               result will be metadata related to the recording.
%
% Output
%   meta  - Metadata struct parsed from metadata.xlsx on `raptor`, which
%            has table data related to this recording.
%   stim  - Stim struct used in .poly5 annotations based on struct from
%           preliminary scripts Doug did.
%
% See also: Contents, make_sta

fname = strrep(fname, '/', filesep);
fname = strrep(fname, '\', filesep);
[p, f, e] = fileparts(fname);

% .poly5 recordings should be given without extension, specifying just the
% same naming convention part (not additional "appended" info).
if isempty(e)
    e = '.poly5';
end

% If the metadata.xlsx path is given directly, return the full table.
if strcmp(e, '.xlsx')
    if exist(fname, 'file')==0
        error('Could not locate file: <strong>%s</strong>', fname);
    end
    meta = readtable(fname);
    meta.Recording = string(meta.Recording);
    meta.Project = string(meta.Project);
    stim = struct;
    return;
end

% Split path into parts to find the metadata location (hopefully this lets
% it work for things mapped to Google Filestream as well).
p_meta = strsplit(p, filesep);
p_meta = strjoin(p_meta(1:(end-1)), filesep);
meta_file = fullfile(p_meta, 'metadata.xlsx');

% Get the full metadata table from the Excel spreadsheet.
M = getMetadata(meta_file);


idx = strcmp(M.Recording, f);
% If filename part (does not count extension) didn't match any recording
% from the "Recording" column of spreadsheet, then something went wrong.
% Warn the user of this and return empty metadata and stim structs.
if sum(idx) == 0
    meta = struct;
    stim = struct;
    warning('No metadata logged for file <strong>%s</strong>!', f);
    return;
end 
% Otherwise, reduce the table we are considering to just the row matching
% THIS recording.
m = M(idx,:);

[~, str_info, ~] = fileparts(m.Recording);
str_info = strsplit(str_info, "_");
meta = struct();
meta.raw = m;

% Do some formatting of the rest of the table columns:
meta.Name = str_info{1};
meta.RecType = string(m.Type);
meta.Subject = string(str_info{1});
meta.Recording = string(m.Recording);
meta.Date = string(strjoin(str_info(2:4), "-"));
index_val = str2double(str_info{5});
if ~isnan(index_val)
    meta.Index = index_val;
    meta.Array = 'EMG';
    meta.Tags = string;
else
    meta.Array = str_info{5};
    meta.Tags = string;
    meta.Index = 999;
    for ii = 6:numel(str_info)
        index_val = str2double(str_info{ii});
        if ~isnan(index_val)
            meta.Index = index_val;
            break;
        else
            meta.Tags = [meta.Tags;  string(str_info{ii})];
        end
    end
end
meta.Sweep = m.Sweep;
meta.Project = strrep(m.Project, "_", " ");
meta.IsExemplar = m.Exemplar;
meta.Evoked = struct('EMG', m.EMG, 'Movement', m.Movement);
if exist(fullfile(p_meta, string(m.Muscle_Map)), 'file')~=0
    fprintf(1, 'Found muscle map file: <strong>%s</strong>\n', string(m.Muscle_Map));
    meta.Muscle = io.JSON(fullfile(p_meta, string(m.Muscle_Map)));
else
    meta.Muscle = io.JSON(struct('Muscles', struct, 'Impedances', struct));
    fprintf(1, 'No muscle map file: <strong>%s</strong>\n', fullfile(p_meta, string(m.Muscle_Map)));
end
meta.Goal = m.Goal;
meta.Notes = m.Notes;
p_gen = fullfile(parameters('generated_data_folder'), meta.Subject, strjoin(str_info(1:4), "_"), num2str(meta.Index));
if exist(p_gen, 'dir')==0
    try
        mkdir(p_gen);
        fprintf(1, '->\tCreated new output folder: <strong>%s</strong>\n', p_gen);
    catch me
        warning(me.message);
    end
end
meta.Folders = struct( ...
    'raw', p, ...
    'tank', p_meta, ...
    'generated', p_gen);
site = struct('raw', m.Stim_Site, ...
    'parsed', parseSite(m.Stim_Site), ...
    'return', string(m.Return_Site));

% This struct field allows it to work with the `make_sta` code
meta.Stim = struct(...
    'site', site, ...
    'pulse', struct(...
    'period', m.Inter_Pulse_Period_ms*1e-3, ...
    'width', m.Pulse_Width_ms*1e-3, ...
    'amplitude', m.Pulse_Amplitude_mA, ... % Leave in mA
    'pps', 1e3/m.Inter_Pulse_Period_ms, ...
    'units', ...
    struct('period', 's', ...
    'width', 's',  ...
    'amplitude', 'mA', ...
    'pps', 'pulses/s')), ...
    'burst', struct(...
    'width', m.Burst_Width_ms*1e-3, ...
    'period', m.Inter_Burst_Period_s, ...
    'bps', 1/m.Inter_Burst_Period_s, ...
    'units', ...
    struct('width', 's', ...
    'period', 's', ...
    'bps', 'bursts/s')));

% This stimulation data struct lets it work with stuff Doug wrote for poly5
stim = meta_2_stim(meta);

    function site = parseSite(stim_site)
        %PARSESITE Return parsed string based on stim_site numeric value
        if ~isnumeric(stim_site)
            if iscell(stim_site)
                site = sprintf('Site %s', stim_site{1});
            else
                site = sprintf('Site %s', stim_site);
            end
        else
            if stim_site <= 0
                site = "No Stim";
                return;
            elseif mod(stim_site, 1) > 0  % Not an integer
                site = "";
                while stim_site > 0
                    site_index = floor(stim_site);
                    site_str = sprintf('Site %g ', site_index);
                    site = strcat(site_str, site);
                    stim_site = (stim_site - site_index) * 10;
                end
            else
                site = sprintf('Site %g', stim_site);
            end
        end
    end

end