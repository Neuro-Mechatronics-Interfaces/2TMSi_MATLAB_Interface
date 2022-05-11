%EXAMPLE__TMSI_STREAM_SERVICE
% Script that enables sampling from multiple devices, and streams data from
% those devices to a server continuously.
%
% --- The README.MD should now be most-current (5/8/22) -----
%
% NOTE: To use this code, you need to have a little bit of prior
%       information. I've modified the TMSiSAGA package from its original
%       state because I'm meddlesome and retentive like that. As such, you
%       need to get:
%           * The serial number of each SAGA unit
% 
%       And then you will need to assign each serial number to a
%       corresponding tag (I use "A", "B", ... etc.) and make sure that the
%       tags and serial numbers and ordering matches up so that elements
%       are matched. 
% 
%       You'll also need to make sure your network firewalls let MATLAB use
%       the UDP ports 3030-3035 (or whatever you select) and TCP/IP ports
%       5000-5050 (or whatever you select). Then just match up those values
%       in these scripts. I might just be really bad at IT but I had a hell
%       of a time getting that part to work and then magically walked in
%       the next day and it all worked without me ever changing the code so
%       either we have gremlins (like the good kind?) or it might require a
%       computer restart and then some quiet contemplation of your life's
%       choices (waiting) until the network gods decide to let you use
%       their ports. Anyways, consider yourself warned.
% 
% NOTE: ORDER OF OPERATIONS MATTERS FOR THESE SCRIPTS! Each of these steps
%       should be started in a separate MATLAB session, possibly using
%       different machines on the same network switch.
% 
%   1. On a local network computer (probably the one running TMSiSAGA
%       devices), you will first run `deploy__tmsi_tcp_servers.m`.
% 
%       This will start the control server. The control server broadcasts
%       to UDP ports 3030 ("state"), 3031 ("name"), and 3032 ("extra").
%       -> Technically there is also a `data` UDP at 3033, but that is not
%           a 
% 
%       The "state" port allows you to move the state machine between:
%       "idle", "run", "record", and "quit" states (as of 5/7/22). 
% 
%       The "name" port broadcasts the current filename to any udp 
%       receivers listening on that port within the local network. 
% 
%           For example, a common local network is "10.0.0.x" for devices 
%           network, or "192.168.1.x" or "192.168.0.x" for devices 
%           connected to a network router or switch respectively. The 
%           broadcast address for a network is "a.b.c.255" network device
%           "a.b.c.x".
% 
%       The "extra" port is just a loopback that broadcasts whatever was
%       sent to the control server as a string as it was received (e.g.
%       "set.tank.random/random_3025_01_02" for subject "random" and date
%       "3025-01-02"). 
% 
%   2. Once the TMSi control/data servers are running, next start
%       another MATLAB session and run the `example__tmsi_stream_service.m`
%       (this script) to open communication with the TMSi SAGA device(s). 
%       
%           This runs a set of nested blocking loops which handle sampling 
%           from those devices and querying the control server state. Two
%           sets of buffers are created:
% 
%               `buffer` - One for each SAGA device. This is a smaller
%                           buffer; the sets of samples from each call to
%                           SAGA device array are appended to this buffer
%                           and each buffer element has an event listener
%                           with a callback that is triggered when the
%                           buffer fills up. This basically acts as a
%                           circular buffer, and the callback re-indexes
%                           the data so that samples are sent in the
%                           correct order. AS OF 5/8/22, TESTING INDICATES
%                           THAT PASSING SAMPLES VIA TCP I LOSE ~40-200
%                           SAMPLES ON EACH "FRAME" OF ~16k SAMPLES. THAT
%                           IS ~1% SAMPLE LOSS WHICH IS OKAY FOR MY
%                           APPLICATION BUT SOMETHING YOU SHOULD NOTE IF
%                           YOU USE THIS CODE!
% 
%               `rec_buffer` - These should be LARGER buffers (currently I
%                               have it as of 5/8/22 set so that they store
%                               up to 10 minutes of data before looping
%                               back around, that is overkill for the
%                               length of triggered recordings I anticipate
%                               using for my purposes but just be aware of
%                               this, I have not set anything to handle the
%                               case where it loops back on itself and
%                               overwrites data). FROM TESTING AS OF
%                               5/8/22, I DO NOT SEE ANY SAMPLE LOSS WHEN
%                               DUMPING THE SAME SAMPLES INTO `rec_buffer`
%                               AS I DUMP INTO `buffer`. Therefore, I am
%                               pretty sure the sample loss via
%                               tcpclient/tcpserver interaction is due to
%                               the circular buffer having a mismatch on
%                               the total number of samples each time. I'm
%                               sure there is a better way to do it than
%                               what I'm doing, but I don't want to spend
%                               more time on it right now, so again, PLEASE
%                               BE AWARE OF THESE LIMITATIONS IF YOU USE
%                               THIS CODE!!
% 
%   3. The last thing to do is, most-likely in the same session running the
%   servers (but you could do this in a third, separate session just to be
%   safe) you would start a `tcpclient` to connect to the "CONTROL" server.
%   
%   Currently there are only two API functions for the "CONTROL"
%   client/server interactions:
%       + client__set_rec_name_metadata  - This just sets what your
%                                           filename metadata should be.
%                                           You should make sure that this
%                                           increments between each
%                                           recording so that you do not
%                                           overwrite an existing file, it
%                                           doesn't as of 5/8/22 have
%                                           anything built-in to check for
%                                           that.
%       + client__set_saga_state       - This sets the state of the SAGA.
%           You can either set it to "idle" | "run" | "rec" | "quit"
%               "idle" -> does nothing
%               "run"  -> stream data to tcpserver, but do not dump to diskfile
%               "rec"  -> stream data to tcpserver and also dump to diskfile
%               "quit" -> stop collecting data and shut down the SAGAs.
% 
%           At some point I will probably also add something like "imp" to
%           do a quick impedance test, but I haven't put that in as of
%           5/8/22.
% 
%        So at this point, your workflow is basically:
%           a. Create tcpclient connected to control server
%           b. Make sure that the SAGA loop is already running. If you
%               clicked the run button for steps 1. and 2. you should be 
%               good at this point. This really shouldn't be in the list.
%           c. Alternate as: i. client__set_rec_name_metadata(...)
%                           ii. client__set_saga_state("rec" (or "run"))
%                          iii. client__set_saga_state("idle"), then back
%                                   to (i) until
%                           iv. client__set_saga_state("quit")
% 
%   At this point I haven't done much to test the shutdown but basically
%   PLEASE MAKE SURE TO CALL THE `lib.cleanUp();` at the end on whichever
%   session is running the SAGA devices. I may have commented it out on my
%   end during testing so just again, double-check that before you start
%   the script. If you intend to cycle through
%   `client__set_saga_state("quit")` a bunch, then you might consider
%   commenting it out as once you call `lib.cleanup` you'll have to re-run
%   all the way through step 2 again rather than just restarting the loop.
%   Note that you should be able to keep whatever client from step 3 even
%   if you have to go back to step 2 so, now that I think about it, steps 2
%   and 3 should probably flip but I'm too lazy to go back and fix that
%   part.

%% Handle some basic startup stuff.
clc;
if exist('server', 'var')~=0
    delete(dev_server);
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
BROADCAST_ADDRESS = "10.0.0.255";
SERVER_ADDRESS = "10.0.0.81";
WORKER_ADDRESS = "128.2.244.29";    % Max desktop processing
UDP_STATE_BROADCAST_PORT = 3030;    % UDP port: state
UDP_NAME_BROADCAST_PORT = 3031;     % UDP port: name
UDP_EXTRA_BROADCAST_PORT = 3032;    % UDP port: extra
UDP_DATA_BROADCAST_PORT  = 3034;    % UDP port: data
UDP_CONTROLLER_RECV_PORT = 3035;    % UDP port: receiver (controller)
SERVER_PORT_CONTROLLER = 5000;           % Server port for CONTROLLER
SERVER_PORT_DATA = struct;
SERVER_PORT_DATA.A    = 5020;           % Server port for DATA from SAGA-A
SERVER_PORT_DATA.B    = 5021;           % Server port for DATA from SAGA-B
SERVER_PORT_WORKER = struct;
SERVER_PORT_WORKER.A = 4000;
SERVER_PORT_WORKER.B = 4001;
DEFAULT_DATA_SHARE = "R:\NMLShare\raw_data\primate";
DEFAULT_SUBJ = "Test";
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
SN = [1005210029; 1005210028];
TAG = ["B"; "A"];
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
worker = [ ...
    tcpclient(WORKER_ADDRESS, SERVER_PORT_WORKER.(device(1).tag)); ...
    tcpclient(WORKER_ADDRESS, SERVER_PORT_WORKER.(device(2).tag))
    ];
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
    start(device);
    state = "idle";
    fname = "default_%s.mat";  % fname should always have "%s" in it so that array is added by the StreamBuffer object save method.
    recording = false;
    
    while ~strcmpi(state, "quit")
        if udp_name_receiver.NumBytesAvailable > 0
            fname = udp_name_receiver.readline(); 
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
                else
                    if recording
                        fprintf(1, "complete\n\t->\t(%s)\n", fname);
                        rec_buffer.save(fname);
                        delete(rec_buffer);
                        clear rec_buffer;
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
            else
                if recording
                    fprintf(1, "complete\n\t->\t(%s)\n", fname);
                    rec_buffer.save(fname);
                    delete(rec_buffer);
                    clear rec_buffer;
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
                recording = false; 
            end
        end
    end
    stop(device);
    state = "idle";
    recording = false;
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
