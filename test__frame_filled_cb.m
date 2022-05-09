function test__frame_filled_cb(src, ~)
%TEST__FRAME_FILLED_CB  Test callback for FrameFilledEvent from StreamBuffer class.

disp("Frame filled event!");
[~, idx] = sort(src.index, 'ascend');
disp(src.samples(:, idx));

end