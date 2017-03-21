function [samples, t] = pureTone(freq, duration, sampleRate, rampDuration, nAudChannels)
%AUD.PURETONE Generates samples for pure tone sound with ramps
%   TODO
%
% Part of Burgbox

% 2013-05 CB created
% 2017-03 MW added number of audio channels as input

if nargin < 4
  rampDuration = [];
end
if nargin < 5
  nAudChannels = 1;
end


% time points for the sinusoid
nSoundSamples = round(duration*sampleRate);
t = linspace(0, duration, nSoundSamples);

% create sinusoid 
samples = sin(2*pi*freq*t);

if ~isempty(rampDuration)
  % create a ramp up and down modulation
  nRampSamples = round(rampDuration*sampleRate);
  rampUp = sin(0.5*pi*linspace(0, 1, nRampSamples));
  modulation = [rampUp, ones(1, nSoundSamples - 2*nRampSamples), fliplr(rampUp)];

  % modulate sinusoid with ramp up & down
  samples = modulation.*samples;
end

% repeat samples across all channels
samples = repmat(samples, nAudChannels, 1);
end

