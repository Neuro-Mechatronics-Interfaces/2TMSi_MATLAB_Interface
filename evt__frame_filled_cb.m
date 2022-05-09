function evt__frame_filled_cb(src, evt, client)
%EVT__FRAME_FILLED_CB  Callback for FrameFilledEvent from StreamBuffer class.

[~, idx] = sort(src.index, 'ascend');
data = src.samples(:, idx)';
client.write(data(:), "double");

end