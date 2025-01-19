function [sensorData, nSamples] = decode_contactile_frames(frames)
%DECODE_CONTACTILE_FRAMES  Decode byte sequences for sampling sensors from contactile button array via serial.
nSamples = size(frames,1);
sensorData = zeros(30, nSamples, 'single'); % All channels (30) per frame

for f = 1:nSamples
    frame = frames(f,:);
    payload = frame(50:end-4); % Extract payload (after header, before footer)

    % Process each sensor's data
    for sensorIdx = 1:10
        sensorStart = (sensorIdx-1) * 12 + sensorIdx*2 + 1;
        sensorEnd = sensorStart + 11;

        if sensorEnd <= length(payload)
            sensorBytes = payload(sensorStart:sensorEnd);

            for channelIdx = 1:3
                channelStart = (channelIdx-1) * 4 + 1;
                channelEnd = channelStart + 3;

                channelData = uint8(sensorBytes(channelStart:channelEnd));
                if (channelData(2)==0xC0) && (channelData(3)==0x7F)
                    channelValue = nan;
                else
                    channelValue = typecast(channelData, 'single');
                end 
                sensorData((sensorIdx-1)*3+ channelIdx, f) = channelValue;
            end
        end
    end
end