function p = barMappingParams
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
%   bh modified 16-Jun-2015 16:59:13; see commented lines

params = exp.Parameters;

params.set('type', 'BarMapping', 'A type identifier for the experiment');
%colour
params.set('bgColour', 0*[1;1;1], 'Colour of background area', 'rgb');
params.set('colour', 255*[1;1;1], 'Colour of bar', 'rgb');
%sizing
params.set('size', 5, 'Height or width of bars (visual angle)', '°');
%misc characteristics
params.set('orientation', 'v', 'Orientation of stimulus', 'horizontal or vetical');
%timing
% params.set('interStimulusInterval', [0.5;2], 'Time between stimulus presentations', 's');
params.set('interStimulusInterval', [0.5 2.5], 'Time between stimulus presentations', 's'); %bh modified 16-Jun-2015 16:59:13
% params.set('stimDuration', 0.5, 'Duration of stimulus presentation', 's');
params.set('stimDuration', 0.5, 'Duration of stimulus presentation', 's'); %bh modified 16-Jun-2015 16:59:13

%% conditional parameters

pos = linspace(-90, 90, 13); %horizontal angles 40 15
% pos = linspace(-9, 135, 16); %bh modified 16-Jun-2015 16:59:13

% % make combinbations thereof
% conComb = reshape(repmat(targetCon, [1 1 numel(xpos)*numel(ypos)]), 2, []);
% xposComb = repmat(reshape(repmat(xpos, size(targetCon, 2), 1), 1, []), 1, numel(ypos));
% yposComb = reshape(repmat(ypos, size(targetCon, 2)*numel(xpos), 1), 1, []);

posComb = pos;

numReps = repmat(10, 1, size(posComb, 2));

params.set('position', posComb, 'Visual angle of target centre', '°');
params.set('numRepeats', numReps, 'No. of repeats of each condition', '#');

params.set('experimentFun', @(pars,rig)exp.createMappingExperiment(exp.Bars,pars,rig),...
  'Function to create the experiment, takes 2 arguments: the params and the rig');

p = params.Struct;

end

