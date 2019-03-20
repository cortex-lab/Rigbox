function advancedChoiceWorld(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination and baited equal contrast
% trial conditions.  
% 2017-03-25 Added contrast discrimination MW
% 2017-08    Added baited trials (thanks PZH)
% 2017-09-26 Added manual reward key presses
% 2017-10-26 p.wheelGain now in mm/deg units
% 2018-03-15 Added time sampler function for delays

%% parameters
wheel = in.wheelMM; % The wheel input in mm turned tangential to the surface
rewardKey = p.rewardKey.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyPressed = in.keyboard.strcmp(rewardKey); % true each time the reward key is pressed
contrastLeft = p.stimulusContrast(1);
contrastRight = p.stimulusContrast(2);

%% when to present stimuli & allow visual stim to move
% stimulus should come on after the wheel has been held still for the
% duration of the preStimulusDelay.  The quiescence threshold is a tenth of
% the rotary encoder resolution.
preStimulusDelay = p.preStimulusDelay.map(@timeSampler).at(evts.newTrial); % at(evts.newTrial) fix for rig pre-delay 
stimulusOn = sig.quiescenceWatch(preStimulusDelay, t, wheel, 10);
interactiveDelay = p.interactiveDelay.map(@timeSampler);
interactiveOn = stimulusOn.delay(interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

audioDevice = audio.Devices('default');
onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audioDevice.DefaultSampleRate,...
    0.02, audioDevice.NrOutputChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.default = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% wheel position to stimulus displacement
% Here we define the multiplication factor for changing the wheel signal
% into mm/deg visual angle units.  The Lego wheel used has a 31mm radius.
% The standard KÜBLER rotary encoder uses X4 encoding; we record all edges
% (up and down) from both channels for maximum resolution. This means that
% e.g. a KÜBLER 2400 with 100 pulses per revolution will actually generate
% *400* position ticks per full revolution.
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
stimulusDisplacement = p.wheelGain*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

%% define response and response threshold 
responseTimeOver = (t - t.at(interactiveOn)) > p.responseWindow; % p.responseWindow may be set to Inf
threshold = interactiveOn.setTrigger(...
  abs(stimulusDisplacement) >= abs(p.stimulusAzimuth) | responseTimeOver);

response = cond(...
    responseTimeOver, 0,... % if the response time is over the response = 0
    true, -sign(stimulusDisplacement)); % otherwise it should be the inverse of the sign of the stimulusDisplacement

response = response.at(threshold); % only update the response signal when the threshold has been crossed
stimulusOff = threshold.delay(1); % true a second after the threshold is crossed

%% define correct response and feedback
% each trial randomly pick -1 or 1 value for use in baited (guess) trials
rndDraw = map(evts.newTrial, @(x) sign(rand(x)-0.5)); 
correctResponse = cond(contrastLeft > contrastRight, -1,... % contrast left
    contrastLeft < contrastRight, 1,... % contrast right
    (contrastLeft + contrastRight == 0), 0,... % no-go (zero contrast)
    (contrastLeft == contrastRight) & (rndDraw < 0), -1,... % equal contrast (baited)
    (contrastLeft == contrastRight) & (rndDraw > 0), 1); % equal contrast (baited)
feedback = correctResponse == response;
% Only update the feedback signal at the time of the threshold being crossed
feedback = feedback.at(threshold).delay(0.1); 

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(audioDevice.NrOutputChannels, p.noiseBurstDur*audioDevice.DefaultSampleRate, @randn);
audio.default = noiseBurstSamples.at(feedback==0); % When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'

reward = merge(rewardKeyPressed, feedback > 0);% only update when feedback changes to greater than 0, or reward key is pressed
out.reward = p.rewardSize.at(reward); % output this signal to the reward controller

%% stimulus azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% define the visual stimulus

% Test stim left
leftStimulus = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
leftStimulus.orientation = p.stimulusOrientation(1);
leftStimulus.altitude = 0;
leftStimulus.sigma = [9,9]; % in visual degrees
leftStimulus.spatialFreq = p.spatialFrequency; % in cylces per degree
leftStimulus.phase = 2*pi*evts.newTrial.map(@(v)rand);   % phase randomly changes each trial
leftStimulus.contrast = contrastLeft;
leftStimulus.azimuth = -p.stimulusAzimuth + azimuth;
% When show is true, the stimulus is visible
leftStimulus.show = stimulusOn.to(stimulusOff);

vs.leftStimulus = leftStimulus; % store stimulus in visual stimuli set and log as 'leftStimulus'

% Test stim right
rightStimulus = vis.grating(t, 'sinusoid', 'gaussian');
rightStimulus.orientation = p.stimulusOrientation(2);
rightStimulus.altitude = 0;
rightStimulus.sigma = [9,9];
rightStimulus.spatialFreq = p.spatialFrequency;
rightStimulus.phase = 2*pi*evts.newTrial.map(@(v)rand);
rightStimulus.contrast = contrastRight;
rightStimulus.azimuth = p.stimulusAzimuth + azimuth;
rightStimulus.show = stimulusOn.to(stimulusOff); 

vs.rightStimulus = rightStimulus; % store stimulus in visual stimuli set

%% End trial and log events
% Let's use the next set of conditional paramters only if positive feedback
% was given, or if the parameter 'Repeat incorrect' was set to false.
nextCondition = feedback > 0 | p.repeatIncorrect == false; 

% we want to save these signals so we put them in events with appropriate
% names:
evts.stimulusOn = stimulusOn;
evts.preStimulusDelay = preStimulusDelay;
% save the contrasts as a difference between left and right
evts.contrast = p.stimulusContrast.map(@diff); 
evts.contrastLeft = contrastLeft;
evts.contrastRight = contrastRight;
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
evts.interactiveOn = interactiveOn;
% Accumulate reward signals and append microlitre units
evts.totalReward = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl')); 

% Trial ends when evts.endTrial updates.  
% If the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial, if evts.endTrial updates to true, 
% the next set of randowmly picked conditional parameters is used
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay.map(@timeSampler)); 

%% Parameter defaults
% See timeSampler for full details on what values the *Delay paramters can
% take.  Conditional perameters are defined as having ncols > 1, where each
% column is a condition.  All conditional paramters must have the same
% number of columns.
try
%%% Contrast starting set
% C = [1 0;0 1;0.5 0;0 0.5]';
%%% Contrast discrimination set
% c = [1 0.5 0.25 0.12 0.06 0];
% c = combvec(c, c);
% C = unique([c, flipud(c)]', 'rows')';
%%% Contrast detection set
c = [1 0.5 0.25 0.12 0.06 0];
C = [c, zeros(1, numel(c)-1); zeros(1, numel(c)-1), c];
%%%
p.stimulusContrast = C;

p.repeatIncorrect = abs(diff(C,1)) > 0.25; % | all(C==0);
p.onsetToneFrequency = 5000;
p.interactiveDelay = 0.4;
p.onsetToneAmplitude = 0.15;
p.responseWindow = Inf;
p.stimulusAzimuth = 90;
p.noiseBurstAmp = 0.01;
p.noiseBurstDur = 0.5;
p.rewardSize = 3;
p.rewardKey = 'r';
p.stimulusOrientation = [0, 0]';
p.spatialFrequency = 0.19; % Prusky & Douglas, 2004
p.interTrialDelay = 0.5;
p.wheelGain = 5;
p.preStimulusDelay = [0 0.1 0.09]';
catch % ex
%    disp(getReport(ex, 'extended', 'hyperlinks', 'on'))
end

%% Helper functions
function duration = timeSampler(time)
% TIMESAMPLER Sample a time from some distribution
%  If time is a single value, duration is that value.  If time = [min max],
%  then duration is sampled uniformally.  If time = [min, max, time const],
%  then duration is sampled from a exponential distribution, giving a flat
%  hazard rate.  If numel(time) > 3, duration is a randomly sampled value
%  from time.
%
% See also exp.TimeSampler
  if nargin == 0; duration = 0; return; end
  switch length(time)
    case 3 % A time sampled with a flat hazard function
      duration = time(1) + exprnd(time(3));
      duration = iff(duration > time(2), time(2), duration);
    case 2 % A time sampled from a uniform distribution
      duration = time(1) + (time(2) - time(1))*rand;
    case 1 % A fixed time
      duration = time(1);
    otherwise % Pick on of the values
      duration = randsample(time, 1);
  end
end
end