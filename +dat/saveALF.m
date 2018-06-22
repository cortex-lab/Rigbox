function [alfPaths, filenames] = saveALF(data, ai)
% ALFPATHS = DAT.SAVEALF(DATA) Extract, save and register behaviour ALFs
%  Provided the data structure from a signals experiment, this function
%  extracts the relevant data, formats them in accordance with the ALF
%  standard, saves the NPY files and attempts to register them to Alyx
%  (provided an instance of Alyx).
%
% See also EXP.SIGNALSEXP, ALYX
%
% 2018 - MW created

expPath = dat.expPath(data.expRef, 'main', 'master');

% Write feedback
feedback = getOr(data.events, 'feedbackValues', NaN);
feedback = double(feedback);
feedback(feedback == 0) = -1;
if ~isnan(feedback)
  writeNPY(feedback(:), fullfile(expPath, 'cwFeedback.type.npy'));
  alf.writeEventseries(expPath, 'cwFeedback',...
    data.events.feedbackTimes, [], []);
  writeNPY([data.outputs.rewardValues]', fullfile(expPath, 'cwFeedback.rewardVolume.npy'));
else
  warning('No ''feedback'' events recorded, cannot register to Alyx')
end

% Write go cue
interactiveOn = getOr(data.events, 'interactiveOnTimes', NaN);
if ~isnan(interactiveOn)
  alf.writeEventseries(expPath, 'cwGoCue', interactiveOn, [], []);
else
  warning('No ''interactiveOn'' events recorded, cannot register to Alyx')
end

% Write response
response = getOr(data.events, 'responseValues', NaN);
if min(response) == -1
  response(response == 0) = 3;
  response(response == 1) = 2;
  response(response == -1) = 1;
end
if ~isnan(response)
  writeNPY(response(:), fullfile(expPath, 'cwResponse.choice.npy'));
  alf.writeEventseries(expPath, 'cwResponse',...
    data.events.responseTimes, [], []);
else
  warning('No ''feedback'' events recorded, cannot register to Alyx')
end

% Write stim on times
stimOnTimes = getOr(data.events, 'stimulusOnTimes', NaN);
if ~isnan(stimOnTimes)
  alf.writeEventseries(expPath, 'cwStimOn', stimOnTimes, [], []);
else
  warning('No ''stimulusOn'' events recorded, cannot register to Alyx')
end
contL = getOr(data.events, 'contrastLeftValues', NaN);
contR = getOr(data.events, 'contrastRightValues', NaN);
if ~any(isnan(contL))&&~any(isnan(contR))
  writeNPY(contL(:), fullfile(expPath, 'cwStimOn.contrastLeft.npy'));
  writeNPY(contR(:), fullfile(expPath, 'cwStimOn.contrastRight.npy'));
else
  warning('No ''contrastLeft'' and/or ''contrastRight'' events recorded, cannot register to Alyx')
end

% Write trial intervals
alf.writeInterval(expPath, 'cwTrials',...
  data.events.newTrialTimes(:), data.events.endTrialTimes(:), [], []);
repNum = data.events.repeatNumValues(:);
writeNPY(repNum == 1, fullfile(expPath, 'cwTrials.inclTrials.npy'));
writeNPY(repNum, fullfile(expPath, 'cwTrials.repNum.npy'));

% Write wheel times, position and velocity
pos = data.inputs.wheelValues(:);
pos = pos*(3.1*2*pi/(4*1024));
t = data.inputs.wheelTimes(:);
% Resample linear
Fs = 1000; 
wheelTimes = t(1):1/Fs:t(end);
wheelValues = interp1(t, pos, wheelTimes);
% Timestamps of first and last samples
wheelTS = [0 wheelTimes(1); length(wheelValues)-1 wheelTimes(end)];

alf.writeTimeseries(expPath, 'Wheel', wheelTS, [], []);
writeNPY(wheelValues, fullfile(expPath, 'Wheel.position.npy'));
writeNPY(wheelValues./wheelTimes, fullfile(expPath, 'Wheel.velocity.npy'));

% Register them to Alyx
filenames = dir(expPath);
isNPY = cellfun(@(f)endsWith(f, '.npy'), {filenames.name});
filenames = filenames(isNPY);
alfPaths = fullfile({filenames.folder}, {filenames.name});
if nargin == 2; ai.registerFile(alfPaths); end
end