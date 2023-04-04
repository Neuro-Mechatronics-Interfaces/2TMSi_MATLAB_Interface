function debug_tmsi_stream(src, evt)
%DEBUG_TMSI_STREAM  Similar to that implemented in SAGA_GUI for enum.TMSiPacketMode.StreamMode case.

% if src.BytesAvailable > 0
%     nSamplesAvailable = src.BytesAvailable/8;
%     nChannels = src.UserData.n.channels;
%     nSamples = src.UserData.n.samples;
%     nSamplesPerFrame = nChannels * nSamples + 1;
%     if nSamplesPerFrame > nSamplesAvailable
%         src.flush();
%         return;
%     else
%         data = src.read(nSamplesPerFrame, 'double');
%         src.flush();
%     end
% %     y = reshape((double(data(1:(end-1)))-1024.0).*1.0e-3, 69, 512);
%     y = reshape(data(1:(end-1)), nChannels, nSamples);
% %     src.UserData.img.CData = reshape(zscore(rms(y(1:64,:),2),0,1),8,8) + randn(8,8).*1e-1;
% %     src.UserData.img.CData = reshape(rms(y(1:64,:),2),8,8) ./ src.UserData.img.UserData;
% %     src.UserData.img.UserData = reshape(zscore(rms(y(1:64,:),2),0,1),8,8);
% %     src.UserData.img.CData = mean(diff(reshape(y(1:64,:),8,8,512),2,1),3); 
%     o = src.UserData.per_channel_offset;
%     h = src.UserData.h;
%     for ii = 1:numel(h)
%         h(ii).YData = y(ii,:) + o*ii;
%     end
%     drawnow limitrate;
% else
%     src.flush();
% end


message = src.readline();
in = jsondecode(message);
evt.AbsoluteTime.Format = 'uuuu-MM-dd_hh:mm:ss.SSS';
src.UserData.logger.info(sprintf('%s :: %s :: Sent', string(evt.AbsoluteTime), in.type));

switch in.type
    case 'stream.tmsi'
        y = reshape(in.data, src.UserData.n.channels, []);
%         o = src.UserData.per_channel_offset;
%         h = src.UserData.h;
        idx = mod(in.data(in.channels==101,:)-1, src.UserData.n.samples)+1;
%         for ii = 1:numel(h)
%             h(ii).YData(idx) = y(ii,:) + o*ii;
%         end
        src.UserData.h.YData(idx, :) = y(1:64,:)';
%         set(src.UserData.c, 'XData', idx, 'YData', ones(size(idx))); 
        drawnow limitrate;

    case 'name.tmsi'
        title(src.UserData.h, ...
            sprintf('%s: %04d-%02d-%02d (%s::%d)', in.subject, in.year, in.month, in.day, src.UserData.tag, in.block), ...
            'FontName','Tahoma');
end
src.UserData.logger.info(sprintf('%s :: %s :: Handled', string(datetime('now','Format','uuuu-MM-dd_hh:mm:ss.SSS')), in.type));

end