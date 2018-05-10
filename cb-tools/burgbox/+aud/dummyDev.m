function dev = dummyDev(~)
% Returns a dummy audio device structure, regardless of input
%   Returns a standard structure with values for generating tone
%   samples.  This function gets around the problem of querying the
%   rig's audio devices when inferring parameters.
dev = struct('DeviceIndex', -1,...
  'DefaultSampleRate', 44100,...
  'NrOutputChannels', 2);
end
