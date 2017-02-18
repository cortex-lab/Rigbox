function experiment = configureRangeExperiment(experiment, paramStruct, rig)
%UNTITLED13 Summary of this function goes here
%   Detailed explanation goes here

%% Create the experiment object
% experiment = exp.ChoiceWorld;
experiment.Type = paramStruct.type; %record the experiment type

%create parameters utility object from struct
params = exp.Parameters;
params.Struct = paramStruct;

% holdRequired = pick(paramStruct, 'abortOnEarlyResponse', 'def', false);
% responseWindow = pick(paramStruct, 'responseWindow', 'def', inf);
% interTrialDelay = pick(paramStruct, 'interTrialDelay', 'def', false);

%% Create event handlers for basic experiment structure
experiment.addEventHandler(exp.rangeEventHandlers(...
  paramStruct.jumpInteractiveDelay,...
  paramStruct.trialDelay));
experiment.RewardRateFun = paramStruct.rewardFun;

%% Create experiment condition server using the parameters, with randomised trial order
experiment.ConditionServer = params.toConditionServer(true);

%% Confgiure the experiment with the necessary rig hardware
% TODO: much of this could be generalised
experiment.useRig(rig);
experiment.InputSensor = rig.mouseInput;
experiment.RewardController = rig.rewardController;
experiment.StimWindow.BackgroundColour = params.Struct.bgColour;

if isfield(rig, 'lickDetector')
  experiment.LickDetector = rig.lickDetector;
end

%% Wheel input gain calibration
experiment.calibrateInputGain();

end

