close all force;
clear; clc;


PULSE_REFRESH_PERIOD = 2.5; % seconds
PULSE_MS = round(1e3 * PULSE_REFRESH_PERIOD);

% Amplitude modulation parameters
AMP_MOD_PERIOD = 0.65; % sec
MIN_AMP = 0.15;
MAX_AMP = 0.85;
FIXED_FREQ = 1000; % Hz (fixed frequency during AM set)
AMP = @(t)(MIN_AMP+MAX_AMP)/2 + 0.5*(MAX_AMP - MIN_AMP)*cos(2 * pi / AMP_MOD_PERIOD * t);

% Frequency modulation parameters
FREQ_MOD_PERIOD = 1.3; % sec
MIN_FREQ = 500;
MAX_FREQ = 2500;
FIXED_AMP = 0.85; % 0 - 1 (fixed amplitude during FM set)
FREQ = @(t)round((MIN_FREQ+MAX_FREQ)/2 + 0.5*(MAX_FREQ - MIN_FREQ)*cos(2 * pi / FREQ_MOD_PERIOD * t));

%% Open connection to the tactor
deviceID = tdk.open(); % This calls tdk.setup() automatically

%% Static loop
fig = figure('Name','Buzzer Modulation','Color','k', ...
    'Position',[350   444   727   138], ...
    'MenuBar', 'none', 'ToolBar', 'none');
uicontrol(fig,'Style','text','String',["Static Loop"; sprintf("(%d-Hz @ %d%%)", FIXED_FREQ, round(100*FIXED_AMP))], ...
    'FontName','Consolas','FontSize',32,'ForegroundColor','w', ...
    'BackgroundColor', 'k', 'Units', 'normalized', 'Position', [0 0 1 1], ...
    'HorizontalAlignment','center');
tdk.setGain(deviceID,FIXED_AMP);
tdk.setFrequency(deviceID,FIXED_FREQ);
pause(0.1);

pulseTic = tic;
while isvalid(fig)
    tPulse = toc(pulseTic);
    if (tPulse > PULSE_REFRESH_PERIOD)
        tdk.stop(deviceID);
        tdk.pulse(deviceID,PULSE_MS); % Keep buzzing
        pulseTic = tic;
    end
    pause(0.00025);
end

%% Amplitude modulation loop
fig = figure('Name','Buzzer Modulation','Color','k', ...
    'Position',[413   544   727   138], ...
    'MenuBar', 'none', 'ToolBar', 'none');
uicontrol(fig,'Style','text','String',[""; "Amplitude Modulation Loop"; ""], ...
    'FontName','Consolas','FontSize',32,'ForegroundColor','w', ...
    'BackgroundColor', 'k', 'Units', 'normalized', 'Position', [0 0 1 1], ...
    'HorizontalAlignment','center');
tdk.setFrequency(deviceID,FIXED_FREQ);
pause(0.1);

pulseTic = tic;
while isvalid(fig)
    tPulse = toc(pulseTic);
    if (tPulse > PULSE_REFRESH_PERIOD)
        tdk.stop(deviceID);
        a = AMP([tPulse,tPulse+PULSE_REFRESH_PERIOD]);
        tdk.setGainRamp(deviceID,a(1),a(2),PULSE_MS);
        tdk.pulse(deviceID,PULSE_MS); % Keep buzzing
        pulseTic = tic;
    end
    pause(0.00025);
end

%% Frequency modulation loop
fig = figure('Name','Buzzer Modulation','Color','k', ...
    'Position',[350   444   727   138], ...
    'MenuBar', 'none', 'ToolBar', 'none');
uicontrol(fig,'Style','text','String',[""; "Frequency Modulation Loop"; ""], ...
    'FontName','Consolas','FontSize',32,'ForegroundColor','w', ...
    'BackgroundColor', 'k', 'Units', 'normalized', 'Position', [0 0 1 1], ...
    'HorizontalAlignment','center');
tdk.setGain(deviceID,FIXED_AMP);
pause(0.1);

pulseTic = tic;
while isvalid(fig)
    tPulse = toc(pulseTic);
    if (tPulse > PULSE_REFRESH_PERIOD)
        tdk.stop(deviceID);
        f = FREQ([tPulse,tPulse+PULSE_REFRESH_PERIOD]);
        tdk.setFrequencyRamp(deviceID,f(1),f(2),PULSE_MS);
        tdk.pulse(deviceID,PULSE_MS); % Keep buzzing
        pulseTic = tic;
    end
    pause(0.00025);
end



%% Close tactor connection
tdk.close();
