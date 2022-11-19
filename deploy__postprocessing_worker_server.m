function [server, FILTER] = deploy__postprocessing_worker_server(cfg, FILTER)
%DEPLOY__POSTPROCESSING_WORKER_SERVER - Run TCP server to handle post-processing requests.
%
% Syntax:
%   [server,FILTER] = deploy__postprocessing_worker_server(config);
%   server = deploy__postprocessing_worker_server(config, FILTER);
%
% Inputs:
%   config - Array struct, where each element has the fields:
%           'delimiter' - (usually, '.' -- depends on how data is passed to "worker" server)
%           'tag' - "A" or "B"
%           'address' - The IP of the computer to run on ("127.0.0.1" for localhost)
%           'port' - usually 4000 (A) or 4001 (B)
%           'sync_bit' - Usually this is 9 or 10
%           'type' - Can be ".poly5" or ".mat"
%           'fcn' - The callback function handle
%           'terminator' - Typically "LF" but can be "CR" or "CR/LF"
%               ("LF" - line feed: \n | "CR" - carriage return: \r)
%   FILTER - (optional) -- if not specified, uses defaults that can be seen
%                   by the optional second returned output argument.
%                   -> Should have filters from 
%                       utils.get_default_filtering_pars, for the 
%                       the following fields:
%                       - 'raw_array'
%                       - 'diff2_array'
%                       - 'rms'
%                       - 'bipolar'
%
% Output:
%   server - The worker tcpserver objects. These can live in the base
%           `deploy__tmsi_tcp_servers.m` script or they could be deployed 
%           on a separate network machine as long as the address 
%           configuration is correct. 
%
% See also: Contents, deploy__tmsi_tcp_servers, callback.exportFigures

if nargin < 2
    FILTER = struct;
    FILTER.raw_array = utils.get_default_filtering_pars("TMSi","Array","Raw");
    FILTER.diff2_array = utils.get_default_filtering_pars("TMSi", "Array", "Differential2");
    FILTER.rms = utils.get_default_filtering_pars("TMSi", "Array", "Differential2");
    FILTER.bipolar = utils.get_default_filtering_pars("TMSi", "Bipolar", "Rectified");
end


if ~isfield(cfg, 'delimiter')
    cfg.delimiter = ".";
end
if ~isfield(cfg, 'terminator')
    cfg.terminator = "LF";
end
if ~isfield(cfg, 'fcn')
    cfg.fcn = @callback.exportFigures;
end
server = tcpserver(cfg.address, cfg.port);
server.UserData = struct( ...
    'filter', FILTER, ...
    'delimiter', cfg.delimiter, ...
    'tag', cfg.tag, ...
    'type', cfg.type, ...
    'sync_bit', cfg.sync_bit);
configureTerminator(server, cfg.terminator);
configureCallback(server, 'terminator', cfg.fcn);

end