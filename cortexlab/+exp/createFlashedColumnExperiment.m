function experiment = createFlashedColumnExperiment(paramStruct, rig)
%position, contrast, numReps, ...
 % isi, stimDuration, predelay, rig)

%% create the experiment
experiment = custom.GratingColumn; %create an experiment
experiment.Type = paramStruct.type; %record the experiment type

%% use the parameters
params = exp.Parameters;
params.Struct = paramStruct;

experiment.BackgroundColour = params.Struct.bgColour(:)';

% %% set up a  trial condition server
% npos = numel(position);
% ncons = numel(contrast);
% width = 22;
% spatialFreq = 0.1;
% reppos = repmat(position(:), [ncons 1]);
% repcons = reshape(repmat(contrast(:), [1 npos])', [], 1);
% condition = struct('position', num2cell(reppos),...
%   'contrast', num2cell(repcons), 'width', width, 'spatialFreq', spatialFreq);
% condition = repmat(condition, [numReps 1]); % replicate
% condition = condition(randperm(length(condition))); % randomise
% experiment.ConditionServer = exp.PresetConditionServer(condition);

experiment.ConditionServer = params.toConditionServer;

%% set up the triggers
% when experiment starts, begin first trial after predelay
expStart = exp.EventHandler('experimentStarted', exp.StartTrial);
expStart.Delay = predelay;

% when a trial starts, prepare the stimuli
prepareStim = exp.EventHandler('trialStarted');
prepareStim.addCallback(@(info, due) info.Experiment.prepareStim());
prepareStim.Delay = 0;

% some time after trial starts present stimulus
stimStart = exp.EventHandler('trialStarted', exp.StartPhase('stimulus'));
stimStart.Delay = params.Struct.interStimulusInterval;
stimStart.InvalidateStimWindow = true;

% remove stimulus some time after presentation
stimStop = exp.EventHandler('stimulusStarted', exp.EndPhase('stimulus'));
stimStop.Delay = params.Struct.stimDuration;
stimStop.InvalidateStimWindow = true;

% when stimulus phase ends, after a delay, end the trial and start a new
% one
endTrial = exp.EventHandler('stimulusEnded', exp.EndTrial);
endTrial.Delay = 0;
nextTrial = exp.EventHandler('trialEnded', exp.StartTrial);

experiment.addEventHandler(expStart, stimStart, stimStop, endTrial, ...
  nextTrial, prepareStim);

%% Confgiure the experiment with the necessary rig hardware
experiment.RigName = rig.name; % record the name of the rig
experiment.Clock = rig.clock;
experiment.StimWindow = rig.stimWindow;
experiment.StimViewingModel = rig.stimViewingModel;

end