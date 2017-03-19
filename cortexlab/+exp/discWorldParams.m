function params = discWorldParams
%EXP.DISCWORLDPARAMS Default parameters struct for DiscWorld experiments
%   Detailed explanation goes here
%
% Part of Cortex Lab Rigbox customisations

% 2013-01 CB created, inspired by Terry Pratchett

params.type = 'DiscWorld';

%% experiment creation function
setValue(...
  'experimentFun', @(pars, rig) exp.configureChoiceExperiment(exp.DiscWorld, pars, rig),...
  [], 'Function to create the experiment, takes 2 arguments: the params and the rig');

%% initial parameters with defaults values
% feedback parameters
setValue('rewardVolume', 3, 'µl',...
  'Reward volumn delivered on each correct trial');

% trial temporal structure
setValue('onsetVisStimDelay', 0.1, 's',...
  'Duration between the start of the onset tone and visual stimulus presentation');
setValue('onsetToneDuration', 0.1, 's',...
  'Duration of the onset tone');
setValue('onsetToneRampDuration', 0.01, 's',...
  'Duration of the onset tone amplitude ramp (up and down each this length)');
setValue('preStimQuiescentPeriod', [2; 3], 's',...
  'Required period of no input before stimulus presentation');
setValue('bgCueDelay', false, 's', 'NOT IMPLEMENTED');
setValue('cueInteractiveDelay', 1, 's',...
  'Delay period between grating cue presentation and interactive phase');
setValue('feedbackDeliveryDelay', [0; 0.5], 's',...
  'Delay period between response completion and feedback provided');
setValue('negFeedbackSoundDuration', 2, 's',...
  'Duration of negative feedback noise burst');

% visual stimulus characteristics
setValue('cueAzimuth', 0, '°',...
  'Horizontal position of cue centre (visual angle)');
setValue('cueElevation', 15, '°',...
  'Elevation of cue centre above horizon (visual angle)');
setValue('choiceThreshold', [-45; 45], '°',...
  'Rotation of cue required to reach response threshold');
setValue('cueSpatialFrequency', 0.1, 'cyc/°',...
  'Spatial frequency of grating cue at the centre');
setValue('cueSigma', [10; 10], '°',...
  'Size (w,h) of the grating, in terms of Gabor sigma parameter (visual angle)');
setValue('bgColour', 127*ones(3, 1), 'rgb',...
  'Colour of background area');
setValue('cueColour', 127*ones(3, 1), 'rgb',...
  'Colour of cue');
setValue('visWheelGain', 3, '°/mm',...
  'Visual stimulus rotation per movement at wheel apex');

% audio
setValue('onsetToneMaxAmp', 1, 'normalised',...
  'Maximum amplitude of onset tone');
setValue('onsetToneFreq', 12e3, 'Hz',...
  'Frequency of the onset tone');
setValue('negFeedbackSoundAmp', 0.025, 'normalised',...
  'Amplitude of negative feedback noise burst');

%% configure trial-specific parameters
oris = [-45 45]; % list of orientations to use
contrasts = [1.0 0.5 0.25 0.1 0.05 0]; % list of contrasts to use
% create all combinations of above
[trialOris, trialContrasts] = ndgrid(oris, contrasts);
trialOris = trialOris(:)';
trialContrasts = trialContrasts(:)';
nConditions = size(trialOris, 1);
% feedback on orientation side
feedback = [-sign(trialOris); sign(trialOris)];
% repeat all incorrect trials except zero contrast ones
repIncorrect = trialContrasts > 0;
% by default only use only the 100% contrast condition
useConditions = trialContrasts == 1.0;
% uniform repeats for at least 300 trials
nReps = ceil(300*useConditions./sum(useConditions));
% use standard amplitude by default for all trials
toneAmp = ones(1, nConditions);
setValue('cueOrientation', trialOris, '°',...
  'Orientation of gabor grating (cw from horizontal)');
setValue('visCueContrast', trialContrasts, 'normalised', 'Contrast of grating cue at each target');
setValue('feedbackForResponse', feedback, 'normalised', 'Feedback given for each target');
setValue('repeatIncorrectTrial', repIncorrect, 'logical',...
  'Whether to repeat trials with incorrect responses (baiting)');
setValue('onsetToneRelAmp', toneAmp, 'normalised',...
  'Amplitude of onset tone in units of (i.e. relative to) the max.');
setValue('numRepeats', nReps, '#', 'No. of repeats of each condition');

  function setValue(name, value, units, description)
    params.(name) = value;
    if ~isempty(units)
      params.([name 'Units']) = units;
    end
    params.([name 'Description']) = description;
  end

end

