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
State port messages are expected to be new-line terminated byte messages, which should be one of the following: `["idle", "run", "rec", "imp", "quit"]`:  
* `idle`: Stops the SAGA64+ device from acquiring new samples. 
* `run`: Starts the SAGA64+ device acquiring samples and reads them from the device, updating streaming plots if they are enabled. Issues TCP messages via `SpikeServer` but does not save the data. If we were already recording, then this stops the current recording.  
* `rec`: If the SAGA64+ device is not already acquiring samples, this starts sample acquisition, updates streaming plots, and issues all TCP messages, but also dumps the samples into the recording file specified to the `name` port ([next section](#udp-name-port-messages)). 
* `imp`: Stops any ongoing recording. Pulls up electrode impedance plots for each SAGA. Once the figure windows are closed, saves the impedances based on the most-recent filename to a separate `_impedances.mat` file for each SAGA, and then goes back to the normal state machine operation. Does not send any TCP messages etc. while this is ongoing.  
* `quit`: Stop running the state machine loop and shut down the connection to SAGA devices. This should always be called before powering off/disconnecting the SAGA devices, otherwise next time bootup will be a pain in the ass.  

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
| **CAR** | `a` | Specify whether or not to use common average reference (CAR), and optionally the threshold proportion (0-1000, to be divided by 1000 to get proportion between 0 and 1) for excluding artifact spikes in terms of the number of synchronous spike channels on each sample instant.  Example 1: `writeline(udpSock, "a.0", "192.168.88.100", 3036);` stops using CAR.  Example 2: `writeline(udpSock, "a.1", "192.168.88.100", 3036);` uses CAR under the assumption of 1 array (64-channel 8x8 grid).  Example 3: `writeline(udpSock, "a.2", "192.168.88.100", 3036);` uses CAR under the assumption of 2 arrays (32-channel 4x8 textile grids).  Example 4: `writeline(udpSock, "a.2:750", "192.168.88.100", 3036);` uses CAR with 2 textile arrays, and changes the `param.threshold_artifact` value to 0.75 (default is 0.4).|
| **Calibration Samples** | `c` | Sets the calibration state and number of samples in the calibration buffer. Default calibration state is "main" and the default buffer length is 20000 samples (five seconds, with default sample rate of 4kHz).  Example: `writeline(udpSock, "c.noisy:8000", "192.168.88.100, 3036);` changes the calibration buffer to "noisy" and reduces the calibration buffer to 2 seconds. **_Caution:_ There cannot be spaces in the calibration state name.** | 
| **NEO GUI** | `e` | Turns the nonlinear energy operator (NEO) GUI on or off, and set which SAGA/Spike-Channel is examined.  Example `writeline(udpSock, "e.1:B:3", "192.168.88.100", 3036);` turns the GUI on and sets SAGA to B and NEO/Spike channel to 3. `"e.0"` turns the GUI off (does not require additional arguments).| 
| **Save Location** | `f` | Set the save file location using `f.<folder>`.  Example: `writeline(udpSock, "f.C:/Data", "192.168.88.100", 3036);` sets save file root folder to `"C:/Data"`. This gets ignored if you set the full file path explicitly using the `name` port.|
| **GUI Samples** | `g` | Use `g.<# samples>` to specify the number of samples in the GUI line plots.  Example: `writeline(udpSock, "f.C:/Data", "192.168.88.100", 3036);` |
| **HPF Cutoff Frequency** | `h` | Use `h.<fc>` to specify the highpass filter cutoff frequency. Default is 10-Hz. Uses the `config.Default.Sample_Rate` defined in `config_stream_service_plus__default.yaml` to calculate the normalized frequency, then designs the highpass filter as a second-order butterworth filter. | 
| **Label State** | `l` | Set the "label" state and number of samples it should contain. The default label value is "default" and the default label buffer length is 2000 samples (0.5 seconds at 4kHz default rate). If you generate a new label that has not yet been acquired while the state machine script has been running, then this will automatically trigger collection of the labeled data buffer and subsequent estimation (or re-estimation) of being in the labeled state based on spike rate data.  Example: `writeline(udpSock, "l.r_index_flex:1000", "192.168.88.100", 3036);` sets the label to "r_index_flex" and the label buffer to 1000 samples. **_Caution:_ There cannot be spaces in the label state name.** | 
| **Squiggles Line Offsets** | `o` | Sets the spacing between squiggle lines (units are in microvolts).  Example: `writeline(udpSock, "o.100", "192.168.88.100", 3036);` set spacing for 100 uV between squiggles lines.|
| **Spike Channels** | `p` | Sets the number of spike "channels" -- this is the number of rows in the "transform" matrix that gets estimated during the calibration for a given label. Setting this to a new value will re-trigger calibration in the current state, but you would need to re-trigger calibration in any prior states to change the number of channels in their calibrated transforms.  Example: `writeline(udpSock, "p.12", "192.168.88.100", 3036);` changes the number of spike "channels" to 12.| 
| **Squiggles GUI** | `q` | Turns the squiggles ("data stream lines") GUI on or off.  Example `writeline(udpSock, "q.1:A:12,15,24:B:66,67", "192.168.88.100", 3036);` turns the GUI on and sets the squiggles to channels 12, 15, 24 from the `samples` array (so, UNI 11, 14, and 23, in this case) from SAGA A, and  channels 66 and 67 from the `samples` array (so, BIP1 and BIP2 in this case) of B. `"q.0"` turns the GUI off.| 
| **Rate Smoothing Alpha** | `r` | Sets alpha for the EMA on rate estimator. Set this as a multiple of 1000; i.e. to set alpha to 0.75 you would use `writeline(udpSock, "r.750", "192.168.88.100", 3036);` | 
| **Spike Detection** | `x` | Factor of 1000 times the number of times the median absolute deviation to use for spike detection. Setting this value to 0 turns off spike detection.  Example 1: `writeline(udpSock, "x.0", "192.168.88.100", 3036);` turns off spike detection.  Example 2: `writeline(udpSock, "x.1500", "192.168.88.100", 3036);` enables spike detection and sets the threshold to 15x the median absolute deviation of the calibration samples on a per-channel basis. | 
| **Save Parameters** | `z` | Specify whether or not to save the parameters struct with recording files.  Example: `writeline(udpSock, "z.1", "192.168.88.100", 3036);` enables saving of `params` parameter struct to each saved matfile. | 
