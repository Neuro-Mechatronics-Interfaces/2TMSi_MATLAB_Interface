classdef MetaDataHandler < handle
    %METADATAHANDLER  Handle metadata.xlsx appending

    properties (Access=public)
        M       table                   % Metadata for the current block
    end

    properties (GetAccess=public, SetAccess=protected)
        file    string                  % Name of metadata xlsx file
        subj    string                  % Name of recording subject
        yyyy    double                  % Year of recording
        mm      double                  % Month of recording
        dd      double                  % Date of recording
        date    datetime                % More-accurate datetime
        array   string = ["A", "B"]     % Recording array
        block   double                  % Block/index of recording
    end

    properties (Access=private)
        date_   datetime                % Datetime (with only date) of recording (from other props)
    end

    properties (Hidden, GetAccess=public, SetAccess=protected)
        merged  logical = true          % Flag indicating if the "current metadata block" has been merged.
        saved   logical = true          % Flag indicating if table changes have been saved.
    end

    properties (Access=protected)
        def_raw_data_folder (1,1) string
        tank    string                  % Folder containing recordings on raw_data drive
        T       table                   % The full metadata table
        var_types       cell            % Actual variable types from table
        def_var_values  cell = { ...    % Default values for each variable type
            "", "mat", "", "N3_Patch", [], "Complete Phase 3", "C3", "C4", ...
            6600, 3.0, 0.25, 10.0, 0, 1.0, 6.5, 3, 333.0, "Cathodal", ...
            "", false, false, false, "2electrode_0", "DS8R", "Electrical", "JC", "", [],1000.0};
    end

    properties (Constant)  % Default values go here
        def_var_names = {'Recording','Type','Muscle_Map','Project','Date','Goal','Stim_Site','Return_Site',...
            'Depth_um','Inter_Pulse_Period_ms','Pulse_Width_ms','Pulse_Amplitude_mA', ...
            'Max_Return_Amplitude_mA', 'Inter_Burst_Period_s','Burst_Width_ms', ...
            'N_Pulses_Per_Burst','Pulse_Frequency','Pulse_Type',...
            'Notes','Exemplar','Movement','EMG',...
            'Sweep','Stimulator','Stim_Type','Operator','Annotation','Index','Impedance_kOhm'};
        def_var_types = {'string','string','string','string','datetime','string','string','string', ...
            'double','double','double','double','double','double', ...
            'double', 'double','double','string', ...
            'string','logical','logical','logical', ...
            'string','string','string','string','string','double','double'};
    end

    methods
        function self = MetaDataHandler(SUBJ, YYYY, MM, DD, ARRAY, BLOCK)
            %METADATAHANDLER  Constructor for metadata handling class.
            %
            % Syntax:
            %   self = MetaDataHandler(SUBJ, YYYY, MM, DD, ARRAY);
            %   self = MetaDataHandler(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
            %
            % Inputs:
            %   SUBJ  - Name of recording subject.
            %   YYYY  - (double scalar) year of recording
            %   MM    - (double scalar) month of recording
            %   DD    - (double scalar) day of recording
            %   ARRAY - "A", "B", or ["A", "B"] (identifiers for SAGAs)
            %   BLOCK - (optional; double scalar; default is 0 if not
            %            specified)
            %
            % See also: Contents
            if nargin < 1
                config = io.yaml.loadFile(parameters('config'), 'ConvertToArray', true);
                self.def_raw_data_folder = string(config.Default.Folder);
                [SUBJ, YYYY, MM, DD, ARRAY, BLOCK] = MetaDataHandler.quick_selector_gui();
            elseif nargin == 1
                config = SUBJ;
                self.def_raw_data_folder = string(config.Default.Folder);
                [SUBJ, YYYY, MM, DD, ARRAY, BLOCK] = MetaDataHandler.quick_selector_gui();
            end
            self.array = ARRAY;
            self.subj = string(SUBJ);
            if ~isnumeric(YYYY)
                YYYY = str2double(YYYY);
            end
            if ~isnumeric(DD)
                DD = str2double(DD);
            end
            if ~isnumeric(MM)
                MM = str2double(MM);
            end
            self.yyyy = YYYY;
            self.mm = MM;
            self.dd = DD;
            self.date_ = datetime(self.yyyy, self.mm, self.dd,'Format','uuuu-MM-dd''T''HH:mm:ss.SSS');
            self.tank = string(sprintf("%s_%04d_%02d_%02d", self.subj, self.yyyy, self.mm, self.dd));
            if nargin > 5
                self.block = BLOCK;
            else
                self.block = nan;
            end
            fname = fullfile(self.def_raw_data_folder, SUBJ, "metadata.xlsx");
            self.point_to_new_metadata_file(fname);
            self.set_current_metadata_values(self.block);
        end

        function assign(self, name, value)
            %ASSIGN  Assign a value to current metadata table rows for a single variable
            %
            % Syntax:
            %   self.assign(name, value);
            %
            % Inputs:
            %   name  -- Name of table variable (column)
            %   value -- The value to assign to each row.
            %
            % See also: Contents
            if ~ismember(name, self.M.Properties.VariableNames)
                error("MetaDataHandler:Data:MissingVariable", "Invalid table variable: %s", name);
            end
            if iscell(value) && (numel(value) == size(self.M, 1))
                for iM = 1:numel(value)
                    self.M{iM, name} = value{iM};
                end
            else
                for iM = 1:size(self.M, 1)
                    self.M{iM, name} = value;
                end
            end
            self.merged = false;
            self.saved = false;
        end

        function assign_naming_props_only(self, SUBJ, YYYY, MM, DD, ARRAY, BLOCK)
            %ASSIGN_NAMING_PROPS_ONLY  Only assign protected properties but don't do anything else.
            %
            % Syntax:
            %   self.assign_naming_props_only(SUBJ, YYYY, MM, DD, ARRAY, BLOCK);
            %
            % Example:
            %   app.meta.assign_naming_props_only("Mats", 2022, 10, 20, ["A", "B"], 0);
            self.subj = SUBJ;
            self.yyyy = YYYY;
            self.mm = MM;
            self.dd = DD;
            self.array = ARRAY;
            self.block = BLOCK;
            self.tank = string(sprintf("%s_%04d_%02d_%02d", self.subj, self.yyyy, self.mm, self.dd));
        end

        function delete(self)
            %DELETE  Overload destructor to check for save if deleted
            if ~self.saved
                answer = questdlg('Unsaved metadata. Save changes before destroying handler?', ...
                    'Save Metadata.xlsx?', ...
                    'Save', 'Discard', 'Save');
                switch answer
                    case 'Save'
                        % "Merge" (but not save to metadata.xlsx yet)
                        self.save_metadata();
                        fprintf(1, 'Metadata saved (in <strong>%s</strong>).\n', self.file);
                    case 'Discard'
                        % Continue to incrementing
                        fprintf(1, 'Metadata not saved.\n');
                    otherwise
                        % Do nothing
                end
            end
        end

        function decrement_block(self)
            %DECREMENT_BLOCK  Increments block index by 1
            %
            % Syntax:
            %   self.decrement_block();
            %
            % See also: Contents
            if ~self.merged
                answer = questdlg('Current meta not merged. Increment without storing current block metadata?', ...
                    'Discard Metadata?', ...
                    'Merge', 'Discard', 'Cancel', 'Cancel');
                switch answer
                    case 'Merge'
                        % "Merge" (but not save to metadata.xlsx yet)
                        self.merge_current_metadata();
                        fprintf(1, 'Data for <strong>block %d</strong> stored.\n', self.block);
                    case 'Discard'
                        % Continue to incrementing
                        fprintf(1, 'Data for <strong>block %d</strong> discarded.\n', self.block);
                    case 'Cancel'
                        % Cancel method
                        return;
                    otherwise % Same as 'Cancel'
                        return;
                end
            end
            self.set_current_metadata_values(self.block - 1);
        end

        function increment_block(self)
            %INCREMENT_BLOCK  Increments block index by 1
            %
            % Syntax:
            %   self.increment_block();
            %
            % See also: Contents
            if ~self.merged
                answer = questdlg('Current meta not merged. Increment without storing current block metadata?', ...
                    'Discard Metadata?', ...
                    'Merge', 'Discard', 'Cancel', 'Cancel');
                switch answer
                    case 'Merge'
                        % "Merge" (but not save to metadata.xlsx yet)
                        self.merge_current_metadata();
                        fprintf(1, 'Data for <strong>block %d</strong> stored.\n', self.block);
                    case 'Discard'
                        % Continue to incrementing
                        fprintf(1, 'Data for <strong>block %d</strong> discarded.\n', self.block);
                    case 'Cancel'
                        % Cancel method
                        return;
                    otherwise % Same as 'Cancel'
                        return;
                end
            end
            self.set_current_metadata_values(self.block + 1);
        end

        function value = getv(self, name)
            %GETV  Return the corresponding value to `name` from current metadata.
            %
            % Syntax:
            %   value = self.getv(name);
            %
            % Inputs:
            %   name -- Name of a table variable (column)
            %
            % Output:
            %   value -- The value of the first row of self.M, for the
            %            corresponding table value.
            %
            % See also: Contents
            if ~ismember(name, self.M.Properties.VariableNames)
                error("MetaDataHandler:Data:MissingVariable", "Invalid table variable: %s", name);
            end
            value = self.M{1, name};
        end

        function str = guess_muscle_map_name(self, ARRAY)
            %GUESS_MUSCLE_MAP_NAME  Guess muscle-map filename for this block
            %
            % Syntax:
            %   str = self.guess_muscle_map_name();
            %
            % See also: Contents
            if nargin < 2
                ARRAY = self.array;
            end
            if numel(ARRAY) > 1
                str = strings(size(ARRAY));
                for iA = 1:numel(ARRAY)
                    str(iA) = self.guess_muscle_map_name(ARRAY(iA));
                end
                return;
            end
            str = string(sprintf("%s_Muscle-Map_%s.json", self.tank, ARRAY));
        end


        function merge_current_metadata(self)
            %MERGE_CURRENT_METADATA  Merges metadata for current block with the full metadata table.
            %
            % Syntax:
            %   self.merge_current_metadata();
            %
            % See also: Contents

            if isempty(self.T)
                self.T = self.M;
            else
                for iA = 1:size(self.M, 1)
                    idx = MetaDataHandler.match_table2table(self.T, self.M(iA, :));
                    if isempty(idx)
                        self.T = vertcat(self.T, self.M(iA, :));
                    else
                        self.T(idx, :) = self.M(iA, :);
                    end
                end
            end
            
            self.merged = true;
            self.saved = false;
        end

        function point_to_new_metadata_file(self, fname)
            %POINT_TO_NEW_METADATA_FILE  Updates metadata to new filename
            %
            % Syntax:
            %   self.point_to_new_metadata_file(fname);
            %
            % Inputs:
            %   fname -- Full filename of `metadata.xlsx` spreadsheet (or
            %               new spreadsheet to be created).
            %
            % See also: Contents, MetaDataHandler

            if exist(fname,'file')==0
                self.block = 0;
                fprintf(1, 'Please wait, creating metadata for <strong>%s</strong>...', self.tank);
                tmp = self.T;
                try
                    self.T = table('Size', [0, numel(self.def_var_names)], ...
                        'VariableTypes', self.def_var_types, ...
                        'VariableNames', self.def_var_names);
                    writetable(self.T, fname, 'Sheet', 'Stimulation');
                    self.file = fname;
                    self.var_types = self.def_var_types;
                catch me
                    warning(me.message);
                    disp('Table data was not changed.');
                    self.T = tmp;
                    return;
                end
            else
                fprintf(1, 'Please wait, loading metadata for <strong>%s</strong>...', self.tank);
                self.T = readtable(fname);
                if size(self.T, 1) == 0
                    self.block = 0;
                    self.file = fname;
                    self.var_types = self.def_var_types;
                    return;
                end
                if ismember("Date", self.T.Properties.VariableNames)
                    self.T.Date = datetime(self.T.Date, 'Format', 'uuuu-MM-dd''T''HH:mm:ss.SSS');
                end
                self.T.Index = MetaDataHandler.parse_index(self.T.Recording);
                self.block = max(self.T.Index(MetaDataHandler.dates_match(self.T.Date,self.date_)));
                if isempty(self.block)
                    self.block = 0;
                end
                self.file = fname;
                self.var_types = cell(1, numel(self.T.Properties.VariableNames));
                for iV = 1:numel(self.var_types)
                    cur_var = self.T.Properties.VariableNames{iV};
                    iDef = strcmpi(self.def_var_names, cur_var);
                    if sum(iDef) == 1
                        self.var_types{iV} = self.def_var_types{iDef};
                        switch self.def_var_types{iDef}
                            case 'string'
                                self.T.(cur_var) = string(self.T.(cur_var));
                                self.T.(cur_var)(ismissing(self.T.(cur_var))) = "";
                            otherwise
                                % Only have to handle string, currently.
                        end
                    else
                        self.var_types{iV} = class(self.T.(cur_var));
                    end
                end
                self.var_types{strcmpi(self.T.Properties.VariableNames, 'Recording')} = 'string';
            end
            fprintf(1, 'complete\n');
        end

        function save_metadata(self)
            %SAVE_METADATA  Saves the data to xlsx file
            %
            % Syntax:
            %   self.save_metadata();
            %
            % See also: Contents
            self.merge_current_metadata();
            writetable(self.T, self.file, 'Sheet', 'Stimulation', 'WriteMode', 'overwritesheet');
            self.saved = true;
        end

        function set_current_metadata_values(self, BLOCK, SUBJ, YYYY, MM, DD, ARRAY)
            %SET_CURRENT_METADATA_VALUES  Sets metadata values for current block, but does not save to file yet
            %
            % Syntax:
            %   self.set_current_metadata_values(BLOCK);
            %   self.set_current_metadata_values(BLOCK, SUBJ, YYYY, MM, DD, ARRAY);
            %
            % Inputs:
            %   BLOCK - The block index to set metadata for.
            %   SUBJ  - (Optional) can specify along with YYYY, MM, DD,
            %               ARRAY to update all of those things in the
            %               event that you have multiple recording tanks
            %               for the same subject's metadata spreadsheet.
            %
            % See also: Contents
            self.block = BLOCK;
            if nargin > 5
                self.subj = SUBJ;
                self.yyyy = YYYY;
                self.mm = MM;
                self.dd = DD;
                self.tank = string(sprintf("%s_%04d_%02d_%02d", SUBJ, YYYY, MM, DD));
                self.date_ = datetime(YYYY, MM, DD, 'Format', 'yyyy-MM-dd');
            end
            if nargin > 6
                self.array = ARRAY;
            end
            if isempty(self.M) || (numel(self.array) ~= size(self.M, 1))
                self.M = table('Size', [numel(self.array), numel(self.T.Properties.VariableNames)], ...
                    'VariableTypes', self.var_types, ...
                    'VariableNames', self.T.Properties.VariableNames);
                for iV = 1:size(self.M, 2)
                    if strcmpi(class(self.M{:, iV}),'double')
                        iDef = strcmpi(self.def_var_names, self.M.Properties.VariableNames{iV});
                        if sum(iDef) == 0
                            continue;
                        end
                        if ~isempty(self.def_var_values{iDef})
                            self.M{:, iV} = self.def_var_values{iDef};
                        end
                    end
                end
                self.saved = false;
            end
            any_new = false;
            for iA = 1:numel(self.array)
                idx = MetaDataHandler.match_block2table(self.T, self.tank, self.array(iA), self.block);
                if isempty(idx)
                    self.M.Recording(iA) = string(sprintf("%s_%s_%d", self.tank, self.array(iA), self.block));
                    self.M.Index(iA) = BLOCK;
                    self.M.Muscle_Map(iA) = self.guess_muscle_map_name(self.array(iA));
                    if isempty(self.date)
                        self.M.Date(iA) = self.date_;
                    else
                        self.M.Date(iA) = self.date;
                    end
                    for iV = 1:numel(self.def_var_values)
                        cur_var = self.T.Properties.VariableNames{iV};
                        iDef = strcmpi(self.def_var_names, cur_var);
                        if iscell(self.M.(cur_var)(iA))
                            if ismissing(self.M.(cur_var){iA})
                                self.M.(cur_var){iA} = self.def.var_values{iDef};
                            end
                        else
                            if ismissing(self.M.(cur_var)(iA))
                                self.M.(cur_var)(iA) = self.def_var_values{iDef};
                            end
                        end
                    end
                    any_new = true;
                else
                    self.M(iA, :) = self.T(idx, :);
                end
            end
            % If we didn't find it in the full table, it has been created
            % and therefore was not merged.
            if any_new
                self.merged = false;
            else
                self.merged = true;
            end
        end

        function set_date(self, new_date)
            %SET_DATE  Updates date to new date
            new_date.Format = 'uuuu-MM-dd''T''HH:mm:ss.SSS';
            self.date = new_date;
            self.yyyy = year(self.date);
            self.mm = month(self.date);
            self.dd = day(self.date);
            self.date_ = datetime(self.yyyy, self.mm, self.dd,'Format','uuuu-MM-dd''T''HH:mm:ss.SSS');
            self.tank = string(sprintf("%s_%04d_%02d_%02d", self.subj, self.yyyy, self.mm, self.dd));
        end

        function set_subject(self, SUBJ)
            %SET_SUBJECT  Updates subject to new subject with associated metadata spreadsheet
            %
            % Syntax:
            %   self.set_subject(SUBJ);
            %
            % Inputs:
            %   SUBJ - (string) name of new subject
            %
            % See also: Contents
            self.subj = SUBJ;
            fname = fullfile(self.def_raw_data_folder, SUBJ, "metadata.xlsx");
            point_to_new_metadata_file(self, fname);
            self.block = 0;
            self.set_current_metadata_values(self.block);
        end
    end

    methods (Static)
        function [SUBJ, YYYY, MM, DD, ARRAY, BLOCK] = quick_selector_gui(varargin)
            %QUICK_SELECTOR_GUI   Blocking function to manually select key experiment parameters (for constructor).
            pars = struct;
            pars.Subject = 'Mats';
            pars.Date = datetime('now','Format','uuuu-MM-dd''T''HH:mm:ss.SSS');
            pars.Array = ["A", "B"];
            pars.Block = 0;
            pars.Icon = 'redlogo.jpg';
            pars.Name = 'Set Subject Parameters';
            pars.Enable = struct('Subject', 'on', ...
                                 'Date', 'on', ...
                                 'Array', 'on', ...
                                 'Block', 'on');
            f_en = fieldnames(pars.Enable);
            f_p = fieldnames(pars);
            for iV = 1:2:numel(varargin)
                name = char(varargin{iV});
                name = [upper(name(1)), lower(name(2:end))];
                idx_en = ismember(f_en, name);
                if sum(idx_en) == 1
                    pars.Enable.(name) = 'off';
                end
                idx_p = ismember(f_p, name);
                if sum(idx_p) == 1
                    pars.(name) = varargin{iV+1};
                end
            end
            
            fig = uifigure(...
                'Name', pars.Name, ...
                'Color', 'w', ...
                'Icon', pars.Icon, ...
                'WindowStyle', 'alwaysontop', ...
                'Position', [240 420 580 225], ...
                'CloseRequestFcn', @handle_figure_close_cb);
            SUBJ = pars.Subject;
            YYYY = year(pars.Date);
            MM = month(pars.Date);
            DD = day(pars.Date);
            ARRAY = pars.Array;
            BLOCK = pars.Block;
            d = uidatepicker(fig, 'Position', [210 125 200 50], ...
                'FontName', 'Tahoma', ...
                'FontSize', 15, ...
                'DisplayFormat', 'yyyy-MM-dd', ...
                'Enable', pars.Enable.Date,...
                'Value', pars.Date);
            n = uidropdown(fig, 'Position', [50 125 100 50], ...
                'FontName', 'Tahoma', ...
                'FontSize', 15, ...
                'Editable', 'on', ...
                'Items', {'Mats', 'Chaitanya', 'Pulkit', 'Doug', 'Jonathan', 'Max', 'Jiaming', 'Forrest', 'Screamy', 'Slinky', 'Rascal', 'Ollie', 'Rupert', 'Spencer', 'Frank', 'Beanz'}, ...
                'Enable', pars.Enable.Subject,...
                'Value', pars.Subject);
            uilabel(fig, 'Position', [160 50 50 50], ...
                'FontName', 'Tahoma', ...
                'FontSize', 15, ...
                'VerticalAlignment', 'center', ...
                'HorizontalAlignment', 'center', ...
                'FontWeight', 'bold', ...
                'Text', 'SAGA:');
            a = uidropdown(fig, 'Position', [210 50 200 50], ...
                'FontName', 'Tahoma', ...
                'FontSize', 15, ...
                'Editable', 'off', ...
                'Items', {'A', 'B', 'Both'}, ...
                'ItemsData', {"A", "B", ["A", "B"]}, ...
                'Enable', pars.Enable.Array,...
                'Value', pars.Array);
            b = uispinner(fig, ...
                'Position', [50 50 100 50], ...
                'FontName', 'Tahoma', ...
                'FontSize', 15, ...
                'RoundFractionalValues', 'on', ...
                'Enable', pars.Enable.Block,...
                'Value', pars.Block);
            uibutton(fig, ...
                'Position', [460 87 75 50], ...
                'FontName', 'Tahoma', ...
                'FontWeight', 'bold', ...
                'FontSize', 16, ...
                'Text', 'Submit', ...
                'ButtonPushedFcn', @(~, ~)close(fig));
            waitfor(fig);

            function handle_figure_close_cb(src, ~)
                try
                    SUBJ = n.Value;
                    YYYY = year(d.Value);
                    MM = month(d.Value);
                    DD = day(d.Value);
                    BLOCK = b.Value;
                    ARRAY = a.Value;
                    delete(src);
                catch me
                    warning(me.message);
                    delete(src);
                end
            end

        end

        function tf = dates_match(dt1, dt2)
            %DATES_MATCH  Return true if the DATE matches for two datetimes
            %
            % Syntax:
            %   tf = MetaDataHandler.dates_match(dt1, dt2);
            %
            % Inputs:
            %   dt1 - datetime object
            %   dt2 - datetime object
            %
            % Example:
            %   >> dt1 = datetime('today');
            %   >> pause(10);
            %   >> dt2 = datetime('now');
            %   >> assert(dt1 ~= dt2); % passes
            %   >> assert(MetaDataHandler.dates_match(dt1, dt2)); % passes
            %
            % See also: Contents, MetaDataHandler
            if (numel(dt1) > 1) || (numel(dt2) > 1)
                if numel(dt1) == 1
                    dt1 = repmat(dt1, size(dt2));
                elseif numel(dt2) == 1
                    dt2 = repmat(dt2, size(dt1));
                end
                tf = false(size(dt1));
                for ii = 1:numel(dt1)
                    tf(ii) = MetaDataHandler.dates_match(dt1(ii), dt2(ii));
                end
                return;
            end
            tf = strcmpi(datestr(dt1,'yyyy-mm-dd'), datestr(dt2,'yyyy-mm-dd'));
        end

        function idx = match_table2table(A, B)
            %MATCH_table2table  Return index where row B matches in A.
            %
            % Syntax:
            %   idx = MetaDataHandler.match_table2table(A, B);
            %
            % Inputs:
            %   A     - Table to use as reference for row matching
            %   B     - Table that we want to find a row for from A.
            %
            % Output:
            %   idx   - Row index in A matching B. If no such row
            %           exists, returned as empty scalar []
            %
            % See also: MetaDataHandler, MetaDataHandler.match_block2table

            if isempty(B.Recording)
                idx = [];
                return;
            end
            idx = find(strcmpi(A.Recording, B.Recording), 1, 'first');
        end

        function idx = match_block2table(A, tank, array, block)
            %MATCH_2TABLE_ROW  Return index where block matches in A.
            %
            % Syntax:
            %   idx = MetaDataHandler.match_block2table(A, tank, array, block);
            %
            % Inputs:
            %   A     - Table to use as reference for row matching
            %   tank  - Name of the data tank.
            %   array - The "tag" used for that array ("A" or "B")
            %   block - The numeric block used as an indexing key
            %
            % Output:
            %   idx   - Row index in A matching inputs. If no such row
            %           exists, returned as empty scalar []
            %
            % See also: MetaDataHandler, MetaDataHandler.match_table2table
            recording = string(sprintf("%s_%s_%d", tank, array, block));
            idx = find( strcmpi(A.Recording, recording), 1, 'first');
        end

        function index = parse_index(recording)
            %PARSE_INDEX  Return the actual block index based on recording file name(s).
            %
            % Syntax:
            %   index = MetaDataHandler.parse_index(recording);
            %
            % Example:
            %   T.Index = MetaDataHandler.parse_index(T.Recording);
            %
            % See also: MetaDataHandler, MetaDataHandler.point_to_new_metadata_file

            recording = string(recording);
            n = numel(recording);
            index = zeros(n,1);
            for ii = 1:n
                tmp = strsplit(recording(ii), "_");
                index(ii) = str2double(tmp{end});
            end
        end
    end
end