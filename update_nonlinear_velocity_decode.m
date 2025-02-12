function state = update_nonlinear_velocity_decode(state, Y, options)

arguments
    state (1,2) double
    Y (:,2) double
    options.XBound (1,2) double = [-5, 5];
    options.YBound (1,2) double = [-5, 5];
    options.XDeadzone (1,1) double = 1;
    options.YDeadzone (1,1) double = 1;
    options.Mode = 1;
end
n = size(Y,1);
dState = zeros(n,2);
iX = abs(Y(:,1)) > options.XDeadzone;
iY = abs(Y(:,2)) > options.YDeadzone;
dState(iX,1) = Y(iX,1);
dState(iY,2) = Y(iY,2);
switch options.Mode
    case 0
        state(1) = min(max(state(1) + sum(dState(:,1),1),options.XBound(1)),options.XBound(2));
        state(2) = min(max(state(2) + sum(dState(:,2),1),options.YBound(1)),options.YBound(2));
    case 1
        state(1) = min(max(mean(dState(:,1),1),options.XBound(1)),options.XBound(2));
        state(2) = min(max(mean(dState(:,2),1),options.YBound(1)),options.YBound(2));
end

end