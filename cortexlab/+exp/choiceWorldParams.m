function params = choiceWorldParams(subtype)
%EXP.CHOICEWORLDPARAMS Default parameters struct for ChoiceWorld experiments
%   Detailed explanation goes here
%
% Part of Cortex Lab Rigbox customisations

% 2013-01 CB created

if nargin < 1
  subtype = 'SingleTarget';
end

%% experiment creation function
setValue(...
  'experimentFun', @(pars, rig) exp.configureChoiceExperiment(exp.ChoiceWorld, pars, rig),...
  [], 'Function to create the experiment, takes 2 arguments: the params and the rig');

params.type = 'ChoiceWorld';

%% initial parameters with defaults values
% feedback parameters
setValue('rewardVolume', 3, 'µl',...
  'Reward volume delivered on each correct trial');
setValue('rewardOnStimulus', 0, 'µl',...
  '''Reward'' volume delivered after stimulus onset');

% trial temporal structure
setValue('onsetVisStimDelay', 0, 's',...
  'Duration between the start of the onset tone and visual stimulus presentation');
setValue('onsetToneDuration', 0.1, 's',...
  'Duration of the onset tone');
setValue('onsetToneRampDuration', 0.01, 's',...
  'Duration of the onset tone amplitude ramp (up and down each this length)');
setValue('preStimQuiescentPeriod', [0.2; 0.6], 's',...
  'Required period of no input before stimulus presentation');
setValue('bgCueDelay', 0, 's',...
  'Delay period between target column presentation and grating cue');
setValue('cueInteractiveDelay', 0, 's',...
  'Delay period between grating cue presentation and interactive phase');
setValue('hideCueDelay', inf, 's',...
  'Delay period between cue presentation onset to hide it');
setValue('responseWindow', inf, 's',...
  'Duration of window allowed for making a response');
setValue('positiveFeedbackPeriod', 1, 's',...
  'Duration of positive feedback phase (with stimulus locked in response position)');
setValue('negativeFeedbackPeriod', 2, 's',...
  'Duration of negative feedback phase (with stimulus locked in response position)');
setValue('feedbackDeliveryDelay', 0, 's',...
  'Delay period between response completion and feedback provided');
setValue('negFeedbackSoundDuration', 0.5, 's',...
  'Duration of negative feedback noise burst');
setValue('interTrialDelay', 0, 's', 'Delay between trials');
setValue('waitOnEarlyResponse', false, 'logical',...
  'Delay interactive until no movement for ''cueInteractiveDelay''');
setValue('hideOnResponseOnset', false, 'logical',...
  'Hide the stimulus when the response starts');

% visual stimulus characteristics
setValue('targetWidth', 35, '°',...
  'Width of target columns (visual angle)');
setValue('distBetweenTargets', 180, '°',...
  'Width between target column centres (visual angle)');
setValue('targetAltitude', 0, '°',...
  'Visual angle of target centre above horizon');
setValue('targetThreshold', params.distBetweenTargets/2, '°',...
  'Horizontal translation of targets to reach response threshold (visual angle)');
setValue('cueSpatialFrequency', 0.1, 'cyc/°',...
  'Spatial frequency of grating cue at the initial location on the horizon');
setValue('cueSigma', [9; 9], '°',...
  'Size (w,h) of the grating, in terms of Gabor ? parameter (visual angle)');
setValue('targetOrientation', 45, '°',...
  'Orientation of gabor grating (cw from horizontal)');
setValue('bgColour', 0*255*ones(3, 1), 'rgb',...
  'Colour of background area');
setValue('targetColour', 0.5*255*ones(3, 1), 'rgb',...
  'Colour of target columns');
setValue('visWheelGain', 3.5, '°/mm',...
  'Visual stimulus translation per movement at wheel surface (for stimuli ahead)');

% audio
setValue('onsetToneMaxAmp', 1, 'normalised',...
  'Maximum amplitude of onset tone');
setValue('onsetToneFreq', 11e3, 'Hz',...
  'Frequency of the onset tone');
setValue('negFeedbackSoundAmp', 0.01, 'normalised',...
  'Amplitude of negative feedback noise burst');

% misc
setValue('quiescenceThreshold', 10, 'sensor units',...
  'Input movement must be under this threshold to count as quiescent');

%% configure trial-specific parameters
contrast = [1 0.5 0.25 0.12 0.06 0]; % contrast list to use on one side or the other
% compute contrast one each target - ones side has contrast, other has zero
targetCon = [contrast, zeros(1, numel(contrast));...
             zeros(1, numel(contrast)), contrast];
% feedback is positive for targets chosen with contrast, negative for the
% other target, and negative for no go responses
feedback = [ones(1, numel(contrast)), -ones(1, numel(contrast)); ...
           -ones(1, numel(contrast)),  ones(1, numel(contrast)); ...
           -ones(1, numel(contrast) - 1) 1 -ones(1, numel(contrast) - 1) 1];
% repeat all incorrect trials except zero contrast ones
repIncorrect = abs(diff(targetCon)) > 0.25;
% by default only use only the 50% contrast condition
useConditions = abs(diff(targetCon)) == 0.5 | abs(diff(targetCon)) == 1;
% uniform repeats for at least 300 trials
nReps = ceil(1000*useConditions./sum(useConditions));
setValue('visCueContrast', targetCon, 'normalised', 'Contrast of grating cue at each target');
setValue('feedbackForResponse', feedback, 'normalised', 'Feedback given for each target');
setValue('repeatIncorrectTrial', repIncorrect, 'logical',...
  'Whether to repeat trials with incorrect responses (baiting)');
setValue('onsetToneRelAmp', 1, 'normalised',...
  'Amplitude of onset tone in units of (i.e. relative to) the max.');
setValue('interactiveOnsetToneRelAmp', 0, 'normalised',...
  'Amplitude of interactive onset tone in units of (i.e. relative to) the max.');
setValue('numRepeats', nReps, '#', 'No. of repeats of each condition');

%% overrides for particular choice world types
switch subtype
  case 'Classic'
    % nothing to change for this type of experiment
  case 'SingleTarget'
    %Lose everything to do with background bars:
    params.bgCueDelay = false;
    % background and targets are the same colour so only target is visible
    params.bgColour = 0.25*256*[1; 1; 1] - 1;
    params.targetColour = params.bgColour;
  case 'Surround'
    %Lose everything to do with background bars:
    params.bgCueDelay = false;
    setValue('surroundOrientation', 0, '°',...
      'Orientation of gabor grating (cw from horizontal)');
    params.bgColour = 0.5*256*[1; 1; 1] - 1;
    params.targetColour = params.bgColour;
    % add surround contrast
    setValue('surroundContrast', 0.03, 'normalised', 'Contrast of the surround grating');
    params.type = 'SurroundChoiceWorld';
    params.experimentFun = @(pars, rig)...
        exp.configureChoiceExperiment(exp.SurroundChoiceWorld, pars, rig);
  otherwise
    error('Unrecognised type ''%s''', subtype);
end

  function setValue(name, value, units, description)
    params.(name) = value;
    if ~isempty(units)
      params.([name 'Units']) = units;
    end
    params.([name 'Description']) = description;
  end

end

