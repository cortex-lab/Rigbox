function advancedChoiceWorld(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination
% 2017-03-25 Added contrast discrimination MW

%% parameters
wheel = in.wheel.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)

nAudChannels = 2;
onsetToneFreq = p.onsetToneFrequency; % e.g. 1200?
p.audDevIdx; % Windows' audio device index (default is 1)
audSampleRate = 44100; % Check PTB Snd('DefaultRate'); previously: 96kHz
contrastLeft = p.stimulusContrast(1);
contrastRight = p.stimulusContrast(2);

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial; % stimulus should come on at the start of a new trial
interactiveOn = stimulusOn.delay(p.interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(onsetToneFreq, 0.1, audSampleRate, 0.02, nAudChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.onsetTone = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% wheel position to stimulus displacement
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
stimulusDisplacement = p.wheelGain*(wheel - wheelOrigin); 

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
feedback = feedback.at(threshold); 

noiseBurstSamples = p.noiseBurstAmp*...
    mapn(nAudChannels, p.noiseBurstDur*audSampleRate, @randn);
audio.noiseBurst = noiseBurstSamples.at(feedback==0); % When the subject gives an incorrect response, send samples to audio device and log as 'noiseBurst'

reward = p.rewardSize.at(feedback > 0); % only update when feedback changes to greater than 0
out.reward = reward; % output this signal to the reward controller

%% stimulus azimuth
azimuth = cond(...
    stimulusOn.to(interactiveOn), 0,... % Before the closed-loop condition, the stimulus is at it's starting azimuth
    interactiveOn.to(threshold), stimulusDisplacement,... % Closed-loop condition, where the azimuth yoked to the wheel
    threshold.to(stimulusOff),  -response*abs(p.stimulusAzimuth)); % Once threshold is reached the stimulus is fixed again

%% define the visual stimulus

% Test stim left
leftStimulus = vis.grating(t, 'sinusoid', 'gaussian'); % create a Gabor grating
leftStimulus.orientation = p.stimulusOrientation;
leftStimulus.altitude = 0;
leftStimulus.sigma = [9,9]; % in visual degrees
leftStimulus.spatialFrequency = p.spatialFrequency; % in cylces per degree
leftStimulus.phase = 2*pi*evts.newTrial.map(@(v)rand);   % phase randomly changes each trial
leftStimulus.contrast = contrastLeft;
leftStimulus.azimuth = -p.stimulusAzimuth + azimuth;
% When show is true, the stimulus is visible
leftStimulus.show = stimulusOn.to(stimulusOff);

vs.leftStimulus = leftStimulus; % store stimulus in visual stimuli set and log as 'leftStimulus'

% Test stim right
rightStimulus = vis.grating(t, 'sinusoid', 'gaussian');
rightStimulus.orientation = p.stimulusOrientation;
rightStimulus.altitude = 0;
rightStimulus.sigma = [9,9];
rightStimulus.spatialFrequency = p.spatialFrequency;
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
% save the contrasts as a difference between left and right
evts.contrast = p.stimulusContrast.map(@diff); 
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
% Accumulate reward signals and append microlitre units
evts.totalReward = reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl')); 

% Trial ends when evts.endTrial updates.  
% If the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial, if evts.endTrial updates to true, 
% the next set of randowmly picked conditional parameters is used
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay); 
end




