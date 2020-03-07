%% The Experiment Framework
% The 'Experiment Framework' is everything defined by the |exp.Experiment|
% base class.  This class defines some basic methods (e.g. run, quit,
% saveData, useRig) and 'experiment phases' (experimentInit,
% experimentStarted, experimentEnded, experimentCleanup) within which stuff
% happens and updates are broadcast to any listener such as MC.  
%
% Experiments are constructed using a set of parameters and a rig object.
% An Experiment stores and uses various objects throughout the experiment,
% for instance an |exp.ConditionServer| object that manages the trial
% parameter conditions and an |io.Communicator| that manages the sending of
% updates to remote listeners.  All experiments run in Rigbox (i.e. via
% |mc| and/or |srv.expServer|) use this framework.
%
% Experiment logic is typically implemented in one of two ways:
%
% # With EventHandlers that trigger a cascade of events and phase changes,
% e.g. a 'trial' phase may be triggered by an 'intermissionEnded' event,
% which in turn may trigger a 'stimulusStarted' event, etc.
% # With a Signals experiment definition function (expDef), whereby
% hardware input and timing signals trigger values to propogate through a
% user-defined network, ultimately triggering stimulus changes and hardware
% outputs.

%% Experiment timeline
% An experiment typically follows the following steps:
% 
% # Experiment configuration - This is when the experiment object is
% constructed and various properties are set. This is usually handled by
% |srv.prepareExp|(1) which calls a special experiment configuration function
% and sets the pre- and post- delays. For Signals Experiments, this is
% |exp.configureSignalsExperiment|, which simple instantiates the
% experiment object.  For other Experiment types the configuration function
% is defined by the 'experimentFun' field in the parameter struct, e.g. for
% ChoiceWorld the config function is |exp.configureChoiceExperiment|, which
% sets up the event handlers. Configuration functions must accept a
% parameter structure and rig object as their inputs.
% # Experiment initialization - Initialization occurs when |run| is called
% on the Experiment object.  Typically this involves initializing the Data
% structure and zeroing the input hardware devices.  The 'startDateTime'
% field of the Data struct is set during initialization (by the
% Experiment's |init| method).  The 'experimentInit' event is then
% triggered, which starts any auxillary services.  This event is also
% recorded in the Data structure(2).  Immediately after this we enter the
% main experiment loop.  In the Signals Experiment Framework this means the
% t event signal starts to update.
% # Experiment start - After the experiment pre-delay the main experiment
% phase begins. This is recorded by the 'experimentStart' event.  In the
% Signals Experiment Framework this is when the expRef is posted to the
% 'expStart' event signal.  In ChoiceWorld, this is when the first
% 'trialStarted' event occurs.
% # Experiment end - The main experiment phase ends when the |quit| method
% is called on the Experiment object.  At this point all other experiment
% phases are aborted.  In the Signals Experiment Framework this is also
% when the 'expEnd' event signal updates to true.  If the experiment is ended
% normally (i.e. not aborted) then the main loop continues until the
% post-delay has elapsed, at which point the 'experimentEnd' event is
% triggered.
% # Experiment cleanup - After exiting the main loop, the experimentCleanup
% event is triggered and the |cleanup| method is called.  Here the
% 'endDateTime' of the Data struct is set, and all event logs are collated
% and saved into the Data struct.  During cleanup all listeners are
% cleared, textures deleted and various other caches are cleared.  After
% this the Data structure is usually saved to disk and control is returned
% to the calling function (usually |srv.expServer/runExp|).  In the Signals
% Experiment Framework the Signal network persists until the
% Experiment object is explicitly deleted.

%% Notes
% (1) |srv.prepareExp| is called by |srv.expServer| when an expRef is
% received.  It also sets up the <./using_services.html#2 auxillary
% services> and <./Timeline.html Timeline>.
%
% (2) All phase events are recording using the Rig clock, which is in
% absolute seconds.  The Clock is zero'd by |srv.expServer/runExp| as soon
% as it receives an expRef, so all times are relative to that.
% <./clocks.html Click here> for more information on the Clock object.

%% Etc.
% Author: Miles Wells
%
% v0.0.1
%
% <index.html Home> > Experiments > The Experiment Framework
