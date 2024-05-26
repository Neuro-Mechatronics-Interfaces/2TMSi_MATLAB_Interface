%%EXAMPLE_WAVEFORMS_PIANOGEN  Access Waveforms AD2 via dwf library.
%#ok<*UNRCH>

close all force;
clear;
clc;

% Add the path to the WaveForms SDK
addpath('C:\Program Files (x86)\Digilent\WaveFormsSDK\lib\x86');
addpath('C:\Program Files (x86)\Digilent\WaveformsSDK\inc');

% Load the WaveForms SDK library
if ~libisloaded('dwf')
    loadlibrary('dwf.dll', 'dwf.h', 'alias', 'dwf');
end

% Enumeration for AnalogOutNode
AnalogOutNodeCarrier = int32(0);
AnalogOutNodeFM = int32(1);
AnalogOutNodeAM = int32(2);

% Create a handle for the device
hdwf = libpointer('int32Ptr', 0);
calllib('dwf', 'FDwfDeviceOpen', int32(-1), hdwf);
if hdwf.Value == 0
    disp('Failed to open device');
    unloadlibrary('dwf');
    return;
end

% Notes and other parameters
notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
octaveUp = 2;
damping = 0.9;
duration = 10; % seconds
% duration = 1;
numSamples = 8192; 
samplingRate = numSamples * duration;
% samplingRate = 44100;
offset = -1.0;  % Set the desired offset (in volts)
amplitude = 2.0;  % Set the desired amplitude scale (in volts)


% Generate FM and AM arrays for a sample song (e.g., Happy Birthday)
% text = "C C D C F E | C C D C G F | C C +C A F E D | A# A# A F G FFF |||";
text = "E F# G F# E F# G F# E D -B |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G G A G A B A G F# E |" + ...
    "F# A A -B B B A B A |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G G A G A B A G F# E |" + ...
    "F# A A -B B B A B A |" + ...
    "|" + ...
    "A A A G G +C B A G G C B|" + ...
    "A A A G G +C B A G G C B|" + ...
    "|" + ...
    "D B E D B D B A B D |" + ...
    "D B E D B D B C B G|" + ...
    "D B E D B D B A B D |" + ...
    "D B E D B D B C B G|" + ...
    "|" + ...
    "|" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G G A G A B A G F# E |" + ...
    "F# A A -B B B A B A |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G F# E F# G F# E D -B |" + ...
    "E F# G G A G A B A G F# E |" + ...
    "F# A A -B B B A B A |" + ...
    "|" + ...
    "A A A G G +C B A G G C B|" + ...
    "A A A G G +C B A G G C B|" + ...
    "|" + ...
    "B B D D +G G F# |" + ...
    "B B +D D + B B A |" + ...
    "B B D D E E D |" + ...
    "E E E D D D -A B A |" + ...
    "B B D D +G G F# |" + ...
    "B B +D D +B B A |" + ...
    "B B D D E E D |" + ...
    "E E E D D D -A B A |" + ...
    "|" + ...
    "|" + ...
    "A A A G G +C B A G G C B|" + ...
    "A A A G G +C B A G G C B|||||";

[rgFM, rgAM] = generate_modulation_arrays(text, notes, octaveUp, damping);

% Convert the arrays to the format required by the WaveForms SDK
rgFM_ptr = libpointer('doublePtr', rgFM);
rgAM_ptr = libpointer('doublePtr', rgAM);

% Set up Wavegen with modulation
calllib('dwf', 'FDwfAnalogOutNodeEnableSet', hdwf.Value, int32(0), int32(0), int32(1));
calllib('dwf', 'FDwfAnalogOutNodeFunctionSet', hdwf.Value, int32(0), int32(0), int32(30)); % Custom
calllib('dwf', 'FDwfAnalogOutNodeFunctionSet', hdwf.Value, int32(0), int32(1), int32(30)); % Custom

% Set up FM modulation data
calllib('dwf', 'FDwfAnalogOutNodeDataSet', hdwf.Value, int32(0), int32(0), rgFM_ptr, length(rgFM));

% Set up AM modulation data
calllib('dwf', 'FDwfAnalogOutNodeDataSet', hdwf.Value, int32(0), int32(1), rgAM_ptr, length(rgAM));

% Set the offset and amplitude of waveform
calllib('dwf', 'FDwfAnalogOutNodeOffsetSet', hdwf.Value, 0, 0, offset);
calllib('dwf', 'FDwfAnalogOutNodeAmplitudeSet', hdwf.Value, 0, 0, amplitude);



% % % Set up Oscilloscope % % %
calllib('dwf', 'FDwfAnalogInFrequencySet', hdwf.Value, samplingRate);

% Set the acquisition mode (record mode for continuous data acquisition)
calllib('dwf', 'FDwfAnalogInAcquisitionModeSet', hdwf.Value, int32(2)); % Record mode


% Set the buffer size to match the number of samples per refresh interval
calllib('dwf', 'FDwfAnalogInBufferSizeSet', hdwf.Value, numSamples);

% Enable the first analog input channel
calllib('dwf', 'FDwfAnalogInChannelEnableSet', hdwf.Value, int32(0), int32(1));
calllib('dwf', 'FDwfAnalogInChannelRangeSet', hdwf.Value, int32(0), 5.0); % 5V range

% Start the oscilloscope
calllib('dwf', 'FDwfAnalogInConfigure', hdwf.Value, int32(1), int32(1));

% Start the waveform
% int32(0) -- First analog output channel
% int32(1) -- Enumeration to start playing
calllib('dwf', 'FDwfAnalogOutConfigure', hdwf.Value, int32(0), int32(1));

% Wait for the waveform to complete
% pause(length(rgFM) / rhythm);
statusPtr = libpointer('uint8Ptr',0);
timeData = linspace(0, duration, numSamples * duration);
buffer = libpointer('doublePtr', zeros(1, numSamples));
fig = init_oscope_figure('ScopeChannel',1,'TimeData',timeData);

% Read data and update plot
% duration = length(rgFM) / rhythm; % duration of the waveform
% startTime = tic;
% while toc(startTime) < duration
vec = 1:numSamples;
iBuffer = 1;
while isvalid(fig)
    % Trigger and read data
    calllib('dwf', 'FDwfAnalogInStatus', hdwf.Value, true, statusPtr); % Corrected function call

    % Read data only if the acquisition state indicates data is ready
    if statusPtr.Value == 3 % DwfStateDone
        calllib('dwf', 'FDwfAnalogInStatus', hdwf.Value, false, statusPtr); % Corrected function call
        calllib('dwf', 'FDwfAnalogInStatusData', hdwf.Value, int32(0), buffer, numSamples);
        fig.UserData.ScopeLine.YData(vec + (iBuffer-1)*numSamples) = buffer.Value;
        iBuffer = rem(iBuffer,duration)+1;
        drawnow;
    else
        pause(0.010);
    end
end

%% Stop the waveform
calllib('dwf', 'FDwfAnalogOutConfigure', hdwf.Value, int32(0), int32(0));
calllib('dwf', 'FDwfAnalogInConfigure', hdwf.Value, int32(0), int32(0));

% Close the device
calllib('dwf', 'FDwfDeviceClose', hdwf.Value);

% Unload the WaveForms SDK library
unloadlibrary('dwf');