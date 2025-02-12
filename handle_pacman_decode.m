function [btn_code, asserting] = handle_pacman_decode(Y_pred)

asserting = mean(Y_pred(:,3),1) > 0.85;
btn_code = 0x0000;
if mean(Y_pred(:,2)) > 0.5 % Go UP
    btn_code = btn_code + 0x0001;
elseif mean(Y_pred(:,2)) < -0.5 % Go DOWN
    btn_code = btn_code + 0x0002;
end

if mean(Y_pred(:,1)) > 0.5 % Go RIGHT
    btn_code = btn_code + 0x0008;
elseif mean(Y_pred(:,1)) < -0.5 % Go LEFT
    btn_code = btn_code + 0x0004;
end
if asserting
    btn_code = btn_code + 0x1000; % Press "A" button
end
vigem_gamepad(3,btn_code);

end