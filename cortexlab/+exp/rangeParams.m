function params = rangeParams(subtype)
%EXP.CHOICEWORLDPARAMS Default parameters struct for ChoiceWorld experiments
%   Detailed explanation goes here
%
% Part of Cortex Lab Rigbox customisations

% 2013-01 CB created

if nargin < 1
  subtype = 'Position';
end

%% experiment creation function
setValue(...
  'experimentFun', @(pars,rig)tbc,...
  [], 'Function to create the experiment, takes 2 arguments: the params and the rig');
%@(pars,rig)exp.configureRangeExperiment(exp.TargetRange,pars,rig)
params.type = [subtype 'TargetRange'];

%% initial parameters with defaults values
% feedback parameters
setValue('rewardVolume', 1.5, 'µl',...
  'Reward volumn delivered on each correct trial');

% trial temporal structure
setValue('jumpInteractiveDelay', 0.5, 's',...
  'Delay period');
% setValue('assessmentDelay', 1.5, 's',...
%   'Delay period');
setValue('trialDelay', 5, 's',...
  'Delay period');

% functions

setValue('posDistFun', @() 3*randn - 40, [],...
  'Function to do blah');
setValue('rewardFun', @(x) 2*exp(-x^2/400^2), [],...
  'Function to do blah');

% visual stimulus characteristics
setValue('targetWidth', 35, '°',...
  'Width of target columns (visual angle)');
setValue('targetAltitude', 0, '°',...
  'Visual angle of target centre above horizon');
setValue('cueSpatialFrequency', 0.1, 'cyc/°',...
  'Spatial frequency of grating cue at the initial location on the horizon');
setValue('cueSigma', [9; 9], '°',...
  'Size (w,h) of the grating, in terms of Gabor ? parameter (visual angle)');
setValue('targetOrientation', 90, '°',...
  'Orientation of gabor grating (cw from horizontal)');
setValue('bgColour', 0.5*256*ones(3, 1) - 1, 'rgb',...
  'Colour of background area');
setValue('targetColour', 0.5*256*ones(3, 1) - 1, 'rgb',...
  'Colour of target columns');
setValue('visWheelGain', 3, '°/mm',...
  'Visual stimulus translation per movement at wheel surface (for stimuli ahead)');

%% configure trial-specific parameters
% contrast = [0.5 0.4 0.2 0.1 0.05 0]; % contrast list to use on one side or the other
% % compute contrast one each target - ones side has contrast, other has zero
% targetCon = [contrast, zeros(1, numel(contrast));...
%              zeros(1, numel(contrast)), contrast];
% % feedback is positive for targets chosen with contrast, negative for the
% % other target, and negative for no go responses
% feedback = [ones(1, numel(contrast)), -ones(1, numel(contrast)); ...
%            -ones(1, numel(contrast)),  ones(1, numel(contrast)); ...
%            -ones(1, numel(contrast) - 1) 1 -ones(1, numel(contrast) - 1) 1];
% % repeat all incorrect trials except zero contrast ones
% repIncorrect = abs(diff(targetCon)) > 0;
% % by default only use only the 50% contrast condition
% useConditions = abs(diff(targetCon)) == 0.5 | abs(diff(targetCon)) == 0.2...
%   | abs(diff(targetCon)) == 0.1;
% % uniform repeats for at least 300 trials
% nReps = ceil(300*useConditions./sum(useConditions));
% % use max amplitude by default for all trials
% toneAmp = ones(1, size(targetCon, 2));
setValue('visCueContrast', [1 1], 'normalised', 'Contrast of grating cue at each target');
setValue('numRepeats', [250 250], '#', 'No. of repeats of each condition');

%% overrides for particular choice world types
switch subtype
%   case 'Classic'
%     % nothing to change for this type of experiment
%   case 'SingleTarget'
%     %Lose everything to do with background bars:
%     params.bgCueDelay = false;
%     % background and targets are the same colour so only target is visible
%     params.bgColour = 0.25*255*[1; 1; 1];
%     params.targetColour = params.bgColour;
%   otherwise
%     error('Unrecognised type ''%s''', subtype);
end

  function setValue(name, value, units, description)
    params.(name) = value;
    if ~isempty(units)
      params.([name 'Units']) = units;
    end
    params.([name 'Description']) = description;
  end

end

