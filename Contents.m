%2TMSI_MATLAB_INTERFACE - Contains code used to make the "real-time" online interface for running two (or more) TMSiSAGA devices off a single host machine.
%
% Please, start by looking at README.MD; documentation in comments
% elsewhere *could* be helpful, but may be deprecated and most-likely the
% best place to find the correct documentation is a combination of here
% (Contents.m) and in README.MD. -Max
%
% Data Handler Classes
%   MetaDataHandler                    - Handle metadata.xlsx appending
%   StreamBuffer                       - Implements a buffer for streamed data.
%
% Event Data Classes
%   SAGAEventData                      - Event data class for notifying about SAGA status using small text files and a worker pool monitoring them.
%   SampleEventData                    - Issued when the data frame fills up.
%
% Utility Functions
%   parse_bit_sync                     - Outputs a vector of trigger events that match up with the bit value from sync_bit. Accepts either a struct or vector
%
% Test Scripts and Callbacks
%   example__tcp_ip_comms              - From MATLAB builtin documentation.
%   example__udp_comms                 - Test UDP setup for online interaction with wrist task interface.
%   test__client_readDataFcn           - Calls read to read BytesAvailableFcnCount number of bytes of data.
%   test__connectionFcn                - Indicates that the connection was accepted.
%   test__frame_filled_cb              - Test callback for FrameFilledEvent from StreamBuffer class.
%   test__readDataFcn                  - Calls read to read BytesAvailableFcnCount number of bytes of data.
%
% Batch Script Targets
%   deploy__nhp_tmsi_tcp_servers       - For use with windows batch script executable.
%   deploy__tmsi_saga_controller       - Script that runs GUI application for execution by Windows .bat executable. 
%
% Event Callback Functions
%   bytesAvailableCB_tcpserver__UNI    - Calls read to reshape the unipolar HD-EMG array into server format.
%   evt__frame_filled_cb               - Callback for FrameFilledEvent from StreamBuffer class.
%
% Server-Side Callback Functions
%   server__CON_connection_changed_cb  - For handling connection changes (CONTROLLER server).
%   server__CON_read_data_cb           - Read callback for CONTROLLER server.
%   server__connection_changed_cb      - Indicates that the connection was accepted.
%   server__DATA_connection_changed_cb - For handling connection changes (DATA server).
%   server__DATA_read_data_cb          - Read callback for DATA server.
%   server__DEV_connection_changed_cb  - For handling connection changes (DEVICE server).
%   server__DEV_read_data_cb           - Read callback for DEVICE server.
%   server__read_data_cb               - Calls read to read BytesAvailableFcnCount number of bytes of data.
%
% Client-Side Controller API Functions
%   client__set_rec_name_metadata      - Set recording name metadata using consistent convention.
%   client__set_saga_state             - Set SAGA controller/device state.
%
% Main Data Stream Deployment Script
%   deploy__tmsi_stream_service        - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously AND starts the UDP controller server.
%   deploy__tmsi_tcp_servers           - Create and run the TCP data (online visualization) server.

