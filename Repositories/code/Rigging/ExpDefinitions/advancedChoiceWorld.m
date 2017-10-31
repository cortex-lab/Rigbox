function advancedChoiceWorld(t, evts, p, vs, in, out, audio)
%% advancedChoiceWorld
% Burgess 2AUFC task with contrast discrimination and baited equal contrast
% trial conditions.  
% 2017-03-25 Added contrast discrimination MW
% 2017-08    Added baited trials (thanks PZH)
% 2017-09-26 Added manual reward key presses
% 2017-10-26 p.wheelGain now in mm/deg units

%% parameters
wheel = in.wheel.skipRepeats(); % skipRepeats means that this signal doesn't update if the new value is the same of the previous one (i.e. if the wheel doesn't move)
rewardKey = p.rewardKey.at(evts.expStart); % get value of rewardKey at experiemnt start, otherwise it will take the same value each new trial
rewardKeyPressed = in.keyboard.strcmp(rewardKey); % true each time the reward key is pressed
nAudChannels = 2;
% p.audDevIdx; % Windows' audio device index (default is 1)
audSampleRate = 44100; % Check PTB Snd('DefaultRate');
contrastLeft = p.stimulusContrast(1);
contrastRight = p.stimulusContrast(2);

%% when to present stimuli & allow visual stim to move
stimulusOn = evts.newTrial; % stimulus should come on at the start of a new trial
interactiveOn = stimulusOn.delay(p.interactiveDelay); % the closed-loop period starts when the stimulus comes on, plus an 'interactive delay'

onsetToneSamples = p.onsetToneAmplitude*...
    mapn(p.onsetToneFrequency, 0.1, audSampleRate, 0.02, nAudChannels, @aud.pureTone); % aud.pureTone(freq, duration, samprate, "ramp duration", nAudChannels)
audio.onsetTone = onsetToneSamples.at(interactiveOn); % At the time of 'interative on', send samples to audio device and log as 'onsetTone'

%% wheel position to stimulus displacement
% Here we define the multiplication factor for changing the wheel signal
% into mm/deg visual angle units.  The Lego wheel used has a 31mm radius.
% The standard KÜBLER rotary encoder uses X4 encoding; we record all edges
% (up and down) from both channels for maximum resolution. This means that
% e.g. a KÜBLER 2400 with 100 pulses per revolution will actually generate
% *400* position ticks per full revolution.
wheelOrigin = wheel.at(interactiveOn); % wheel position sampled at 'interactiveOn'
millimetersFactor = map2(p.wheelGain, 31*2*pi/(1024*4), @times); % convert the wheel gain to a value in mm/deg
stimulusDisplacement = millimetersFactor*(wheel - wheelOrigin); % yoke the stimulus displacment to the wheel movement during closed loop

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
leftStimulus.orientation = p.stimulusOrientation;
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
rightStimulus.orientation = p.stimulusOrientation;
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
% save the contrasts as a difference between left and right
evts.contrast = p.stimulusContrast.map(@diff); 
evts.azimuth = azimuth;
evts.response = response;
evts.feedback = feedback;
% Accumulate reward signals and append microlitre units
evts.totalReward = out.reward.scan(@plus, 0).map(fun.partial(@sprintf, '%.1fµl')); 

% Trial ends when evts.endTrial updates.  
% If the value of evts.endTrial is false, the current set of conditional
% parameters are used for the next trial, if evts.endTrial updates to true, 
% the next set of randowmly picked conditional parameters is used
evts.endTrial = nextCondition.at(stimulusOff).delay(p.interTrialDelay); 

%% Parameter defaults
try
p.onsetToneFrequency = 8000;
p.stimulusContrast = [1 0;0 1;0.5 0;0 0.5]'; % conditional parameters have ncols > 1
p.repeatIncorrect = true;
p.interactiveDelay = 0.4;
p.onsetToneAmplitude = 0.2;
p.responseWindow = Inf;
p.stimulusAzimuth = 90;
p.noiseBurstAmp = 0.01;
p.noiseBurstDur = 0.5;
p.rewardSize = 3;
p.rewardKey = 'r';
p.stimulusOrientation = 0;
p.spatialFrequency = 0.19; % Prusky & Douglas, 2004
p.interTrialDelay = 0.5;
p.wheelGain = 3;
% p.audDevIdx = 1;
catch
end
end