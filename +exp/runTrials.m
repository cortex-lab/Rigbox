function [log, audio, timestamps] = runTrials(expdef, parsData)
%RUNTRIALS Summary of this function goes here
%   Detailed explanation goes here

if isnumeric(parsData)
  % parsData is number of trials, so turn number of trials into struct
  % array with no fields but 'parsData' elements
  globalStruct = struct;
  allCondStruct = rmfield(struct('dummy', cell(1, parsData)), 'dummy');
else
  if ~isa(parsData, 'exp.Parameters')
    parsData = exp.Parameters(parsData);
  end
  [~, globalStruct, allCondStruct] = parsData.toConditionServer();
end

globalPars = sig.Signal('globalPars');
allCondPars = sig.Signal('condPars');

t = sig.Signal('t');
evts = sig.Registry;
stim = Bag;
audio = aud.AudioRegistry;
inputs = sig.Registry;
inputs.wheel = t.do(@GetMouse);
inputs.keys = t.do(@KbQueueCheck).skipRepeats();
inputs.wheel.Name = 'wheel';

evts.expStart = sig.Signal('expStart');

advanceTrial = evts.expStart.then(true);
advanceTrial.Name = 'advanceTrial';
[pars, hasNext, evts.repeat] = exp.presetCondServer(globalPars, allCondPars, advanceTrial);
pars.Name = 'pars';
evts.newTrial = sig.Signal('newTrial');

%% execute the definition function
defargs = {t, evts, pars, stim, audio, inputs};
expdef(defargs{1:nargin(expdef)});

%% construct stuff from definition events
evts.trialNum = evts.newTrial.sumOverTime(); % track trial number
evts.expStop = delay(then(~hasNext, true), 1);
advanceAtEnd = evts.endTrial.into(advanceTrial);
newTrialIfMore = hasNext.then(true).into(evts.newTrial);

%% start the experiment
% some listeners
disptrial = evts.trialNum.printOnValue('trial %s started\n');
disprepeat = evts.repeat.printOnValue('repeat %s\n');
parslist = pars.targetAzimuth.printOnValue('azi=%s\n');
fblist = evts.feedback.printOnValue('feedback= %s\n');
listeners = [advanceAtEnd newTrialIfMore disptrial disprepeat parslist fblist];

% cleanup
expoverlist = evts.expStop.onValue(@cleanup);
expabortedlist = inputs.keys.then(true).onValue(@cleanup);
listeners = [listeners expoverlist expabortedlist];
releaseKeyboard = onCleanup(@KbQueueRelease);
cleanupListeners = onCleanup(@()delete(listeners));

% keyboard listener
KbQueueCreate();
KbQueueStart();

% post parameter data
globalPars.post(globalStruct);
allCondPars.post(allCondStruct);
inputs.wheel.post(0);

% make it start
clockZeroTime = GetSecs;
expStartDateTime = now;
evts.expStart.post(true);

timestamps = zeros(1, 320000);
ts = 0;

running = true;

while running
  t.post(GetSecs);
  ts = ts + 1;
  timestamps(ts) = GetSecs;
  drawnow; % this also allows timers etc to run
end

expStopDateTime = now;
%% assemble the log
log = struct;
log.startDateTime = expStartDateTime;
log.startDateTime = datestr(log.startDateTime);
%events
log.events = logs(evts, clockZeroTime);
%inputs
log.inputs = logs(inputs, clockZeroTime);
%audio
log.audio = logs(audio, clockZeroTime);
log.endDateTime = expStopDateTime;
log.endDateTime = datestr(log.endDateTime);
timestamps(ts+1:end) = [];

  function cleanup(~)
    disp('experiment over');
    running = false;
  end

end

