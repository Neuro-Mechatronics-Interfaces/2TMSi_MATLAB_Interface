%EXAMPLE_TEST_INPUT_UTILITIES_VIRTUAL_GAMEPAD_AND_MOUSE
clear; clc;
gamepad = tcpclient("10.0.0.101", 6053);
mouse = tcpclient("10.0.0.101", 6054);
% gamepad = tcpclient("127.0.0.1", 6053);
% mouse = tcpclient("127.0.0.1", 6054);
% Analog movement
writeline(mouse, 'u,0,-250'); % Move up 250 pixels
pause(1.5);
writeline(mouse, 'd,0,250'); % Move down 250 pixels
pause(1.5);
% Mouse wheel scroll
writeline(mouse, 'scroll,up'); % Scroll up
pause(1.5);
writeline(mouse, 'scroll,down'); % Scroll down
pause(1.5);
writeline(mouse, 'click,left'); % Left mouse click
pause(1.5);
writeline(mouse, 'on,left'); % Now, hold the left-mouse down
pause(0.1);
writeline(mouse, 'r,250,0'); % Move right 250 pixels
pause(0.1);
writeline(mouse, 'off,left'); % Release the left-mouse- may have highlighted text etc.
pause(0.5);
writeline(mouse, 'click,right'); % Right mouse click
pause(1.5);
writeline(mouse, 'x,-250,0'); % Move left 250 pixels to return to start. Don't specify movement type just to be annoying.
pause(0.005);
writeline(mouse, 'click,left'); % Left mouse click
