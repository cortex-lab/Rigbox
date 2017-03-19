function p = flashedColumnParams
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

params = exp.Parameters;

params.set('type', 'FlashedGratingColumns', 'A type identifier for the experiment');
params.set('bgColour', 0.25*255*ones(3, 1), 'Colour of background area', 'rgb');
params.set('width', 22, 'Width of target columns (visual angle)', '°');
params.set('spatialFreq', 0.1, 'Spatial frequency of grating on the horizon', 'cyc/°');
params.set('interStimulusInterval', [2; 5], 'Time between stimulus presentations', 's');
params.set('stimDuration', 1, 'Duration of stimulus presentation', 's');

%% conditional parameters
pos = linspace(-40, 40, 9);
con = [0.5];
% make combinbations thereof
posComb = repmat(pos, 1, numel(con));
conComb = reshape(repmat(con, numel(pos), 1), 1, []);
numReps = repmat(30, 1, numel(conComb));

params.set('position', posComb, 'Horizontal position of column centre (visual angle)', '°');
params.set('contrast', conComb, 'Contrast of grating', 'normalised');
params.set('numRepeats', numReps, 'No. of repeats of each condition', '#');

params.set('experimentFun', @custom.createFlashedColumnExperiment,...
  'Function to create the experiment, takes 3 arguments: the params, the rig and the predelay');

p = params.Struct;

end

