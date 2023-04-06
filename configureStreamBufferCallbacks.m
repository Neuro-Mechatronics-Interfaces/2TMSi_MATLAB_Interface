function buffer_event_listener = configureStreamBufferCallbacks(node, packet_tag, buffer, buffer_event_listener)
%CONFIGURESTREAMBUFFERCALLBACKS  Set up the stream handler callbacks

if numel(packet_tag) > 1
    for ii = 1:numel(packet_tag)
        buffer_event_listener.(packet_tag(ii)) = configureStreamBufferCallbacks(node, packet_tag(ii), buffer.(packet_tag(ii)), buffer_event_listener.(packet_tag(ii)));
    end
    return;
end

if node.flags.new_mode.(packet_tag)
    fprintf(1, "[TMSi]\t->\tDetected (%s) switch in packet mode from '%s' to --> '%s' <--\n", packet_tag, packet_mode.(packet_tag), tmp);
    reset_buffer(buffer.(packet_tag));
    delete(buffer_event_listener);
    switch node.packet_mode
        case 'US'
            apply_car = str2double(info{3});
            i_subset = (double(info{4}) - 96)';
            fprintf(1, '[TMSi]\tEnabled CH-%02d (UNI)\n', i_subset);
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__US(src, evt, visualizer, i_subset, apply_car));
            fprintf(1, "[TMSi]\t->\tConfigured %s for unipolar stream data.\n", packet_tag);
        case 'BS'
            i_subset = (double(info{3}) - 96)';
            fprintf(1, '[TMSi]\tEnabled CH-%02d (BIP)\n', i_subset);
            for ii = 1:N_CLIENT
                buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BS(src, evt, visualizer, i_subset));
            end
            fprintf(1, "[TMSi]\t->\tConfigured %s for bipolar stream data.\n", packet_tag);
        case 'UA'
            apply_car = str2double(info{3});
            %                             i_subset = str2double(info{4});
            i_subset = (double(info{4}) - 96)';
            i_trig = node.trig.(packet_tag);
            fprintf(1, '[TMSi]\tSending triggered-averages for %s:CH-%02d (UNI)\n', packet_tag, i_subset);
            %                             buffer_event_listener.(info{2}) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UA(src, evt, visualizer.(packet_tag), i_subset, apply_car, i_trig));
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer, i_subset, apply_car, i_trig));
            fprintf(1, "[TMSi]\t->\tConfigured %s for unipolar averaging data.\n", packet_tag);
        case 'BA'
            %                             i_subset = str2double(info{3});
            apply_car = str2double(info{3});
            i_subset = (double(info{4}) - 96)';
            i_trig = config.SAGA.(packet_tag).Trigger.Channel;
            fprintf(1, '[TMSi]\tSending triggered-averages for %s:CH-%02d (BIP)\n', packet_tag, i_subset);
            %                             buffer_event_listener.(packet_tag) = addlistener(buffer.(packet_tag), "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__BA(src, evt, visualizer.(packet_tag), i_subset, i_trig));
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__SendAll(src, evt, visualizer, i_subset, apply_car, i_trig));
            fprintf(1, "[TMSi]\tConfigured %s for bipolar averaging data.\n", packet_tag);
        case 'UR'
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__UR(src, evt, visualizer));
            fprintf(1, "[TMSi]\t->\tConfigured %s for unipolar raster data.\n", packet_tag);
        case 'IR'
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IR(src, evt, visualizer));
            fprintf(1, "[TMSi]\t->\tConfigured %s for ICA raster data.\n", packet_tag);
        case 'IS'
            i_subset = (double(info{3}) - 96)';
            fprintf(1, '[TMSi]\tSending triggered-averages for %s:ICA-%02d\n', packet_tag, i_subset(1));
            buffer_event_listener  = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__IS(src, evt, visualizer, i_subset));
            fprintf(1, "[TMSi]\t->\tConfigured %s for bipolar averaging data.\n", packet_tag);
        case 'RC'
            buffer_event_listener = addlistener(buffer, "FrameFilledEvent", @(src, evt)callback.handleStreamBufferFilledEvent__RC(src, evt, visualizer));
            fprintf(1, "[TMSi]\t->\tConfigured %s for RMS contour data.\n", packet_tag);
        otherwise
            fprintf(1, "[TMSi]\t->\tUnrecognized requested packet mode: %s", string(node.packet_mode));
    end
    node.flags.new_mode.(packet_tag) = false;
end

end