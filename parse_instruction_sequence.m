function instructions = parse_instruction_sequence(name, options)
%PARSE_INSTRUCTION_SEQUENCE  Parse list of string instructions from yaml in configurations/instructions folder.
arguments
    name (1,1) string
    options.Folder (1,1) string = "";
end

if strlength(options.Folder)==0
    in_folder = parameters('instructions_folder');
else
    in_folder = options.Folder;
end

F = dir(fullfile(in_folder, "*.yaml"));
if isempty(F)
    error("No instruction .yaml files in %s!", in_folder);
end

yaml_names = string({F.name});
[~,input_name,~] = fileparts(name);
search_name = strcat(string(input_name), ".yaml");

idx = strcmpi(yaml_names, search_name);
if sum(idx) == 0
    fprintf(1,'\n<strong>Valid options:</strong>\n');
    for iF = 1:numel(F)
        fprintf(1,'\t->\t%s\n', F(iF).name(1:(end-5)));
    end
    error("No file named '%s' in %s (check input name or file existence)", search_name, in_folder);
end

cfg = io.yaml.loadFile(fullfile(F(idx).folder, F(idx).name));
instructions = reshape(string(cfg.Sequence),numel(cfg.Sequence),1);

end