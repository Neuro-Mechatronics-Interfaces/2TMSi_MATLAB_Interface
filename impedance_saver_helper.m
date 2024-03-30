function impedance_saver_helper(fname, tag, impedance)
%IMPEDANCE_SAVER_HELPER  Save impedance values to some file
%
% Syntax:
%   impedance_saver_helper(fname, tag, impedance);
%
% Inputs:
%   fname - Formatted output filename or filename expression containing %s
%   tag   - If fname has %s in it, then this is inserted with "-impedance"
%           appended. So for example if SAGA-A tag is "A", then use
%           device.tag to get its tag for this argument. The output
%           filename corresponding to filename
%           `Max_2022_10_22_A_4.poly5` 
%               will then be
%           `Max_2022_10_22_A-impedance_4.mat`
%   impedance - The actual impedance values to save.
%
% See also: Contents

[p, f, ~] = fileparts(fname);
f = strcat(f, ".mat");

if contains(f, "%s")
    f = sprintf(f, strcat(tag, "-impedance"));
end

if isempty(p)
    fname = f;
else
    if exist(p, 'dir') == 0
        try %#ok<TRYNC>
            mkdir(p);
            fprintf(1,'Created save folder:\n\t<strong>%s</strong>\n\n', p);
        end
    end
    fname = fullfile(p, f);
end

time = datetime('now', 'Format', 'uuuu-MM-dd HH:mm:ss.SSS', 'TimeZone', 'America/New_York');
save(fname, 'impedance', 'time', '-v7.3');
end