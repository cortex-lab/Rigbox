function [samples, t] = pureTone(freq, duration, sampleRate, rampDuration, nAudChannels)
%AUD.PURETONE Generates samples for pure tone sound with ramps
%  Returns samples for a pure sine wave tone with an optional ramp at the
%  start and end.
%
%  Inputs:
%    freq - Tone frequency in Hz
%    duration - The duration of the tone in seconds
%    sampleRate - The tone sample rate in Hz
%    rampDuration - The duration of the ramp in seconds at the start and
%      end of the tone.  Default is empty, meaning no ramp.
%    nAudChannels - The number of audio channels.  The returned samples
%      have this many rows.  Default 1.
%
%  Outputs:
%    samples: The tone samples of size [MxN] where M = nAudChannels; N =
%      duration * sampleRate
%    t: A vector of time samples the length of duration * sampleRate
%
%  Example:
%    % Generate samples for a 1 second long 11kHz sine wave at a sampling
%    % rate of 44.1kHz with a ramp of 20ms over two audio channels
%    samples = aud.pureTune(11000, 1, 44100, 0.02, 2);
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

