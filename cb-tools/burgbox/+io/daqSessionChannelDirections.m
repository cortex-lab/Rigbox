function dirs = daqSessionChannelDirections(session)
channels = session.Channels;
dirs = cell(size(channels));
for i = 1:length(channels)
  c = channels(i);
  if isa(c, 'daq.DigitalChannel')
    dirs{i} = c.Direction;      
  elseif isa(c, 'daq.CounterInputChannel') || isa(c, 'daq.AnalogInputChannel')
    dirs{i} = 'Input';
  else
    dirs{i} = 'Output';
  end
end
end