function String_out = fixCase(sTrING_iN)
%FIXCASE Fixes the input string so first character in string is capitalized and rest are lower-case.
%
% Syntax:
%   String_out = fixCase(sTrING_iN);
%
% Inputs:
%   sTrING_iN - String or char array, with any capitalization
%   
% Output:
%   String_out - String or char array (according to input), with first
%                   character (only) capitalized and rest lower-case.
%
% See also: Contents

tmp = char(sTrING_iN);
tmp(1) = upper(tmp(1));
tmp(2:end) = lower(tmp(2:end));
if ischar(sTrING_iN)
    String_out = tmp;
else
    String_out = string(tmp);
end
end