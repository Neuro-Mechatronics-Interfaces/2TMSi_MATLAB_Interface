function [config, TAG, SN, N_CLIENT, SAGA] = parse_main_config(cfg, saga)
%PARSE_MAIN_CONFIG  Parses config struct from config.yaml
%
% Syntax:
%   [config, TAG, SN, N_CLIENT, SAGA] = parse_main_config(cfg);
%   [...] = parse_main_config(cfg, saga);
%
% Inputs:
%   cfg - The configuration struct loaded from
%               config = io.yaml.loadFile('config.yaml')
%               (or, its filename e.g. 'project/config.yaml')
%           -> Default will use 'config.yaml' if not specified.
%
%   saga   - The SAGA metadata struct loaded from 
%               SAGA = io.JSON('SAGA.json');
%               (or, its filename e.g. 'project/SAGA.json')
%           -> Default will use 'SAGA.json' if not specified.
%
% Output:
%   config - The parsed configuration struct.
%   TAG - The array of device tags to use in this session
%   SN  - Elements match 1:1 with elements of TAG, indicating the serial
%           number of the data recorder (top part of the sandwich) for any
%           SAGA device in use.
%   N_CLIENT - Number of SAGA "clients" in this session.
%
% See also: Contents, deploy__tmsi_stream_service, deploy__tmsi_tcp_servers

if nargin < 1
    cfg = parameters('config'); 
end

if nargin < 2
    saga = 'SAGA.json'; 
end

if ischar(saga) || isstring(saga)
    SAGA = io.JSON(saga); 
else
    SAGA = saga;
end

if ischar(cfg) || isstring(cfg)
    config = io.yaml.loadFile(cfg);
else
    config = cfg;
end

config.SAGA.A.SN = struct('DR', SAGA.DR.(config.SAGA.A.Unit), 'DS', SAGA.DS.(config.SAGA.A.Unit));
if config.SAGA.A.Enable
    TAG = "A";
    SN = config.SAGA.A.SN.DR;
    fprintf(1, "Using %s (SN:%12d) as Device-Tag 'A'\n", config.SAGA.A.Unit, SN);
else
    TAG = [];
    SN = [];
    fprintf(1, "Device-Tag 'A' Unit is not enabled and will not be used for recordings.\n"); 
end

config.SAGA.B.SN = struct('DR', SAGA.DR.(config.SAGA.B.Unit), 'DS', SAGA.DS.(config.SAGA.B.Unit));
if config.SAGA.B.Enable
    TAG = [TAG, "B"];
    sn =  config.SAGA.B.SN.DR;
    SN = [SN, sn];
    fprintf(1, "Using %s (SN:%12d) as Device-Tag 'B'\n", config.SAGA.B.Unit, SN(end));
else
    fprintf(1, "Device-Tag 'B' Unit is not enabled and will not be used for recordings.\n"); 
end

N_CLIENT = numel(TAG);
if N_CLIENT < 1
    error("No SAGA devices are enabled in config.yaml. Must enable at least 1 unit to continue.");
end

ch_type_opts = ["CREF", "UNI", "BIP", "AUX", "STAT", "COUNT"];
for ii = 1:N_CLIENT
    tag = TAG(ii);
    for ik = 1:numel(ch_type_opts)
        if isfield(config.SAGA.(tag).Channels, ch_type_opts(ik))
            chs = ch_type_opts(ik);
            if iscell(config.SAGA.(tag).Channels.(chs))
                config.SAGA.(tag).Channels.(chs) = cell2mat(config.SAGA.(tag).Channels.(chs));
            end
        end
    end
end

if isfield(config, 'GUI')
    for ii = 1:N_CLIENT
        tag = TAG(ii);
        if iscell(config.GUI.Squiggles.(tag))
            config.GUI.Squiggles.(tag) = cell2mat(config.GUI.Squiggles.(tag));
        end
    end
end

end