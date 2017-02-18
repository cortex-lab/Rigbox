function experiment = createGaborMappingExperiment(paramStruct, rig)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

%% Create the experiment object
experiment = exp.ChoiceWorld;
experiment.Type = paramStruct.type; %record the experiment type


%% Further customise parameters
%set threshold position for response as it is expected, even though it
%isn't used
paramStruct.targetThreshold = paramStruct.distBetweenTargets/2;

%create parameters utility object from struct
params = exp.Parameters;
params.Struct = paramStruct;

%% Generate audio samples at device sample rate
%Sound samples are wrapped in a cell for storing to a parameter
%(to ensure they're used as one global parameter)
audSampleRate = aud.rate(rig.audio);

% %% Generate onset cue tone
% toneFreq = params.Struct.onsetToneFreq;
% toneLen = params.Struct.onsetToneDuration; % seconds
% toneMaxAmp = params.Struct.onsetToneMaxAmp;
% rampLen = 0.01; %secs - length of amplitude ramp up/down
% toneSamples = toneMaxAmp*aud.pureTone(toneFreq, toneLen, audSampleRate, rampLen);
% toneSamples = repmat(toneSamples, 2, 1); % replicate across two channels/stereo
% params.set('onsetToneSamples', {toneSamples},...
%   sprintf('The data samples for the onset tone, sampled at %iHz', audSampleRate), 'normalised');

%% set up the triggers
% when experiment starts, begin first trial
expStart = exp.EventHandler('experimentStarted', exp.StartTrial);

% when a trial starts, prepare the stimuli
prepareStim = exp.EventHandler('trialStarted');
prepareStim.addCallback(@(info, due) info.Experiment.prepareStim());
prepareStim.Delay = 0; % not chained with trialStarted

% some time after trial starts present stimulus
stimStart = exp.EventHandler('trialStarted',...
  {exp.StartPhase('stimulusBackground'), exp.StartPhase('stimulusCue')});
stimStart.Delay = params.Struct.interStimulusInterval;
stimStart.InvalidateStimWindow = true;

% remove stimulus some time after presentation
stimStop = exp.EventHandler('stimulusCueStarted', ...
  {exp.EndPhase('stimulusBackground'), exp.EndPhase('stimulusCue')});
stimStop.Delay = params.Struct.stimDuration;
stimStop.InvalidateStimWindow = true;

% when stimulus phase ends, after a delay, end the trial and start a new
% one
endTrial = exp.EventHandler('stimulusCueEnded', exp.EndTrial);
endTrial.Delay = 0;
nextTrial = exp.EventHandler('trialEnded', exp.StartTrial);

experiment.addEventHandler(expStart, stimStart, stimStop, endTrial, ...
  nextTrial, prepareStim);

%% Create experiment condition server using the parameters, with randomised trial order
experiment.ConditionServer = params.toConditionServer(true);

%% Confgiure the experiment with the necessary rig hardware
% TODO: much of this could be generalised
experiment.useRig(rig);
experiment.InputSensor = rig.mouseInput;
experiment.RewardController = rig.rewardController;
experiment.StimWindow.BackgroundColour = params.Struct.bgColour;

end

