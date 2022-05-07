function bytesAvailableCB_tcpserver__UNI(src, ~)
%BYTESAVAILABLECB_TCPSERVER__UNI  Calls read to reshape the unipolar HD-EMG array into server format.
% assignin('base', 'event', evt);
src.UserData = read(src,src.BytesAvailableFcnCount/8,"double");
reshapedServerData = reshape(src.UserData,31,31) + 1e-2 .* randn(31,31);
surf(reshapedServerData);
end