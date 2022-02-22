clear all
close all
clc

%% Imput Stimulation Parameters
Daq_Rate = 10000;
StimAmp_UL = 50; % highest stim intensity
StimAmp_LL = 5; % lowest stim intensity
Stim_Reps = 1; % number of pulses per intensity level
Stim_interval = 1; % amount of time between pulses (seconds)
n_steps = 10; % total number of intensity levels

% %% Create Amplitude Trains
StimAmps = linspace(StimAmp_LL,StimAmp_UL,n_steps);
Stim_Trains_stair = repelem(StimAmps,Stim_Reps*Daq_Rate*Stim_interval);
Stim_Trains_stair2d = reshape(Stim_Trains_stair,Stim_Reps*Daq_Rate*Stim_interval,[])';
N_trains = Stim_Trains_stair2d;
Stim_amp_order =  repelem(StimAmps,Stim_Reps);

%% Generate Stimulation Trigger
iTrain = 1;
while(iTrain<=size(N_trains,1))
    clc
    Next_Stimulation_Amplitude = N_trains(iTrain,1)
    s = daq.createSession('ni');
    s.Rate = Daq_Rate;
    CTRch_stim = addCounterOutputChannel(s,'Dev1','ctr0','PulseGeneration');
    Stim_amp_ch = addAnalogOutputChannel(s,'Dev1','ao0','Voltage');  % Analog Output 1 of extended ports (For Stim amplitude modulation)
    CTRch_stim.Frequency = 1/Stim_interval;
    CTRch_stim.DutyCycle = 0.01;
    CTRch_stim.InitialDelay=0.5;
    Amplitude_vector = N_trains(iTrain,:)*10/1000;
    Amplitude_vector(1,end)=0;
    queueOutputData(s,Amplitude_vector');
    [datain, time] = startForeground(s);
    pause;
    iTrain=iTrain+1;
end
clc
