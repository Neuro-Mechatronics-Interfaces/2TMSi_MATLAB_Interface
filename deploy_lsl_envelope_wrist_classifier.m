function deploy_lsl_envelope_wrist_classifier(mdl,classes,options)
%DEPLOY_LSL_ENVELOPE_WRIST_CLASSIFIER  Deploy classifier for wrist 2DOF LSL architecture.
%
% Example:
% data_in = io.load_tmsi("Max", 2024, 5, 29, "*", 1, "lsl", "C:/Data/LSL/Gestures");
% [mdl,classes,XTest,YTest,targets,env_data] = train_LSL_envelope_classifier(data_in);
arguments
    mdl
    classes
    options.LSLFolder = 'C:\MyRepos\Libraries\liblsl-Matlab';
end

% instantiate the library
addpath(genpath(options.LSLFolder));
lib = lsl_loadlib();
config = load_spike_server_config();


inlet = {};
info = {};
% env_info = {};
% env_inlet = {};
% env_outlet = {};
if config.SAGA.A.Enable % Make sure we grab the correct channels so orientation of rows in data array is as-expected by classifier!
    % a_outlet_info = lsl_streaminfo(lib, ...
    %     sprintf('%s_ENV',config.SAGA.A.Unit),...
    %     'EMG', ...
    %     64, ...
    %     4000, ...
    %     'cf_float32', ...
    %     sprintf('%s_ENV',config.SAGA.A.Unit));
    % chns = a_outlet_info.desc().append_child('channels');
    % for iCh = 1:64
    %     c = chns.append_child('channel');
    %     c.append_child_value('name', sprintf('UNI %02d', iCh));
    %     c.append_child_value('label', sprintf('UNI %02d', iCh));
    % end
    % env_outlet{end+1} = lsl_outlet(a_outlet_info);
    % pause(0.050);

    result = {};
    while isempty(result)
        result = lsl_resolve_byprop(lib,'name',char(config.SAGA.A.Unit)); 
    end
    info{end+1} = result{1};
    inlet{end+1} = lsl_inlet(info{end});

    % result = {};
    % while isempty(result)
    %     result = lsl_resolve_byprop(lib,'name',sprintf('%s_ENV',config.SAGA.A.Unit)); 
    % end
    % env_info{end+1} = result{1};
    % env_inlet{end+1} = lsl_inlet(env_info{end});
end

if config.SAGA.B.Enable
    % b_outlet_info = lsl_streaminfo(lib, ...
    %     sprintf('%s_ENV',config.SAGA.B.Unit),...
    %     'EMG', ...
    %     64, ...
    %     4000, ...
    %     'cf_float32', ...
    %     sprintf('%s_ENV',config.SAGA.B.Unit));
    % chns = b_outlet_info.desc().append_child('channels');
    % for iCh = 1:64
    %     c = chns.append_child('channel');
    %     c.append_child_value('name', sprintf('UNI %02d', iCh));
    %     c.append_child_value('label', sprintf('UNI %02d', iCh));
    % end
    % env_outlet{end+1} = lsl_outlet(b_outlet_info);
    % pause(0.050);

    result = {};
    while isempty(result)
        result = lsl_resolve_byprop(lib,'name',char(config.SAGA.B.Unit)); 
    end
    info{end+1} = result{1};
    inlet{end+1} = lsl_inlet(info{end});

    % result = {};
    % while isempty(result)
    %     result = lsl_resolve_byprop(lib,'name',sprintf('%s_ENV',config.SAGA.B.Unit)); 
    % end
    % env_info{end+1} = result{1};
    % env_inlet{end+1} = lsl_inlet(env_info{end});
end
outlet_info = lsl_streaminfo(lib, ...
    'ControllerVelocity', ...       % Name
    'CONTROL', ...           % Type
    2, ....   % ChannelCount
    30, ...                       % NominalSrate
    'cf_float32', ...             % ChannelFormat
    sprintf('ControllerVelocity%06d',randi(999999,1,1)));      % Unique ID
chns = outlet_info.desc().append_child('channels');
ch = {'x','y'};
for iCh = 1:numel(ch)
    c = chns.append_child('channel');
    c.append_child_value('name', ch{iCh});
    c.append_child_value('label', ch{iCh});
    c.append_child_value('type','Velocity');
end
outlet = lsl_outlet(outlet_info);

% Create a GUI that lets you break the loop if needed:
fig = figure('Color','k',...
    'Name','LSL Wrist 2DOF Classifier Placeholder',...
    'Units', 'inches', ...
    'MenuBar','none',...
    'ToolBar','none',...
    'Position',[3.5, 5, 8, 0.75]);
ax = axes(fig,'NextPlot','add','XColor','none','YColor','none','YLim',[-0.5,0.5],'XLim',[-0.5,0.5],'Color','none');
text(ax,0,0,"CLOSE TO EXIT LSL WRIST 2D CLASSIFIER",'FontWeight','bold','FontSize',24,'FontName','Tahoma','Color','w','HorizontalAlignment','center','VerticalAlignment','middle');


iUp = find(strcmpi(classes,'Wrist Extension'));
iDown = find(strcmpi(classes,'Wrist Flexion'));
iLeft = find(strcmpi(classes, 'Radial Deviation'));
iRight = find(strcmpi(classes, 'Ulnar Deviation'));
iRest = find(strcmpi(classes, 'REST'));

z_env = zeros(3,64,2);
z_hpf = zeros(3,64,2);
[b_hpf,a_hpf] = butter(3,100/2000,'high');
[b_env,a_env] = butter(3,5/2000,'low');
data = zeros(1,128);
while isvalid(fig)
    % get chunk from the inlet
    for ii = 1:numel(inlet)
        sample = inlet{ii}.pull_chunk();
        if isempty(sample)
            continue;
        end
        [hpf_uni,z_hpf(:,:,ii)] = filter(b_hpf,a_hpf,sample(1:64,:)',z_hpf(:,:,ii),1);
        [env_uni,z_env(:,:,ii)] = filter(b_env,a_env,abs(hpf_uni),z_env(:,:,ii),1);
        
        % data(vec) = env_uni(end,:)';
        % env_outlet{ii}.push_chunk(env_uni');
        vec = (1:64) + (64*(ii-1));
        data(vec) = mean(env_uni,1);
    end
    res = predict(mdl, data);
    switch res
        case iRest
            out = [0; 0];
        case iUp
            out = [0; 1];
        case iDown
            out = [0; -1];
        case iLeft
            out = [-1; 0];
        case iRight
            out = [1; 0];
    end
    outlet.push_sample(out);
    pause(0.03);
end

end