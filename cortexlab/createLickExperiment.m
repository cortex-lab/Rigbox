function e = createLickExperiment(paramStruct, rig)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

e = exp.LickExperiment; %create a LickExperiment object
e.useRig(rig); %tell the experiment to use the rig's hardware
%set stimulus window background to that specified in params
rig.stimWindow.BackgroundColour = paramStruct.bgColour;

if ~isfield(paramStruct, 'quiescenceThreshold')
  paramStruct.quiescenceThreshold = 1;
  disp('********')
end

%create parameters utility object from struct
params = exp.Parameters;
params.Struct = paramStruct;

% e.InputThreshold = paramStruct.activeLickThreshold

%% Compute flashed bar and grating charateristics in graphics coordinates
model = rig.stimViewingModel; %viewing model for visual<->graphics coords
%[x, y] = model.pixelAtView(polarAngle, visualAngle)
screenTop = 0;
screenBottom = rig.stimWindow.Bounds(3); % TODO: remove hard-coding

nBarPos = 15;
barWidth = paramStruct.barWidth; %visual/deg
barRange = paramStruct.barAzimuthRange; %visual/deg
barCentres = linspace(barRange(1), barRange(2), nBarPos)';  %visual/deg
%[x, y] = model.pixelAtView(polarAngle, visualAngle)
barLefts = model.pixelAtView(0, deg2rad(barCentres - 0.5*barWidth));
barRights = model.pixelAtView(0, deg2rad(barCentres + 0.5*barWidth));
%rectangles are (left,top,right,bottom)
barPxRects = [
    barLefts,...
    repmat(screenTop, [nBarPos 1]),...
    barRights,...
    repmat(screenBottom, [nBarPos 1])];

barPosSeqCycles = 400; %barSeqLength = nBarPos*barSeqCycles, then it repeats again
%seq of indices to pick from the bar rectangles
barRectSeq = repmat((1:nBarPos)', barPosSeqCycles, 1);
barRectSeq = barRectSeq(randperm(numel(barRectSeq))); %randomise the whole sequence
barCol = paramStruct.barColours;
%indices to select bar colours
barColSeq = repmat((1:size(barCol, 1))', ceil(numel(barRectSeq)/numel(barCol)), 1);
%pick only enough elements to match the position sequence in length
barColSeq = barColSeq(1:numel(barRectSeq));
barColSeq = barColSeq(randperm(numel(barColSeq))); %randomise

%% Store the computed parameters for the experiment
e.BarAzimuths = barCentres;
e.BarPxRects = barPxRects;
e.BarRectSeq = barRectSeq;
e.BarColourSeq = barColSeq;

%use params to create a condition server, second parameter is whether to
%randomise conditions
e.ConditionServer = params.toConditionServer(false); 

% Set # of licks required to get rewarded for active sessions
e.InputThreshold = paramStruct.lickThreshold;

%% Create event handling for experiment structure
startFirstTrial = exp.EventHandler('experimentStarted', exp.StartTrial);
startFirstTrial.Delay = 1;

prepareTarget = exp.EventHandler('trialStarted');
%event handler callbacks take arguments as:
% (info, dueTime) where info is an exp.EventInfo object, and dueTime is the
% time that the handler became due
prepareTarget.addCallback(@(info, due) prepareTargetTexture(info.Experiment));

%start a quiescence watch when the trial is started
startQuiescenceWatch = exp.EventHandler('trialStarted');
%Convert interStimulusInterval to an appropriate TimeSampler
quiescentPeriod = exp.TimeSampler.using(paramStruct.preStimNoLickPeriod);
%Callback to initiate a quiescence period (i.e. period of no input) watch
%The period required will be drawn from the quiescentPeriod sampler
startQuiescenceWatch.addCallback(@(info, due) info.Experiment.startQuiescenceWatch(...
  'quiescent', quiescentPeriod.secs));
%now set a trigger for the quiescentEpoch event which should occur when
%the required period has been met. the trigger will present the grating
presentGrating = exp.EventHandler('quiescentEpoch');
presentGrating.addAction(exp.StartPhase('grating'));

% configure laser during stimulus onset if enabled
if pick(paramStruct, 'laserProbability', 'def', 0) > 0
  rig.laser.StimDuration = paramStruct.laserDuration;
  rig.laser.PulseFrequency = paramStruct.laserPulseFreq;
  rig.laser.PulseLength = paramStruct.laserPulseLength;
  presentGrating.addAction(exp.TriggerLaser(rig.laser, paramStruct.laserProbability));
end


%get rid of the grating after 'stimDuration'
endStimAfterDelay = exp.EventHandler('gratingStarted');
endStimAfterDelay.addAction(exp.EndPhase('grating'));
endStimAfterDelay.Delay = paramStruct.stimDuration;
endStimAfterDelay.InvalidateStimWindow = true;

if ~paramStruct.active
  %for non-active session, deliver reward when grating appears
  deliverReward = exp.EventHandler('gratingStarted');
  deliverReward.Delay = paramStruct.passiveRewardDelay;
else
  %for active session, deliver reward when licks occur during grating
  interactiveStart = exp.EventHandler('gratingStarted');
  if isfield(paramStruct, 'stimInteractiveDelay')
    interactiveStart.Delay = paramStruct.stimInteractiveDelay;
  end
  interactiveStart.addAction(exp.StartPhase('interactive'));
  deliverReward = exp.EventHandler('inputThresholdCrossed');
  deliverReward.addCallback(@(~,~) disp('input threshold'));
  deliverReward.addAction(exp.EndPhase('interactive'));
  
  endStimAfterLick = exp.EventHandler('inputThresholdCrossed', exp.EndPhase('grating'));
  endStimAfterLick.Delay = pick(paramStruct, 'stimLickHideLag', 'def', false);
  
  endStimAfterDelay.addAction(exp.EndPhase('interactive'));
  
  e.addEventHandler(endStimAfterLick);
  e.addEventHandler(interactiveStart);
end

deliverReward.addAction(exp.DeliverReward('rewardSize'));

%start a new trial when the grating is removed
startNewTrial = exp.EventHandler('gratingEnded');
startNewTrial.addAction(exp.EndTrial, exp.StartTrial);
startNewTrial.Delay = paramStruct.postStimDuration;

%add the event handlers we just created
e.addEventHandler(startFirstTrial, prepareTarget, startQuiescenceWatch,...
  presentGrating, deliverReward, endStimAfterDelay, startNewTrial);


end

