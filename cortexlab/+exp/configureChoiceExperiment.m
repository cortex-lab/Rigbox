function experiment = configureChoiceExperiment(experiment, paramStruct, rig)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

%% Create the experiment object
% experiment = exp.ChoiceWorld;
experiment.Type = paramStruct.type; %record the experiment type

%% Further customise parameters
%mapping from target threshold ID to response ID (i.e. threshold 1 maps to
%response 1, 2 to 2)
paramStruct.responseForThreshold = [1; 2];
paramStruct.responseForNoGo = 3;

%create parameters utility object from struct
params = exp.Parameters;
params.Struct = paramStruct;

%% Generate audio samples at device sample rate
% setup playback audio device - no configurable settings for now
% 96kHz sampling rate, 2 channels, try to very low audio latency
dev = rig.audioDevices(strcmp('default', {rig.audioDevices.DeviceName}));
rig.audio = aud.open(dev.DeviceIndex,...
dev.NrOutputChannels,...
dev.DefaultSampleRate, 1);

%Sound samples are wrapped in a cell for storing to a parameter
%(to ensure they're used as one global parameter)
audSampleRate = aud.rate(rig.audio);

%% Generate onset cue tone
toneFreq = params.Struct.onsetToneFreq;
toneLen = params.Struct.onsetToneDuration; % seconds
toneMaxAmp = params.Struct.onsetToneMaxAmp;
rampLen = 0.01; %secs - length of amplitude ramp up/down
toneSamples = toneMaxAmp*aud.pureTone(toneFreq, toneLen, audSampleRate, rampLen);
toneSamples = repmat(toneSamples, dev.NrOutputChannels, 1); % replicate across channels/stereo
params.set('onsetToneSamples', {toneSamples},...
  sprintf('The data samples for the onset tone, sampled at %iHz', audSampleRate), 'normalised');

%% Generate noise burst for negative feedback
% white noise, duplicated across two channels
noiseSamples = repmat(...
  randn(1, params.Struct.negFeedbackSoundDuration*audSampleRate), dev.NrOutputChannels, 1);
params.set('negFeedbackSoundSamples', {noiseSamples},...
  sprintf('The samples for the negative feedback sound, sampled at %iHz', audSampleRate),...
  'normalised');

if ~isfield(params.Struct, 'quiescenceThreshold')
  params.set('quiescenceThreshold', 1,...
    'Input movement must be under this threshold to count as quiescent',...
    'sensor units');
end
if ~isfield(params.Struct, 'stimPositionGain')
  params.set('stimPositionGain', 1,...
    'Stimulus position is multiplied by this',...
    'normalised');
end
holdRequired = pick(paramStruct, 'waitOnEarlyResponse', 'def', false);
responseWindow = pick(paramStruct, 'responseWindow', 'def', inf);
interTrialDelay = pick(paramStruct, 'interTrialDelay', 'def', false);

posFbPeriod = pick(paramStruct, 'positiveFeedbackPeriod', 'def', 1);
negFbPeriod = pick(paramStruct, 'negativeFeedbackPeriod', 'def', 2);

hideCueDelay = pick(paramStruct, 'hideCueDelay', 'def', inf);

%% Create event handlers for basic experiment structure
experiment.addEventHandler(exp.basicWorldEventHandlers(...
  params.Struct.bgCueDelay,... delay between background & cue visual stimuli
  interTrialDelay,... delay between trials
  params.Struct.preStimQuiescentPeriod,... quiescent period required to initiate
  params.Struct.onsetVisStimDelay, ... delay between initiation and visual stimulus
  params.Struct.cueInteractiveDelay, ... delay between visual stim onset & interactive
  holdRequired, ... 
  responseWindow,... max time allowed for giving response
  posFbPeriod,...duration with stimulus locked in response position for rewarded
  negFbPeriod,...duration with stimulus locked in response position for unrewarded
  hideCueDelay));% duration after stimulus cue onset to hide it

%% Create experiment condition server using the parameters
experiment.ConditionServer = params.toConditionServer;

%% Confgiure the experiment with the necessary rig hardware
% TODO: much of this could be generalised
experiment.useRig(rig);
experiment.InputSensor = rig.mouseInput;
experiment.RewardController = rig.daqController;
experiment.StimWindow.BackgroundColour = params.Struct.bgColour;

if isfield(rig, 'lickDetector')
  experiment.LickDetector = rig.lickDetector;
end

%% Wheel input gain calibration
experiment.calibrateInputGain();

% visWheelGain = deg2rad(params.Struct.visWheelGain); % now in vis rad per wheel mm
% % calibrate to translation at centre/ahead screen location
% [cx, cy] = experiment.StimViewingModel.pixelAtView(0,0);
% % pixels per visual radian at the straight ahead screen position
% pxPerRad = experiment.StimViewingModel.visualPixelDensity(cx, cy);
% 
% % units conversion for gain factor:
% % visual:  deg -> px
% %          ------------------------
% % wheel:   mm  -> discrete 'clicks'
% visPxPerWheelPos = visWheelGain*pxPerRad*experiment.InputSensor.MillimetresFactor;
% experiment.InputGain = visPxPerWheelPos;
% 
% % *** old gains, for the record, 6 or 12 or computed as below:
% % *** experiment.InputSensor.Gain =
% %    0.0273*diff(rig.stimViewingModel.pixelAtView(0, [0 deg2rad(distBetweenTargets/2)]));

%% 'Reward' at stimulus
if isfield(params.Struct, 'rewardOnStimulus') && any(params.Struct.rewardOnStimulus(:) > 0)
  % or 'onsetToneSoundPlayed' 'stimulusCueStarted'
  stimRewardHandler = exp.EventHandler('stimulusCueStarted');
  stimRewardHandler.addAction(exp.DeliverReward('rewardOnStimulus'));
  % Small delay to allow time for screen flip before the samples output
  stimRewardHandler.Delay = exp.FixedTime(0.05);
  experiment.addEventHandler(stimRewardHandler);
  terminationHandler = exp.EventHandler('responseMade');
  terminationHandler.addCallback(@(inf,t)reset(inf.Experiment.RewardController));
  experiment.addEventHandler(terminationHandler);
end

%% Positive feedback (deliver reward)
% Deliver reward if feedback-positive entered
rewardHandler = exp.EventHandler('feedbackPositiveStarted');
rewardHandler.Delay = params.Struct.feedbackDeliveryDelay; 
rewardHandler.addAction(exp.DeliverReward('rewardVolume'));
experiment.addEventHandler(rewardHandler);

%% Negative feedback (play noise burst)
% Deliver noise-burst if feedback-negative entered
playNoiseBurst = exp.EventHandler('feedbackNegativeStarted');
playNoiseBurst.Delay = params.Struct.feedbackDeliveryDelay;
% actions to load and play a noise burst
playNoiseBurst.addAction(exp.LoadSound('negFeedbackSoundSamples', 'negFeedbackSoundAmp'));
playNoiseBurst.addAction(exp.PlaySound('negFeedback', false));
experiment.addEventHandler(playNoiseBurst);
%%
if isfield(params.Struct, 'interactiveOnsetToneRelAmp') &&...
    params.Struct.interactiveOnsetToneRelAmp > 0
  playTone = exp.EventHandler('interactiveStarted');
  playTone.addAction(exp.LoadSound('onsetToneSamples', 'interactiveOnsetToneRelAmp'));
  playTone.addAction(exp.PlaySound('onsetTone', false));
  experiment.addEventHandler(playTone);
end
%%
if isfield(params.Struct, 'hideOnResponseOnset') && params.Struct.hideOnResponseOnset
  responseOnset = exp.EventHandler('interactiveMovement');
  responseOnset.Delay = false;
  responseOnset.addAction(exp.EndPhase('stimulusCue'));
  responseOnset.InvalidateStimWindow = true;
  responseMade = exp.EventHandler('responseMade');
  responseMade.addAction(exp.StartPhase('stimulusCue'));
  responseMade.InvalidateStimWindow = true;
  experiment.addEventHandler(responseOnset, responseMade);
end

end

