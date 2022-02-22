function give_up(device, lib)
%GIVE_UP - Actually make sure that everything shuts down.
%
% Syntax:
%   debugging.give_up(device, lib);
%
% Inputs:
%   devices - Array of `Device` objects
%   lib     - Library of dll stuff
%
% Output:
%   Shuts everything down.
for ii = 1:numel(device)
    try
        device(ii).stop();
    catch me
        disp(me);
    end
    try
        device(ii).disconnect();
    catch me
        disp(me); 
    end
end
lib.cleanUp();
delete(instrfind);
close all force;
end