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

### UDP Name Port Messages ###
The acquisition script sets up the name port with a udp socket as follows:  
```
udp_name_receiver = udpport("byte", ...
    "LocalHost", config.UDP.Socket.StreamService.Address, ...
    "LocalPort", config.UDP.Socket.StreamService.Port.name, "EnablePortSharing", true);
```  

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
So it is essentially a key-value message with the leading single-character byte code indicating which parameter as follows:  
| Parameter | Code | Description                                              |
| :-------: | :--: | :------------------------------------------------------- |
| **Buffer Samples** | `n` or `t` | Use `n.<# samples>` to specify precisely, or `t.<# seconds>` to use the next power of 2 greater than or equal to the desired buffer recording buffer duration (uses sample rate default of 4000 in calculation). Example: `writeline(udpSock, "192.168.88.100", 3036, "t.600");` would create a buffer at least 10 minutes long. `writeline(udpSock, "192.168.88.100", 3036, "n.2400000");` would create a buffer exactly 2400000 samples long (so, exactly 10 minutes long). The difference between the two is that `t.600` allocates in chunks based on whatever `2^x` value is smallest but meets the minimum required samples.| 
| **Save Location** | `f` | Set the save file location using `f.<folder>`. Example: `writeline(udpSock, "192.168.88.100", 3036, "f.C:/Data");` |
| **Label State** | `s` | Set the "label" state. The default value is "default." If you generate a new label that has not yet been acquired while the state machine script has been running, then this will automatically trigger collection of the calibration buffer and subsequent estimation of the spike filter transformation and thresholding arrays. These are then retained as sub-fields of the `param` struct in the script, such that they will be re-used if **Label State** is re-assigned to a previous value (i.e. if you use `writeline(udpSock, "192.168.88.100", 3036, "s.A"); writeline(udpSock, "s.default", "192.168.88.100", 3036);`, you will revert to the transform and thresholding acquired during "default" label unless you manually re-trigger the calibration. | 
| **Calibrate** | `c` | Sets the length of the calibration sample buffer and re-calibrates. Default is 4000 samples (one second, with default sample rate). Example: `writeline(udpSock, "c.8000", "192.168.88.100, 3036);` extends the calibration buffer to 2 seconds and re-calibrates. | 
| **Spike Channels** | `p` | Sets the number of spike "channels" -- this is the number of rows in the "transform" matrix that gets estimated during the calibration for a given label. Setting this to a new value will re-trigger calibration in the current state, but you would need to re-trigger calibration in any prior states to change the number of channels in their calibrated transforms. Example: `writeline(udpSock, "p.12", "192.168.88.100", 3036);` changes the number of spike "channels" to 12.| 
| **Squiggles GUI** | `q` | Turns the squiggles ("data stream lines") GUI on or off. Example `writeline(udpSock, "q.1:A:12,15,24:B:66,67", "192.168.88.100", 3036);` turns the GUI on and sets the squiggles to channels 12, 15, 24 from the `samples` array (so, UNI 11, 14, and 23, in this case) from SAGA A, and  channels 66 and 67 from the `samples` array (so, BIP1 and BIP2 in this case) of B. `"q.0"` turns the GUI off.| 
| **Squiggles Line Offsets** | `o` | Sets the spacing between squiggle lines (units are in microvolts). Example: `writeline(udpSock, "o.100", "192.168.88.100", 3036);` set spacing for 100 uV between squiggles lines.|
| **NEO GUI** | `e` | Turns the nonlinear energy operator (NEO) GUI on or off, and set which SAGA/Spike-Channel is examined. Example `writeline(udpSock, "e.1:B:3", "192.168.88.100", 3036);` turns the GUI on and sets SAGA to B and NEO/Spike channel to 3. `"e.0"` turns the GUI off (does not require additional arguments).| 
| **GUI Samples** | `l` | Use `l.<# samples>` to specify the number of samples in the GUI line plots. |
| **HPF Cutoff Frequency** | `h` | Use `h.<fc>` to specify the highpass filter cutoff frequency. Default is 10-Hz. Uses the `config.Default.Sample_Rate` defined in `config_stream_service_plus__default.yaml` to calculate the normalized frequency, then designs the highpass filter as a second-order butterworth filter. | 
| **Threshold Deviations** | `d` | Set the number of median absolute deviations for computing threshold from the mixed-NEO signals. Example: `writeline(udpSock, "d.15", "192.168.88.100", 3036);` would set the median absolute deviations for NEO threshold on a per-mixed-channel basis to 15. |