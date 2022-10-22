%DEPLOY__TMSI_STREAM_SERVICE - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) server.
% See details in README.MD

%% Handle some basic startup stuff.
clc;
if exist('server', 'var')~=0
    delete(server);
end

if exist('device', 'var')~=0
    disconnect(device);
end

if exist('lib', 'var')~=0
    lib.cleanUp();
end

if ~libisloaded(TMSiSAGA.DeviceLib.alias())
    clear all;
else
    unloadlibrary(TMSiSAGA.DeviceLib.alias())
    clear all;
end

%% SET PARAMETERS
SERVER_ADDRESS = "127.0.0.1";        % Host machine for TMSiSAGA ("Stream Server"; most-likely "localhost")
WORKER_ADDRESS = "172.26.32.199";        % Can be Max desktop ("128.2.244.29") or Backyard Brains ("172.26.32.199")
UDP_STATE_BROADCAST_PORT = 3030;    % UDP port: state
UDP_NAME_BROADCAST_PORT = 3031;     % UDP port: name
UDP_EXTRA_BROADCAST_PORT = 3032;    % UDP port: extra
UDP_TASK_BROADCAST_PORT  = 3033;    % UDP port: task
UDP_DATA_BROADCAST_PORT  = 3034;    % UDP port: data
UDP_CONTROLLER_RECV_PORT = 3035;    % UDP port: receiver (controller)
SERVER_PORT_CONTROLLER = 5000;          % Server port for CONTROLLER
SERVER_PORT_DATA = struct;
SERVER_PORT_DATA.A    = 5020;           % Server port for DATA from SAGA-A
SERVER_PORT_DATA.B    = 5021;           % Server port for DATA from SAGA-B
SERVER_PORT_WORKER = struct;
SERVER_PORT_WORKER.A = 4000;
SERVER_PORT_WORKER.B = 4001;
USE_WORKER = false; % Set to true if the worker will actually be deployed (MUST BE DEPLOYED BEFORE RUNNING THIS SCRIPT IF SET TO TRUE).
DEFAULT_DATA_SHARE = string(parameters('raw_data_folder'));
DEFAULT_SUBJ = "Max";
N_SAMPLES_LOOP_BUFFER = 16384;

% Set this to LONGER than you think your recording should be, otherwise it
% will loop back on itself! %
N_SAMPLES_RECORD_MAX = 4000 * 60 * 10; % (sample rate) * (seconds/min) * (max. desired minutes to record)
% 5/8/22 - On NHP-Dell-C01 takes memory from 55% to 70% to pre-allocate 2
% cell arrays of randn for 72 channels each with enough samples for
% 10-minutes (to get an idea of scaling). 
%   -> General rule of thumb: better to pre-allocate big array of random
%       noise, then "gain" memory by indexed assignment into it, than to
%       run out of memory while running the loop.
% TODO: Add something that will increment a sub-block index so that it
% auto-saves if the buffer overflows, maybe using a flag on the buffer
% object to do this or subclassing to a new buffer class that is
% specifically meant for saving stream records.

% SN = [1005210029; 1005210028]; % NHP-B; NHP-A | docking stations / bottom
% TAG = ["B"; "A"];

% SN = [1005210038]; % SAGA-3 (wean | docking station / bottom half)
% TAG = "S3"; 

% SN = [1000210046]; % SAGA-3 (wean | data recorder / top half)
% TAG = "S3";

% SN = [1005220030; 1005220009]; % SAGA-4; SAGA-5 (wean | docking stations / bottom half)
% TAG = ["S4"; "S5"];

SN = [1000220037; 1000220035];
TAG = ["A"; "B"]; % Arbitrary  - "A" is SAGA-4 and "B" is SAGA-5

N_CLIENT = numel(TAG);

%% Setup device configurations.
config_device = struct('Dividers', {{'uni', 0; 'bip', 0}}, ...
                        'Triggers', true, ...
                        'BaseSampleRate', 4000, ...
                        'RepairLogging', false, ...
                        'ImpedanceMode', false, ...
                        'AutoReferenceMethod', false, ...
                        'ReferenceMethod', 'common',...
                        'SyncOutDivider', 4000, ...
                        'SyncOutDutyCycle', 500);
config_channels = struct('uni', 1:64, ...
                         'bip', 1:4, ...
                         'dig', 0, ...
                         'acc', 0);
channels = struct('A', struct('CREF', 1,  'UNI', 2:65, 'BIP', 66:69, 'TRIG', 70, 'STAT', 71, 'COUNT', 72, 'n', struct('channels', 72, 'samples', N_SAMPLES_LOOP_BUFFER)), ...
                  'B', struct('CREF', 1,  'UNI', 2:65, 'BIP', 66:69, 'TRIG', 70, 'STAT', 71, 'COUNT', 72, 'n', struct('channels', 72, 'samples', N_SAMPLES_LOOP_BUFFER)));


%% Open device connections
% Initialize the library
lib = TMSiSAGA.Library();
try
    % Code within the try-catch to ensure that all devices are stopped and 
    % closed properly in case of a failure.
    device = lib.getDevices({'usb'}, {'electrical'});  
    connect(device); 
catch e
    % In case of an error close all still active devices and clean up
    lib.cleanUp();  
        
    % Rethrow error to ensure you get a message in console
    rethrow(e)
end

%% Retrieve data about the devices.
try % Separate try loop because now we must be sure to disconnect device.
    setDeviceTag(device, SN, TAG);
    info = getDeviceInfo(device);
    enableChannels(device, horzcat({device.channels}));
    updateDeviceConfig(device);   
    device.setChannelConfig(config_channels);
    device.setDeviceConfig(config_device); 
catch e
    disconnect(device);
    lib.cleanUp();
    rethrow(e);
end

%% Create TMSi stream client + udpport
udp_state_receiver = udpport("byte", "LocalPort", UDP_STATE_BROADCAST_PORT, "EnablePortSharing", true);
udp_name_receiver = udpport("byte", "LocalPort", UDP_NAME_BROADCAST_PORT, "EnablePortSharing", true);
ch = device.getActiveChannels();
client = [ ...
        tcpclient(SERVER_ADDRESS, SERVER_PORT_DATA.(device(1).tag)); ...
        tcpclient(SERVER_ADDRESS, SERVER_PORT_DATA.(device(2).tag))  ...
        ];
if USE_WORKER
    worker = [ ...
        tcpclient(WORKER_ADDRESS, SERVER_PORT_WORKER.(device(1).tag)); ...
        tcpclient(WORKER_ADDRESS, SERVER_PORT_WORKER.(device(2).tag))
        ];
end
buffer = [ ...
        StreamBuffer(ch{1}, channels.(device(1).tag).n.samples, device(1).tag, device(1).sample_rate), ...
        StreamBuffer(ch{2}, channels.(device(2).tag).n.samples, device(2).tag, device(2).sample_rate) ...
        ];
buffer_event_listener = [ ...
    addlistener(buffer(1), "FrameFilledEvent", @(src, evt)evt__frame_filled_cb(src, evt, client(1))); ...
    addlistener(buffer(2), "FrameFilledEvent", @(src, evt)evt__frame_filled_cb(src, evt, client(2))) ...
    ]; %#ok<NASGU>


%%
try % Final try loop because now if we stopped for example due to ctrl+c, it is not necessarily an error.
    
    state = "idle";
    fname = strrep(fullfile(DEFAULT_DATA_SHARE,"default","default_%s.mat"), "\", "/");  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    recording = false;
    running = false;
    fprintf(1, "\n<strong>>>\t\t%s::SAGA LOOP BEGIN</strong>\n\n", ...
        string(datetime('now')));
    
    while ~strcmpi(state, "quit")
        if udp_name_receiver.NumBytesAvailable > 0
            tmp = udp_name_receiver.readline();
            if startsWith(strrep(tmp, "\", "/"), DEFAULT_DATA_SHARE)
                fname = tmp;
            else
                fname = strrep(fullfile(DEFAULT_DATA_SHARE, tmp), "\", "/"); 
            end
            fprintf(1, "File name updated: <strong>%s</strong>\n", fname);
        end
        while (~strcmpi(state, "idle")) && (~strcmpi(state, "quit"))
            [samples, num_sets] = device.sample();
            buffer.append(samples);
            if udp_state_receiver.NumBytesAvailable > 0
                state = readline(udp_state_receiver);
                if strcmpi(state, "rec")
                    if ~recording
                        fprintf(1, "Buffer created, recording in process...");
                        rec_buffer = [ ...
                            StreamBuffer(ch{1}, N_SAMPLES_RECORD_MAX, device(1).tag), ...
                            StreamBuffer(ch{2}, N_SAMPLES_RECORD_MAX, device(2).tag) ...
                        ];
                    end
                    recording = true;
                    running = true;
                elseif ~strcmpi(state, "run")
                    running = false;
                    stop(device);
                    if recording
                        fprintf(1, "complete\n\t->\t(%s)\n", fname);
                        rec_buffer.save(fname);
                        delete(rec_buffer);
                        clear rec_buffer;
                        if USE_WORKER
                            [~, finfo, ~] = fileparts(fname);
                            args = strsplit(finfo, "_");
                            for iWorker = 1:numel(worker)
                                worker(iWorker).writeline(...
                                    string(sprintf('%s.%d.%d.%d.%s', ...
                                        args{1}, ...
                                        str2double(args{2}), ...
                                        str2double(args{3}), ...
                                        str2double(args{4}), ...
                                        args{6}))); 
                            end
                        end
                    end
                    recording = false; 
                end
            end          
            if recording
                rec_buffer.append(samples);
            end            
        end
        if udp_state_receiver.NumBytesAvailable > 0
            state = readline(udp_state_receiver);
            if strcmpi(state, "rec")
                if ~recording
                    fprintf(1, "Buffer created, recording in process...");
                    rec_buffer = [ ...
                        StreamBuffer(ch{1}, N_SAMPLES_RECORD_MAX, device(1).tag, device(1).sample_rate), ...
                        StreamBuffer(ch{2}, N_SAMPLES_RECORD_MAX, device(2).tag, device(2).sample_rate) ...
                    ];
                end
                recording = true;
                if ~running
                    start(device);
                    running = true;
                end
            elseif strcmpi(state, "run")
                if ~running
                    start(device);
                    running = true;
                end
            else
                if recording
                    fprintf(1, "complete\n\t->\t(%s)\n", fname);
                    rec_buffer.save(fname);
                    delete(rec_buffer);
                    clear rec_buffer;
                    if USE_WORKER
                        [~, finfo, ~] = fileparts(fname);
                        args = strsplit(finfo, "_");
                        for iWorker = 1:numel(worker)
                            worker(iWorker).writeline(...
                                string(sprintf('%s.%d.%d.%d.%s', ...
                                    args{1}, ...
                                    str2double(args{2}), ...
                                    str2double(args{3}), ...
                                    str2double(args{4}), ...
                                    args{6}))); 
                        end
                    end
                end
                if running
                    stop(device); 
                end
                recording = false; 
                running = false;
            end
        end
    end
    stop(device);
    state = "idle";
    recording = false;
    running = false;
    disconnect(device);
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    
catch me
    % Stop both devices.
    stop(device);
    disconnect(device);
    warning(me.message);
    clear client worker buffer buffer_event_listener udp_state_receiver udp_name_receiver
    lib.cleanUp();  % % % Make sure to run this when you are done! % % %
    fprintf(1, '\n\n-->\tTMSi stream stopped at %s\t<--\n\n', ...
        string(datetime('now')));
end
