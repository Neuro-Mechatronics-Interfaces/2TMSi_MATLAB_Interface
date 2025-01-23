function all_ch = active_channels_2_sync_channels(ch, options)
%ACTIVE_CHANNELS_2_SYNC_CHANNELS Sets up channels for poly5 file formatting so that channels from two devices can have samples logged in same file, along with any other required binary streams we want to log synchronously.
% 
%   all_ch = ACTIVE_CHANNELS_2_SYNC_CHANNELS(ch, options) processes a list
%   of active channels and returns a structured array of synchronization
%   channels based on specified options. 
%
%   Input:
%       ch - Input list of channels.
%
%       options - Optional name-value pair arguments to configure the
%       channels to include:
%           'CursorChannels'           - (logical) If true, includes cursor-related channels.
%                                        Default: true.
%           'JoystickChannels'         - (logical) If true, includes joystick-related channels.
%                                        Default: true.
%           'CenterOutChannels'        - (logical) If true, includes center-out task-related channels.
%                                        Default: true.
%           'JoystickPredictionChannels' - (logical) If true, includes joystick prediction channels.
%                                        Default: true.
%           'TeensyChannel'            - (logical) If true, includes Teensy device channel.
%                                        Default: true.
%           'TeensySerialNumber'       - (numeric) Serial number for Teensy device channel. 
%                                        Default: -1.
%           'ViGEmChannel'             - (logical) If true, includes emulated gamepad (ViGEm) channel.
%                                        Default: true.
%           'LoopTimestampChannel'     - (logical) If true, includes loop timestamp channel.
%                                        Default: true.
%
%   Output:
%       all_ch - A structured array containing the synchronized channels,
%                formatted for compatibility with downstream processing.
%
%   Example:
%       ch = device.getActiveChannels(); % Return active TMSiSAGA device channels.
%       all_ch = active_channels_2_sync_channels(ch); 
%
%   See also: ADD_CHANNEL_STRUCT

arguments
    ch
    options.AssertionChannel (1,1) logical = false; % 
    options.CursorChannels (1,1) logical = true; % Shorthand, if set false, JoystickChannels, JoystickPredictionChannels, and CenterOutChannels are all overriden to false.
    options.JoystickChannels (1,1) logical = false;
    options.CenterOutChannels (1,1) logical = false;
    options.JoystickPredictionChannels (1,1) logical = false;
    options.MegaChannel (1,1) logical = false; % Indicates commands sent to MEGA2560
    options.MegaSerialNumber (1,1) {mustBeNumeric} = -1;
    options.TeensyChannel (1,1) logical = true; % Indicates commands sent to Teensy
    options.TeensySerialNumber (1,1) {mustBeNumeric} = -1;
    options.ContactileChannels (1,1) logical = false;
    options.NumContactileSensors (1,1) {mustBeInteger, mustBeInRange(options.NumContactileSensors, 1, 10)} = 6;
    options.GamepadButtonChannel (1,1) logical = false;  % Indicates emulated gamepad kernel commands
    options.StateChannel (1,1) logical = false; % e.g. for adding in game state/task state etc
    options.LoopTimestampChannel (1,1) logical = true; % Indicates timestamp of current sample loop batch
end

all_ch = channels_cell_2_sync_channels(ch);

if options.JoystickChannels && options.CursorChannels
    all_ch = add_channel_struct(all_ch, 'JoyPx', '-', "J", -1); %#ok<*UNRCH>
    all_ch = add_channel_struct(all_ch, 'JoyPy', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'JoyVx', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'JoyVy', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'JoyAx', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'JoyAy', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'JoyBtn','-', "J", -1);
end

if options.CenterOutChannels && options.CursorChannels
    all_ch = add_channel_struct(all_ch, 'Target','-', "G", -1);
    all_ch = add_channel_struct(all_ch, 'Score', '-', "G", -1);
    all_ch = add_channel_struct(all_ch, 'Trial', '-', "G", -1);
end

if options.JoystickPredictionChannels && options.CursorChannels
    all_ch = add_channel_struct(all_ch, 'PredPx', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'PredPy', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'PredVx', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'PredVy', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'PredAx', '-', "J", -1);
    all_ch = add_channel_struct(all_ch, 'PredAy', '-', "J", -1);
end

if options.MegaChannel % "U" for mu for microcontroller
    all_ch = add_channel_struct(all_ch, 'MEGA', '-', "U", options.MegaSerialNumber);
end

if options.TeensyChannel % "U" for mu for microcontroller
    all_ch = add_channel_struct(all_ch, 'Teensy', '-', "U", options.TeensySerialNumber);
end

if options.GamepadButtonChannel
    all_ch = add_channel_struct(all_ch, 'ViGEm', '-', "V", -1);
end

if options.AssertionChannel
    all_ch = add_channel_struct(all_ch, 'Assertion', '-', "D", -1);
end

if options.StateChannel
    all_ch = add_channel_struct(all_ch, 'State', '-', "S", -1);
end

if options.ContactileChannels
    for ii = 1:options.NumContactileSensors
        all_ch = add_channel_struct(all_ch, sprintf('BTN-%02d-X', ii), 'N', "C", -1);
        all_ch = add_channel_struct(all_ch, sprintf('BTN-%02d-Y', ii), 'N', "C", -1);
        all_ch = add_channel_struct(all_ch, sprintf('BTN-%02d-Z', ii), 'N', "C", -1);
    end
end

if options.LoopTimestampChannel
    all_ch = add_channel_struct(all_ch, 'BatchTS', 'sec', "T", -1);
end

end