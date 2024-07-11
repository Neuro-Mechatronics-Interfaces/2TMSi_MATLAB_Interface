function [x,y] = project_ring(uni_ring, theta)

uni_ring(uni_ring < 0) = 0;
% w = uni_ring ./ sum(uni_ring,1);
w = uni_ring;
cx = cos(reshape(theta,1,[]));
cy = sin(reshape(theta,1,[]));
x = cx*w;
y = cy*w;


end