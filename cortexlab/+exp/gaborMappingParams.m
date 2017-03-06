function params = gaborMappingParams
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

params = struct;

setValue('type', 'GaborMapping', [], 'A type identifier for the experiment');
% %colour
% params.set('bgColour', 127*[1;1;1], 'Colour of background area', 'rgb');
% % params.set('colour', 255*[1;1;1], 'Colour of bar', 'rgb');
% %sizing
% params.set('cueSigma', [9;9], 'Sigma of Gaussian [width, height]', '°');
% params.set('cueSpatialFrequency', 0.1, 'Sigma of Gaussian [width, height]', '°');
% %misc characteristics
% params.set('visCueContrast', 1, 'Contrast of grating', 'normalised');
% %timing
% params.set('interStimulusInterval', [0.5;2], 'Time between stimulus presentations', 's');
% params.set('stimDuration', 0.5, 'Duration of stimulus presentation', 's');
% 
% %pos
% xpos = 0;
% ypos = 0;
% 
% %% conditional parameters
% 
% 
% % make combinbations thereof
% ori = (0:7)*45/2;
% 
% numReps = repmat(15, 1, numel(ori));
% 
% params.set('altitude', ypos, 'Visual angle above horizon', '°');
% params.set('azimuth', xpos, 'Visual angle right of vertical meridian', '°');
% params.set('orientation', ori, 'Orientation of stimulus', '°');
% params.set('numRepeats', numReps, 'No. of repeats of each condition', '#');

setValue('targetWidth', 35, '°',...
  'Width of target columns (visual angle)');
setValue('distBetweenTargets', 80, '°',...
  'Width between target column centres (visual angle)');
setValue('targetAltitude', 0, '°',...
  'Visual angle of target centre above horizon');
setValue('targetThreshold', params.distBetweenTargets/2, '°',...
  'Horizontal translation of targets to reach response threshold (visual angle)');
setValue('cueSpatialFrequency', 0.1, 'cyc/°',...
  'Spatial frequency of grating cue at the initial location on the horizon');
setValue('cueSigma', [5; 5], '°',...
  'Size (w,h) of the grating, in terms of Gabor ? parameter (visual angle)');
setValue('targetOrientation', 90, '°',...
  'Orientation of gabor grating (cw from horizontal)');
setValue('bgColour', 0*255*ones(3, 1), 'rgb',...
  'Colour of background area');
setValue('targetColour', 0.5*255*ones(3, 1), 'rgb',...
  'Colour of target columns');
% background and targets are the same colour so only target is visible
params.bgColour = 0.25*256*[1; 1; 1] - 1;
params.targetColour = params.bgColour;

setValue('interStimulusInterval', [2;3], 's', 'Delay between trials');
setValue('stimDuration', [2;3], 's', 'Duration of stimulus presentation');

setValue('experimentFun', @(p,r)exp.createGaborMappingExperiment(p,r),...
  [],'Function to create the experiment, takes 2 arguments: the params, the rig');

%% configure trial-specific parameters
contrast = [0.5 0.4 0.2 0.1 0.05 0]; % contrast list to use on one side or the other
% compute contrast one each target - ones side has contrast, other has zero
targetCon = [contrast, zeros(1, numel(contrast));...
             zeros(1, numel(contrast)), contrast];
% feedback is positive for targets chosen with contrast, negative for the
% other target, and negative for no go responses
feedback = [ones(1, numel(contrast)), -ones(1, numel(contrast)); ...
           -ones(1, numel(contrast)),  ones(1, numel(contrast)); ...
           -ones(1, numel(contrast) - 1) 1 -ones(1, numel(contrast) - 1) 1];
% repeat all incorrect trials except zero contrast ones
repIncorrect = abs(diff(targetCon)) > 0;
% by default only use only the 50% contrast condition
useConditions = abs(diff(targetCon)) == 0.5 | abs(diff(targetCon)) == 0.2...
  | abs(diff(targetCon)) == 0.1;
% uniform repeats for at least 300 trials
nReps = ceil(300*useConditions./sum(useConditions));
setValue('visCueContrast', targetCon, 'normalised', 'Contrast of grating cue at each target');
setValue('numRepeats', nReps, '#', 'No. of repeats of each condition');
% p = params.Struct;

  function setValue(name, value, units, description)
    params.(name) = value;
    if ~isempty(units)
      params.([name 'Units']) = units;
    end
    params.([name 'Description']) = description;
  end

end

