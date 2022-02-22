function rPlot = view_triggers(device)

fig_name = string(strsplit(sprintf('HD-EMG Array %s: Triggers\r', [device.tag]), '\r'));
fig = make_ui_figure(fig_name(1:numel(device)));

rPlot = TMSiSAGA.RealTimePlot(fig, [device.sample_rate], device.getActiveChannels());

% Open a connection to the device
if ~device.is_connected
    device.connect();
else
    if device.is_sampling
        device.stop();
    end
end
start(device);

while rPlot.is_visible
  [samples, num_sets] = device.sample();

  if num_sets > 0
      append(rPlot, samples);
      draw(rPlot);
  end
end
try
    delete(rPlot);
catch
    disp('Real-time plot destroyed.');
end

end