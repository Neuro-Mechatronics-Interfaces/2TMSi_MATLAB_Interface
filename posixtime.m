function s = posixtime(val)
if nargin < 1
    val = 'now';
end
s = seconds(datetime(val)-datetime(1970,1,1,0,0,0));
end