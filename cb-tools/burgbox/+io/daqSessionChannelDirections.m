function dirs = daqSessionChannelDirections(session)
% Returns a cell array of directions for all channels in a given session
%   IO.DAQSESSIONCHANNELDIRECTIONS(session) finds all the channels
%   assosiated with a given session and returns the direction of each one
%   in a cell array
%
%   See HW.DAQROTARYENCODER and HW.TIMELINE for usage examples
%
% Part of Rigbox
% CB created

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