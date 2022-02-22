clear;
clc;

H = TMSiSAGA_Handler();
H.setFileInfo('TEST', 'R:\NMLShare\raw_data\primate\TEST\TEST_2021_12_03');
H.begin();
% L = addlistener(H, "DiskFileEvent", @(~,evt)disp(evt));
% H.record();
% disp('ready');
% pause(10);
% H.stop();

%%
start(H.device);
H.device(1).is_recording = true;
H.device(2).is_recording = true;
while any([H.device.is_recording]) && (~H.has_received_stop_signal())
    for k = 1:2  % This is where we are selective about which device to sample
        if H.device(k).is_sampling
                % % % TODO: This is where we implement a
                % circular buffer in order to get the
                % "real-time" stuff to actually work... % %
                samples = H.device(k).sample();
                H.file{k}.append(samples);

        end
    end
end
% Make sure the poly5 files are closed. At this point, the
% devices should already have been stopped (see:
%   ```obj.has_received_stop_signal```)
for k = 1:2
    H.file{k}.close();
end
stop(H.device);