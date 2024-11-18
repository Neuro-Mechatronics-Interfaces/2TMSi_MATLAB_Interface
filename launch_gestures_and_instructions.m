s = serialport("COM6", 115200);
gestures_fig = init_instruction_gui("Serial", s, "TimerGUIAddress", "127.0.0.1");
timer_fig = init_instruction_timer_gui("GesturesGUIAddress", "127.0.0.1");