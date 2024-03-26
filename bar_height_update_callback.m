function bar_height_update_callback(src, hBarA, hBarB, hBarZ, hBarC, hTxt, hTxt2, net, Label)
%BAR_HEIGHT_UPDATE_CALLBACK Update the heights of the bars according to counts in tcpclient UserData.A.x, UserData.A.y, UserData.B.x, UserData.B.y fields.
%
% Example:
%   hA = bar(...);
%   hB = bar(...);
%   timerObj = timer('TimerFcn', @(~, ~, client, hA, hB)bar_height_update_callback(src, hA, hB));
%   timerObj.

% disp("Tick");
if src.UserData.UpdateGraphics
    if isa(hBarA,'matlab.graphics.chart.primitive.Bar')
        set(hBarA,'XData',src.UserData.A.x, 'YData', src.UserData.A.y);
        set(hBarB,'XData',src.UserData.B.x, 'YData', src.UserData.B.y);
    else
        hBarA.CData = reshape(src.UserData.A.y,8,8);
        hBarB.CData = reshape(src.UserData.B.y,8,8);
    end
    % if nargin > 3
    %     set(hTxt, 'String', string(src.UserData.CurrentReportedPose));
    % end
end
% drawnow();

if src.UserData.NeedsCalibration
    src.UserData.Calibration(:, src.UserData.CalibrationIndex) = ([src.UserData.A.y; src.UserData.B.y]);
    src.UserData.CalibrationIndex = src.UserData.CalibrationIndex + 1;
    if src.UserData.CalibrationIndex > size(src.UserData.Calibration,2)
        src.UserData.NeedsCalibration = false;
        disp("Calibration data collection complete!");
        % stop(src);
        % src.UserData.AutoEnc = trainAutoencoder(src.UserData.Calibration, 24);
        % src.UserData.DimReduceData = predict(src.UserData.AutoEnc, src.UserData.Calibration)';
        [src.UserData.coeff, ~, ~, ~, src.UserData.explained] = pca(src.UserData.Calibration');
        src.UserData.T = src.UserData.coeff(:,1:12)./max(abs(src.UserData.coeff(:,1:12)),[],1);
        plot_controller_coeffs(src);
        src.UserData.UpdateGraphics = true;
        % start(src);
    end
    return;
end

if nargin < 7
    return;
end

% if nargin > 8
%     src.UserData.Zprev = 0.25 .* predict(src.UserData.AutoEnc, ([src.UserData.A.y, src.UserData.B.y])') + 0.25.*src.UserData.Zprev;
%     predicted = net(src.UserData.Zprev);
%     [~,idx] = max(predicted);
%     set(hTxt2,'String',Label(idx));
% else
%     src.UserData.Zprev = 0.25 .* predict(src.UserData.AutoEnc, ([src.UserData.A.y, src.UserData.B.y])') + 0.25.*src.UserData.Zprev;
% end
src.UserData.Zprev = [src.UserData.A.y; src.UserData.B.y]';
cmd_raw = src.UserData.Zprev * src.UserData.T;
if src.UserData.UpdateGraphics
    set(hBarZ,'XData',(1:numel(src.UserData.Zprev))', 'YData', src.UserData.Zprev);
    set(hBarC,'XData',1:size(src.UserData.T,2),'YData',cmd_raw);
end

if src.UserData.ControlServer.Connected && (numel(src.UserData.EigenPairs) >= 2)
    
    data = struct('axis', nan(size(src.UserData.EigenPairs,1),1), 'button', zeros(4,1));
    for iRow = 1:size(src.UserData.EigenPairs,1)
        data.axis(iRow) = sum(cmd_raw(src.UserData.EigenPairs{iRow}));
    end
    [~,iMax] = max(abs(cmd_raw(8:11)));
    data.button(iMax) = 1;
    writeline(src.UserData.ControlServer, jsonencode(data));
end

cmd = '';
for iVal = 1:size(src.UserData.XBoxKeys,1)
    if src.UserData.XBoxKeys{iVal,2} == "X"
        cmd = [cmd, sprintf('%s:0.0,',src.UserData.XBoxKeys{iVal,1})];
        continue;
    end
    val = src.UserData.(src.UserData.XBoxKeys{iVal,2}).y(src.UserData.XBoxKeys{iVal,3}) * src.UserData.XBoxKeys{iVal,4};
    cmd = [cmd, sprintf('%s:%0.1f,',src.UserData.XBoxKeys{iVal,1},val)];
end
cmd(end) = [];
disp(cmd);
if src.UserData.XBoxServer.Connected

    writeline(src.UserData.XBoxServer, cmd);
end

% k = numel(src.UserData.Data.Y) + 1;

% src.UserData.Data.X(k,:) = [src.UserData.A.y, src.UserData.B.y];
% src.UserData.Data.Pose(k) = src.UserData.CurrentAssignedPose;

% disp('Tick');
end