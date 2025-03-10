# Network and Messaging #

## UDP ## 
Currently, the direct pathway to control the state machine running the 2TMSi acquisition loop is via UDP packets. There are three main sockets you can send UDP messages to. Briefly, they are as follows:   
* `state` (port 3030) - Updates the control state of the acquisition state machine. 
* `name` (port 3031) - Updates the file names for the next recording.
* `params` (port 3036) - Updates various parameters in the acquisition loop. There are more parameters in the "advanced" (`_plus`) version.  

### UDP State Port Messages ###
The acquisition script sets up the state port with a udp socket as follows:  
```
udp_state_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.state, "EnablePortSharing", true);
```  
State port messages are expected to be new-line terminated byte messages, which should be one of the following: `["idle", "run", "rec", "imp", "quit", "ping"]`:  
* `idle`: Stops the SAGA64+ device from acquiring new samples. 
* `run`: Starts the SAGA64+ device acquiring samples and reads them from the device, updating streaming plots if they are enabled. Issues TCP messages via `SpikeServer` but does not save the data. If we were already recording, then this stops the current recording.  
* `rec`: If the SAGA64+ device is not already acquiring samples, this starts sample acquisition, updates streaming plots, and issues all TCP messages, but also dumps the samples into the recording file specified to the `name` port ([next section](#udp-name-port-messages)). 
* `imp`: Stops any ongoing recording. Pulls up electrode impedance plots for each SAGA. Once the figure windows are closed, saves the impedances based on the most-recent filename to a separate `_impedances.mat` file for each SAGA, and then goes back to the normal state machine operation. Does not send any TCP messages etc. while this is ongoing.  
* `quit`: Stop running the state machine loop and shut down the connection to SAGA devices. This should always be called before powering off/disconnecting the SAGA devices, otherwise next time bootup will be a pain in the ass.  
* `ping`: Query the current state of the state machine loop. Return messages will be sent as indicated by the cases below as newline-terminated byte messages with structure `"res:<state>"` (e.g. `"res:run"`) indicating this is a response to a ping.  
  + `ping` alone uses default configuration parameters for the return message.
  + `ping:<address>` (e.g. "ping:192.168.88.101") indicates the address for the return message. 
  + `ping:<address>:<port>` (e.g. "ping:192.168.88.101:4001") indicates the address and port for the return message. 

### UDP Name Port Messages ###
The acquisition script sets up the name port with a udp socket as follows:  
```
udp_name_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.name, "EnablePortSharing", true);
```  
Name messages are expected to be new-line terminated byte messages, which can be full file paths or relative filenames. The file part of the filename should contain "%s" somewhere, which is used to create separate save files for each SAGA unit based on the corresponding device tag string.  Example: `writeline(udpSock, "C:/Data/Folder_That_Does_Not_Exist/Subject_2024_03_15_%s_22.mat", "192.168.88.100", 3031);` would create the folder that does not exist, and then any subsequent recording would be saved in this file. Save files no longer have a maximum length with the "_plus.m" version.

### UDP Parameters Port Messages ###
The acquisition script sets up the parameter port with a udp socket as follows:  
```
udp_param_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.params, "EnablePortSharing", false);
```  
Parameter messages are expected to be new-line terminated byte messages, with the syntax:  
```
data = readline(udp_param_receiver);
data_syntax = strsplit(data, '.');
parameter_code = data_syntax{1};
parameter_value = data_syntax{2};
```
So it is essentially a key-value message with the leading single-character byte code indicating which parameter field to populate. The following table contains examples demonstrating how to set parameters, assuming you are sending UDP byte messages using a MATLAB `udpport` object created as `udpSock = udpport("byte");` allowing you to send UDP messages to the state machine, which is running on the device at "192.168.88.100" and with the `param` port configured to 3036 (the default value):    
| Parameter | Code | Description                                              |
| :-------: | :--: | :------------------------------------------------------- |
| **CAR** | `a` | Specify whether or not to use common average reference (CAR), and optionally the threshold proportion (0-1000, to be divided by 1000 to get proportion between 0 and 1) for excluding artifact spikes in terms of the number of synchronous spike channels on each sample instant.  Example 1: `writeline(udpSock, "a.0", "192.168.88.100", 3036);` stops using CAR.  Example 2: `writeline(udpSock, "a.1", "192.168.88.100", 3036);` uses CAR under the assumption of 1 array (64-channel 8x8 grid).  Example 3: `writeline(udpSock, "a.2", "192.168.88.100", 3036);` uses CAR under the assumption of 2 arrays (32-channel 4x8 textile grids).  Example 4: `writeline(udpSock, "a.2:750", "192.168.88.100", 3036);` uses CAR with 2 textile arrays, and changes the `param.threshold_artifact` value to 0.75 (default is 0.4).  Example 5: `writeline(udpSock, "a.3", "192.168.88.100", 3036);` Sets CAR mode to Discrete Laplacian. |
| **Tag** | `b` | Sets the tag associated with filename (only for saving/filename purposes) for each SAGA.  Example 1:  `writeline(udpSock, "b.A:FLX", "192.168.88.100", 3036);` sets the files generated by SAGA-A to have "FLX" in the filename.  Example 2: `writeline(udpSock, "b.B:EXT", "192.168.88.100", 3036);` sets the Poly5 files generated by SAGA-B to have "EXT" in the filename where "B" usually would go. |
| **Output State Trigger Bits** | `c` | Sets the bit to use for toggling mouse-click.  Example: `writeline(udpSock, "c.2,3", "192.168.88.100", 3036);` sets the trigger-bit for left-click BIT-2 and trigger-bit for right-click to BIT-3 which will toggle the mouse click based on state of that BIT, if enabled. |
| **Classifier File** | `d` | Loads the specified classifier file. This file should have two variables, 'A' and 'B', each of which are structs containing the fields 'Channels', 'Net', and 'MinPeakHeight'.  Example 1: `writeline(udpSock,"d.C:/Data/MyAdHocClassifier.mat","192.168.88.100",3036);` uses the contents of the specified file.  Example 2: writeline(udpSock, "d.A|C:/Data/MyAdHocClassifierForSAGA_A_Only.mat", "192.168.88.100, 3036);` |
| **Save Location** | `f` | Set the save file location using `f.<folder>`.  Example: `writeline(udpSock, "f.C:/Data", "192.168.88.100", 3036);` sets save file root folder to `"C:/Data"`. This gets ignored if you set the full file path explicitly using the `name` port.|
| **GUI Samples** | `g` | Use `g.<# samples>` to specify the number of samples in the GUI line plots.  Example: `writeline(udpSock, "f.C:/Data", "192.168.88.100", 3036);` |
| **HPF Cutoff Frequency** | `h` | Use `h.<fc>` to specify the highpass filter cutoff frequency. Default is 100-Hz. Uses the `config.Default.Sample_Rate` defined in `config_stream_service_plus__default.yaml` to calculate the normalized frequency, then designs the highpass filter as a third-order butterworth filter. | 
| **Interpolate Grid** | `i` | Turns grid interpolation ON/OFF. Note that ON mode only works if CAR is set to mode 3; also, this incurs a noticeable performance hit on the acquisition loop.  `Example: writeline(udpSock, "i.1", "192.168.88.100", 3036);` Turns ON the grid interpolation; "i.0" would turn it OFF. |
| **Envelope LPF Cutoff Frequency** | `j` | Use `j.<fc_lpf*1000>` to specify the RMS envelope lowpass filter cutoff frequency. Multiplying by 1000 makes the integer string-parsing work on receiver end. Default is 0.5-Hz. Uses the `config.Default.Sample_Rate` defined in `config_stream_service_plus__default.yaml` to calculate the normalized frequency, then designs the lowpass filter as a third-order butterworth filter. | 
| **Envelope Classifier** | `k` | Loads the envelope classifier, which should take the same number of samples as you are streaming (if both, then takes 128 with "A" first then "B" grid channels). Expects smoothed envelope data.  Example: `writeline(udpSock,"k.C:/Data/MyAdHocEnvelopeClassifier.mat","10.0.0.100",3036);` uses the contents of the specified file. |
| **Left/Right Channel Selector** | `l` | Sets the left or right channel index for use with output state triggers.  Example: `writeline(udpSock, "l.L:5", "192.168.88.100", 3036);` will set left-trigger output to channel 5.  Example: `writeline(udpSock, "l.R:65", "192.168.88.100", 3036);` will set right-trigger output to channel 65. |
| **MVC Samples** | `m` | Begin acquiring for MVC using this many sample iterations.  Example: `writeline(udpSock, "m.10", "192.168.88.100", 3036);` will loop for 10 iterations to acquire the MVC value. | 
| **ALL HIGH/LOW Cut Frequencies** | `n` | Added for the EEG/EMG combo interface. Use `n.<fc_hpf_A>:<fc_lpf_A>:<fc_hpf_B>:<fc_lpf_B>` for setting the LPF/HPF on all filters, uniquely for A/B. Example: `writeline(udpSock, "n.13:30:100:500", "127.0.0.1", 3036);` will set SAGA-A to BPF 13-30 Hz (i.e. Beta band) with 100-500Hz for the EMG on SAGA-B.  | 
| **Squiggles Line Offsets** | `o` | Sets the spacing between squiggle lines (units are in microvolts).  Example: `writeline(udpSock, "o.100", "192.168.88.100", 3036);` set spacing for 100 uV between squiggles lines.|
| **Bit or Threshold Parsing** | `p` | Switch between Bit-Parsing ("1") or Threshold-Parsing ("0") using syntax `<bit/thresh>:<left-sliding-thresh>:<left-rising-thresh>:<left-falling-thresh>:<right-sliding-thresh>:<right-rising-thresh>:<right-falling-thresh>`.  Example 1: `writeline(udpSock, "p.1", "192.168.88.100", 3036);` goes to bit-parsing.  Example 2: `writeline(udpSock, "p.0:60:50:20:75:30:10", "192.168.88.100", 3036);` sets sliding threshold to 60 microvolts; for left channel we have rising threshold of 0.5 and falling of 0.2 state threshold and right channel sliding threshold is 75 uV, with rising state threshold of 0.3 and falling threshold of 0.1 arbitrary state units. |
| **Squiggles GUI** | `q` | Turns the squiggles ("data stream lines") GUI on or off.  Example `writeline(udpSock, "q.1:A:12,15,24:B:66,67", "192.168.88.100", 3036);` turns the GUI on and sets the squiggles to channels 12, 15, 24 from the `samples` array (so, UNI 11, 14, and 23, in this case) from SAGA A, and  channels 66 and 67 from the `samples` array (so, BIP1 and BIP2 in this case) of B. `"q.0"` turns the GUI off.| 
| **Rate Smoothing Alpha** | `r` | Sets alpha for the EMA on rate estimator.  Example 1: Set this as a multiple of 1000; i.e. to set alpha to 0.75 you would use `writeline(udpSock, "r.750", "192.168.88.100", 3036);`  Example 2: `writeline(udpSock, "r.750,150,005", "192.168.88.100", 3036);` sets an alpha kernel with three values, essentially producing three times the number of features in this case with a "fast", "medium," and "slow" timescale. |  
| **Selected FORCE channel (LSL)** | `s` | Sets the 1-indexed channel and TMSi (A or B) for broadcasting LSL channel (e.g. for use with Prakarsh forces GUI).  Example 1: `writeline(udpSock, "s.B:3", "192.168.88.100", 3036);` selects SAGA-B, channel index 3 (one of the UNI channels).  Example 2: `writeline(udpSock, "s.A:69", "192.168.88.100", 3036);` selects SAGA-A, index 69; if all 4 BIP are enabled and all UNI enabled, this would be an AUX channel e.g. the first accelerometer axis. |
| **JSON** | `t` | I ran out of letters and it does not need to be this type of compressed code anyways. Sends a JSON message, e.g. `writeline(udpSock, 't.{"name":"myparameter","value":{"a":"1","b":2,"c":{"a":3.5,"b":"text"}}}', "127.0.0.1", 3036);` will write the struct with fields 'a' (char == '1'), 'b' (int == 2), and 'c' (struct with fields 'a' (float == 3.5), 'b' (char array == 'text')) which is directly assigned to the field "myparameter" of the `param` struct. |
| **Toggle HPF Squiggles** | `w` | Toggles between HPF squiggles and Envelope squiggles. Can extend to `w.  Example: `writeline(udpSock, "w.0", "192.168.88.100", 3036);` toggle HPF mode on both SAGA. Example 2: `writeline(udpSock, "w.A:1","127.0.0.1",3036);` toggle to BPF mode for SAGA-A but leave SAGA-B in whatever mode it was in (e.g. for setting one in EMG mode and one in EEG mode). | 
| **Spike Detection** | `x` | Factor of 1000 times the number of times the median absolute deviation to use for spike detection. Setting this value to 0 turns off spike detection.  Example 1: `writeline(udpSock, "x.0", "192.168.88.100", 3036);` turns off spike detection.  Example 2: `writeline(udpSock, "x.1500", "192.168.88.100", 3036);` enables spike detection and sets the threshold to 15x the median absolute deviation of the calibration samples on a per-channel basis. | 
| **Triggers Socket Connections** | `y` | Specify as "<1:enable,0:disable>:<1:mouse,0:gamepad>".  Example 1: `writeline(udpSock, "y.1:1", "192.168.88.100", 3036);` Enables the trigger output state parsing, and sets it up to emulate mouse clicks.  Example 2: `writeline(udpSock, "y.1:0", "192.168.88.100", 3036);` Enables the trigger output state parsing, and sets it up to emulate gamepad keypresses. |
| **Save Parameters** | `z` | Specify whether or not to save the parameters struct with recording files.  Example: `writeline(udpSock, "z.1", "192.168.88.100", 3036);` enables saving of `params` parameter struct to each saved matfile. | 
