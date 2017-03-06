function experiment = createMappingExperiment(experiment, paramStruct, rig)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% experiment = exp.Bars; %create a LickExperiment object
experiment.useRig(rig); %tell the experiment to use the rig's hardware
%set stimulus window background to that specified in params
experiment.StimWindow.BackgroundColour = paramStruct.bgColour;
experiment.StimWindow.clear;
experiment.Type = paramStruct.type; %record the experiment type

%create parameters utility object from struct
params = exp.Parameters;
params.Struct = paramStruct;

%use params to create a condition server, second parameter is whether to
%randomise conditions
experiment.ConditionServer = params.toConditionServer(true); 

%% Create event handling for experiment structure
startFirstTrial = exp.EventHandler('experimentStarted', exp.StartTrial);
startFirstTrial.Delay = 1;

prepStim = exp.EventHandler('trialStarted');
prepStim.Delay = 0;
prepStim.addCallback(@(info, ~) prepareStim(info.Experiment));

presentStim = exp.EventHandler('trialStarted');
presentStim.Delay = paramStruct.interStimulusInterval;
presentStim.addAction(exp.StartPhase('stimulus'));
presentStim.InvalidateStimWindow = true;

%get rid of the stimulus after 'stimDuration'
endStim = exp.EventHandler('stimulusStarted');
endStim.addAction(exp.EndPhase('stimulus'), exp.EndTrial, exp.StartTrial);
endStim.Delay = paramStruct.stimDuration;
endStim.InvalidateStimWindow = true;

%add the event handlers we just created
experiment.addEventHandler(startFirstTrial, prepStim, presentStim, endStim);


end

