%EXAMPLE_DSP_SCOPE_WORKFLOW  Setup a Scope workflow using DSP toolkit objects/methods.

clear; 
clc;

% scope = 
scope.YLimits = [0 1];
scope.XOffset = -2.5;    
scope.SampleIncrement = 0.1;
scope.Title = "Gaussian distribution";
scope.XLabel = "X";
scope.YLabel = "f(X)";
