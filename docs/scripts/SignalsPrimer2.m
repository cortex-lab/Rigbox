%% Demonstration of working values
% Working values of signals are important for proper signal propagation in
% the C code, as you suspected. Basically each time a new signal value is
% posted (i.e. starting from an 'origin' signal), any dependent signals
% need to be updated to take account of the change. This kind of updating
% is implemented by propagating the changes through the nodes -- where each
% signal is a node, and connections between them are direct dependencies.
% Where the interactions between dependent signals get complicated, this
% can mean a signal/node's value can potentially change more than once
% during a full propagation, but will eventually settle to its final
% correct value. Thus we maintain this 'working value' during the process,
% until the propagation is complete. Then all those signals who got a new
% (working) value, will have their current value updated to the new working
% value.

net = sig.Net; % Create our network
origin = net.origin('input');
a = origin.lag(3);
b = a*origin^2;
%   a = src + 1
%   b = a + src
%   b = identity(b) %

% addlistener(b.Node, 'WorkingValue', 'PostSet', @(src,~)disp(src.WorkingValue))

origin.post(1) % Post some values to the input signal
origin.post(2)
origin.post(3)

%%
% net = sig.Net;
% A = net.origin('A');
% B = net.origin('B');
% C = net.origin('C');
% structSig = net.origin('structSig');
% post(structSig, struct(...
%   'A', A.scan(@(a,b)nansum([a b]), nan), ...
%   'B', C.scan(@(a,b)nansum([a b]), nan), ...
%   'C', B.scan(@(a,b)nansum([a b]), nan)));
% structSig = structSig.subscriptable;
% post(A, 5)
% sigA = structSig.A;
% h = sigA.output();
% 
% % The below is equivilent
% structSig = net.subscriptableOrigin('structSig');
% structSig.CacheSubscripts = true;
% post(structSig, struct(...
%   'A', A.scan(@(a,b)nansum([a b]), nan), ...
%   'B', C.scan(@(a,b)nansum([a b]), nan), ...
%   'C', B.scan(@(a,b)nansum([a b]), nan)));
% post(A, 5)
% sigA = structSig.A
% 
% %% 
% net = sig.Net;
% structSig = net.subscriptableOrigin('structSig');
% structSig.CacheSubscripts = true; % Essential
% structSig.C = net.origin('C');
% structSig.C; % Essential
% structSig.C = 5;
% structSig.C.Node.CurrValue

%% Running an experiment in Signals
% Let's look at Signals in the context of an experiment.  Signals is a
% module of Rigbox, a toolbox that allows the experimentor to parameterize,
% monitor and log experiments, as well as providing a layer for harware
% configuration.
% 
% Rigbox contains a number of classes that define some sort of experimental
% structure, within which an individual experiment will run.  These are
% found in the +exp package.  For a Signals Experiment this is
% exp.SignalsExp.  SignalsExp imposes the inputs, outputs, timing and trial
% structure, as well as managing the logging and saving of data.  In
% setting up a Signals Experiment, the class is given a structure of
% parameters and a structure of objects that interface with hardware
% (audio, PsychToolbox, a DAQ, etc.).  One of the parameters, 'expDef' is a
% path to a Signals Experiment definition; a function that contains the
% specific 'wire diagram' for that experiment.  An experiment definition
% should have the following inputs: 
%
% t - the timing signal, every iteration of the main experiment loop the
% Signals Experiment posts the number of seconds elapsed
%
% events - a Registry of events to be logged.  All Signals assigned to this
% structure in your experiment definition are turned into logging Signals
% and saved to a file at the end of the experiment.
% 
% parameters - any Signals referenced from this subscriptable Signal are
% considered session specific paramters that the experiment will assign
% values to before every session.  Default values for these paramters may
% be provided within the experiment definition.  Before each session the
% experimentor may choose which paramters have fixed values, and which may
% take a different value each trial.  More on this later.
% 
% vs - all visual elements defined in the experiment definition are
% assigned to this structure to be rendered to the screen.  More on this
% later.
%
% inputs - a Registry of input Signals.  In a Signals Experiment this is
% currently a rotary encoder (wheel) and the keyboard.
%
% outputs - the outputs defined in a hardware structure.
%
% audio - any Signals assigned to this Registry have their values outputted
% to the referenced audio device.  This may also be referenced with a named
% audio device, returning a structure of paramters about the devices such
% as number of output channels and sample rate.
%
% This experiment definition function called just once before entering the
% main experiment loop, where values are then posted to the time and input
% Signals, at which point the values are propergated through the network.

%% Signals Experiment task structure
% Below is the task structure set up before calling the experiment
% definition.
% 
% obj.Time = net.origin('t');
% obj.Events.expStart = net.origin('expStart');
% obj.Events.newTrial = net.origin('newTrial');
% obj.Events.expStop = net.origin('expStop');
% advanceTrial = net.origin('advanceTrial');
% obj.Events.trialNum = obj.Events.newTrial.scan(@plus, 0); % track trial number
% globalPars = net.origin('globalPars');
% allCondPars = net.origin('condPars');
% nConds = allCondPars.map(@numel);
% nextCondNum = advanceTrial.scan(@plus, 0); % this counter can go over nConds
% hasNext = nextCondNum <= nConds;
% % this counter cant go past nConds
% % todo: current hack using identity to delay advanceTrial relative to hasNext
% repeatLastTrial = advanceTrial.identity().keepWhen(hasNext);
% condIdx = repeatLastTrial.scan(@plus, 0);
% condIdx = condIdx.keepWhen(condIdx > 0);
% condIdx.Name = 'condIdx';
% repeatNum = repeatLastTrial.scan(@sig.scan.lastTrue, 0) + 1;
% repeatNum.Name = 'repeatNum';
% condPar = allCondPars(condIdx);
% pars = globalPars.merge(condPar).scan(@mergeStruct, struct).subscriptable();
% pars.Name = 'pars';
% [obj.Params, hasNext, obj.Events.repeatNum] = exp.trialConditions(...
%   globalPars, allCondPars, advanceTrial);
% lastTrialOver = ~hasNext.then(true);
% obj.Listeners = [
%   obj.Events.expStart.map(true).into(advanceTrial) %expStart signals advance
%   obj.Events.endTrial.into(advanceTrial) %endTrial signals advance
%   advanceTrial.map(true).keepWhen(hasNext).into(obj.Events.newTrial) %newTrial if more
%   lastTrialOver.into(obj.Events.expStop) %newTrial if more
%   onValue(obj.Events.expStop, @(~)quit(obj));];

% TODO: mention that endTrial must be defined
