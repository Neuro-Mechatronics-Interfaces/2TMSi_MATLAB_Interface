function serv = deploy__visualizer_server(TAG, config)
%DEPLOY__VISUALIZER_SERVER  Deploy TCP servers for (online) data visualization
%
% Syntax:
%   serv = deploy__visualizer_server(TAG, config);
%
% Inputs:
%   TAG - ["A"], ["B"], or ["A", "B"] (last option is for both SAGAs)
%   config - (Optional) if not specified, parses config from .yaml file
%               specified in parameters.m
%
% Output:
%   serv - struct with fields corresponding to TAG elements. Each field
%           contains a tcpserver object, which handles the online data
%           visualization messaging and visual update on its corresponding
%           "child" application pane.
%
% See also: Contents, deploy__tmsi_tcp_servers, parameters

if nargin < 1
    error("Must specify TAG as ""A"", ""B"", or [""A"", ""B""]");
end

if nargin < 2
    config = parse_main_config(parameters('config'));
end

serv = struct;
for ii = 1:numel(TAG)
    tag = TAG{ii};
    serv.(tag) = tcpserver(...
            config.Server.Address.TCP, ...
            config.Server.TCP.(tag).Viewer, ...
            "ConnectionChangedFcn", @(src,~)callback.handleConnectionChangedIndicator(src,"app","DataConnectionStatusLamp"), ...
            "Timeout", 0.5);    
    serv.(tag).UserData = struct(...
                'app', SAGA_GUI(tag, config), ...
                'n', config.SAGA.(tag).Channels.n.samples);
    n_samples = config.SAGA.(tag).Channels.n.samples + 1;
    configureCallback(serv.(tag), "byte", 8*(n_samples), ...
        @(src, evt)callback.serverVisualizationCallbackWrapper(src, evt));
end

end