function save_data(self)
%SAVE_DATA  Saves data stored in `sample_data` and `meta_data` to a file.
%
%   Note: this truncates "unused" trials (as identified by files with all
%                                           NaN values).

config = io.yaml.loadFile(parameters('config'), "ConvertToArray", true);
[fname, pname] = uiputfile('*.mat', 'Save triggered data', ...
    fullfile(config.Default.Folder, '..', 'generated_data', ...
             self.subject, self.tank_(), sprintf('%s_All-Stimuli.mat', self.tank_())));
if fname == 0
    return;
end
idx = ~isnan(self.meta_data(:,5));
if sum(idx) == 0
    fprintf(1,'[SAGA-DATA-SERVER]::No valid data; no file exported.\n');
    return;
end
meta = self.meta_data(idx, :); % [x, y, focusing, amplitude, block]
meta = array2table(meta, ...
    'VariableNames', {'x', 'y', 'focusing', 'amplitude', 'block'});
X = self.sample_data(:, :, idx);
t = self.t;

out_file = fullfile(pname, fname);
save(out_file, 't', 'meta', 'X', '-v7.3');
fprintf(1,'[SAGA-DATA-SERVER]::Successfully exported %s\n', out_file);

end