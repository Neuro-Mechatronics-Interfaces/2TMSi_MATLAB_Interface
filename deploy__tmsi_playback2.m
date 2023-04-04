function deploy__tmsi_playback2(SUBJ,YYYY,MM,DD,BLOCK)
%DEPLOY__TMSI_PLAYBACK2 - Script that enables sampling from multiple devices, and streams data from those devices to a server continuously.
%
% Starts up the TMSi stream(s) to playback a specified block on a loop.
%   -> Takes a hopefully more-efficient approach than the original.
% See details in README.MD

config_file = parameters('config');
fprintf(1, "[Deploy]::[Playback] Loading configuration file (%s, in main repo folder)...\n", config_file);
[config, ~, ~, N_CLIENT] = parse_main_config(config_file);

%% Open "device connections"
f = utils.get_block_name(SUBJ, YYYY, MM, DD, "A", BLOCK, config.Default.Folder);
aname = string(strcat(f.Raw.Block, ".mat"));
f = utils.get_block_name(SUBJ, YYYY, MM, DD, "B", BLOCK, config.Default.Folder);
bname = string(strcat(f.Raw.Block, ".mat"));
device = TMSiSAGA.Playback([aname; bname]);
% connect(device);

%% Create TMSi stream client + udpport
ordered_tags = strings(size(device));
ch = struct();
for ii = 1:numel(ordered_tags)
    ordered_tags(ii) = string(device(ii).tag);
    ch.(ordered_tags(ii)) = device(ii).getActiveChannels();
end
node = TMSi_Node(ordered_tags, ch, config, 'device', "virtual");
node.set_name(SUBJ, YYYY, MM, DD, BLOCK);
fprintf(1, "\n[Deploy]::[Playback] [%s] LOOP BEGIN\n\n",string(datetime('now')));

%%
try
    while node.state ~= enum.TMSiState.QUIT      
        switch node.state
            case enum.TMSiState.IDLE
                switch node.transition
                    case enum.TMSiTransition.FROM_IMPEDANCE
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RUNNING
                        stop(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RECORDING
                        node.clear_transition();
                    otherwise % Otherwise do nothing.
                        if node.needs_reload
                            fprintf(1, "[Deploy]::[Playback] Loading %s...", node.fname);
                            for ii = 1:N_CLIENT
                                device(ii).load_new(strcat(sprintf(node.fname, device(ii).tag), ".mat"));
                            end
                            fprintf(1,'complete\n');
                            node.needs_reload = false;
                        end
                end
    
            case enum.TMSiState.RUNNING
                switch node.transition
                    case {enum.TMSiTransition.FROM_IDLE, enum.TMSiTransition.FROM_IMPEDANCE, enum.TMSiTransition.FROM_RECORDING}
                        start(device);
                        node.clear_transition();
                    otherwise % Append to the sample buffer
                        for ii = 1:N_CLIENT
                            samples = device(ii).sample();
                            node.append(device(ii).tag, samples);
                        end
                end
    
            case enum.TMSiState.RECORDING
                switch node.transition
                    case enum.TMSiTransition.NONE % Does nothing.
                    otherwise
                        fprintf(1,'[PLAYBACK]\tNot possible to enter RECORDING mode for PLAYBACK.\n');
                        node.clear_transition();
                end
            case enum.TMSiState.IMPEDANCE
                switch node.transition
                    case enum.TMSiTransition.NONE % Does nothing.
                    otherwise
                        fprintf(1,'[PLAYBACK]\tNot possible to enter IMPEDANCE mode for PLAYBACK.\n');
                        node.clear_transition();
                end
            case enum.TMSiState.QUIT
                switch node.transition
                    case enum.TMSiTransition.FROM_IDLE
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RUNNING
                        stop(device);
                        node.clear_transition();
                    case enum.TMSiTransition.FROM_RECORDING
                        node.clear_transition();
                    otherwise % Execute the actual shutdown process
                        disconnect(device);
                        delete(device);
                        delete(node);
                        break;
                end
        end
        pause(0.005); % Allows configured callbacks to execute.
    end
catch me
    fprintf(1,'[PLAYBACK]\tSomething went wrong...\n');
    assignin("base", "node", node);
    assignin("base", "device", device);
    throwAsCaller(me);
end

end
