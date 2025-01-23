function [p5, p5_file, p5_folder] = initializePoly5File(subj, block, all_ch, fs, options)
%INITIALIZEPOLY5FILE Initializes Poly5 file for recording with desired filename/structure, sample-rate, and channel metadata.
%
% Syntax:
%   p5 = initializePoly5File(subj, block, all_ch);
%   p5 = initializePoly5File(...,fs,'Name',value,...);
%   [p5, p5_file, p5_folder] = initializePoly5File(...);
%
% Inputs:
%   subj - Subject name or identifier (text scalar)
%   block - Block index keyed to experiment
%   all_ch - Struct array of channel metadata to initialize poly5 file
%   fs - Sample rate (default: 2000). 
%
% Output:
%   p5 - TMSiSAGA.Poly5 object for writing the sample data to
%   p5_file - File part ("<name>.poly5") of file path
%   p5_folder - Folder part of Poly5 file path.
%
% See also: TMSiSAGA.Poly5

arguments
    subj (1,1) {mustBeTextScalar}
    block (1,1) double {mustBeInteger}
    all_ch struct % Channels struct array
    fs (1,1) double {mustBePositive} = 2000;
    options.OutputRoot {mustBeTextScalar} = pwd;
    options.Poly5FileTag {mustBeTextScalar} = 'Synchronized';
end

dt = datetime();
tank = sprintf('%s_%04d_%02d_%02d',subj,year(dt), month(dt), day(dt));
p5_folder = sprintf('%s/%s/%s', options.OutputRoot, subj, tank);
if exist(p5_folder,'dir')==0
    mkdir(p5_folder);
end
p5_file = sprintf("%s_%s_%d.poly5", tank, options.Poly5FileTag, block);
p5_path = string(sprintf("%s/%s", ...
     p5_folder, p5_file));
p5 = TMSiSAGA.Poly5(p5_path, fs, all_ch, 'w');

end