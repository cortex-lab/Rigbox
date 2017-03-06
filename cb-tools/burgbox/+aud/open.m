function handle = open(dev, nchannels, rate, latencyClass, mode)
%AUD.OPEN Summary of this function goes here
%   Detailed explanation goes here
%
% Part of Burgbox

% 2014-02 CB created

if nargin < 2 || isempty(nchannels)
  nchannels = 1; % default to 1 channel/mono
end
if nargin < 3 || isempty(rate)
  rate = 96e3; %default to 96kHz
end
if nargin < 4 || isempty(latencyClass)
  latencyClass = 1; %Psychtoolbox will try to get low latency but reliable
end
if nargin < 5 || isempty(mode)
  mode = 1; %default to playback-only mode
end
handle = PsychPortAudio('Open', dev, mode, latencyClass, rate, nchannels);

end

