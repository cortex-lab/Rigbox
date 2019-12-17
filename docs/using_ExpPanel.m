%% Introduction
% ExpPanels are panels under the Experiment > Current tab of mc that
% display information about events occuring during an experiment.  This
% document contains information on how to set up an ExpPanel for
% customizing the monitoring of an Experiment.

%% exp.ExpPanel
% The base class for the ExpPanel is the |exp.ExpPanel|.  All subclasses
% chain a call to this class.
%
% When starting a new experiment in MC a new ExpPanel is created by calling
% the static contructor method `live`:
% 
%   p = live(parent, ref, remoteRig, paramsStruct, activateLog)
%   doc eui.ExpPanel/live
% 
% The precise subclass used depends on the `type` parameter in the
% paramsStruct input.  Currently supported types include
% SingleTargetChoiceWorld, ChoiceWorld, DiscWorld, SurroundChoiceWorld
% (|eui.ChoiceExpPanel|); BarMapping (|eui.MappingExpPanel|); custom a.k.a.
% Signals (|eui.SignalsExpPanel|).  
%
% For Signals experiments the default ExpPanel class may be overridden by
% providing a parameter named `expPanelFun` whose value is either a
% function handle or path to the class to be instantiated.  This parameter
% is automatically added in MC if the folder from which the experiment
% function was loaded contains an ExpPanel.  The name must be the same as
% the experiment function but with 'ExpPanel' added, e.g. for
% 'advancedChoiceWorld.m', the corresponding ExpPanel file would be
% 'advancedChoiceWorldExpPanel.m'.

%% Basic layout
% The ExpPanel has the following basic layout:

%%% Title
% The panel title contains the experiment reference and the name of the
% remote rig.  When the experiment is initializing or during the
% cleanup/post-delay phase the title is amber.  During the main experiment
% phase the title turns green and when complete, red.  This title colour
% and other properties are set in the `live` method then subsequently by
% the `event` method.

%%% InfoGrid
% The info grid contains all experiment event labels and their current
% values.  As new events occur they're added to the last via a call to
% addInfoField.  There are 4 default fields:
%
%   Status - The current experimental phase, e.g. 'Pending', 'Complete'.
%     The status is set based on 'ExpUpdate' events from the remote rig
%     (see the `expUpdate` method).
%   Duration - The time elapsed since the experiment began.  This
%     is updated each time the `update` method is called (every 100ms in
%     MC).
%   Trial count - The total number of trials.  This field is updated based
%     on the 'newTrial' ExpUpdate status (see `expUpdate` method).
%   Condition - The current trial condition.  This only appears if
%     `conditionId` parameter is defined.
%
% The fields may be hidden by right-clicking one and selecting 'Hide
% field'.  The hidden fields may be reset by selecting 'Reset hidden'.

%%% CustomPanel
% A container for subclasses to build plots into.  For example in the
% ChoiceWorld Experiment, this contains a psychometric curve plot and the
% trace of the wheel input.  

%%% CommentsBox
% An input field for taking notes.  These are automatically saved to the
% Log (see |dat.logPath|, |dat.logEntries|).  If logged into Alyx the notes
% are also saved to the database session narrative (see
% |Alyx.updateNarrative|).  The comments box may be hidden by
% right-clicking and selecting 'Hide comments'.

%%% ButtonPanel
% A set of buttons for ending/aborting the experiment as well as viewing
% the parameter set.

%% Method call sequence
% TODO

%% exp.SignalsExpPanel
% The subclass, |exp.SignalsExpPanel|, is the default class for Signals
% Experiments.   In this class, all Signals updates are shown as InfoFields
% whose colours pulse green as the values update.  The signals sent from
% the stimulus computer includes events, parameters, inputs and outputs
% signals.  The 'Trial count' field reflects the value of events.trialNum.
% The UpdatesFilter property contains a list of signals updates to create a
% label for, or if Exclude == true, all signals names in this list are
% ignored.  This is useful when your events structure is large and you
% don't wish to see all of them during the experiment.

%% Custom Signals ExpPanels
% TODO Add section on subclassing

%% Notes, etc.
% (*) For plotting more precise timings used updates.timestamp

% Author: Miles Wells
%
% v1.0.0

%#ok<*NOPTS,*ASGLU,*NASGU>
