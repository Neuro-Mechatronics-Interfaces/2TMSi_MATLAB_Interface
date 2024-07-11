function [channelOrder, theta, proxdist] = load_layout(name, loc_A, loc_B, options)
%LOAD_LAYOUT  Loads layout for a given electrode configuration.  
arguments
    name {mustBeMember(name, {'4Textile_Rings'})} = '4Textile_Rings';
    loc_A {mustBeMember(loc_A, {'EXT', 'FLX'})} = 'EXT';
    loc_B {mustBeMember(loc_B, {'EXT', 'FLX'})} = 'FLX';
    options.Folder {mustBeFolder} = fullfile(pwd, 'configurations', 'layouts');
end
fname = fullfile(options.Folder, sprintf('%s_A%s_B%s.mat', name, loc_A, loc_B));
load(fname, 'channelOrder', 'theta', 'proxdist');
end