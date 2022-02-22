% UI Package for generating graphics for user interfaces
% MATLAB Version 9.7 (R2019b Update 5) 02-Jun-2020
%
% Packages
%   pars                     - Package with sub-module parameters.
%
% Functions
%   addSignificanceLine      - Add line to axes indicating significant epoch(s)
%   addToSecondMonitor       - Return position coordinates for 2nd mon if possible
%   cubehelix                - Generate an RGB colormap of Dave Green's CubeHelix colorscheme
%   expAI                    - Export figure in appropriate format for Adobe Illustrator
%   getGrid                  - Returns [x,y,w,h] graphics position vector for (nRow,nCol)
%   getHorizontalSpacing     - Get spacing in x-direction for array of graphics
%   getSecondMonitorPosition - Return 2nd (or 1st) monitor position coordinates
%   getVerticalSpacing       - Get spacing in y-direction for array of graphics
%   panelizeAxes             - Returns axes cell array, with panelized axes objects
%   parameters               - Returns parsed default parameters struct
%   plotCDF                  - Plots cumulative distribution function (CDF) for data in `Y`
%   plotWithShadedError      - Add shaded confidence bounds to data
%   simplePlot               - Make a "simple" line plot using just (2D) vertex data
