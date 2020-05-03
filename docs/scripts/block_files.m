%% Working with block files
% Block files are the 'raw' data files produced by Experiments.  They end
% in '_block.mat'.  They are structs that hold all the experiment and trial
% related information.

%% Loading a block file
% Block files are MAT files and can thefore be loaded from their location
% using the MATLAB |load| function, however the Data package contains a
% number of functions for making loading more convenient.  The main
% function is |dat.loadBlock|, which loads and caches a block for a given
% expRef.  For example here is how you can load the most recent experiment
% for the subject 'ALK051':
expRefs = dat.listExps('ALK051');
block = dat.loadBlock(expRefs{end});

%%%
% If there is no block file found for that experiment, an empty array is
% returned.  You can check in advance using the |dat.expExists| function.
% For more information on laoding experiments using the dat package, see
% the 'Loading experiments' section of the <./using_dat_package.html#5 Data
% Package user guide>.  This guide also has information on loading
% parameter and rig information.

%% Basic block structure
% Block files of all major Experiment types have the following fields:
%
% *expRef* - 
% The expRef for that experiment (char).
%
% *rigName* - 
% The name of the stimulus computer which the experiment ran on (char). The
% rig name itself is set in |hw.devices|, and is by default the computer's
% hostname.
%
% *startDateTime* - 
% The start datetime of the experiment as a serial date number (see
% <https://uk.mathworks.com/help/matlab/ref/datenum.html datenum>).  This
% is usually set during experiment initialization, in the Experiment's
% |init| method.
%
% *startDateTimeStr* - 
% The start datetime of the experiment as a date string in the following
% format 'dd-mmm-yyyy HH:MM:SS' (day-month-year hour:minute:second, see
% <https://uk.mathworks.com/help/matlab/ref/datestr.html datestr>).  This
% is usually set during experiment initialization, in the Experiment's
% |init| method.
%
% *endDateTime* - 
% The end datetime of the experiment as a serial date number (see
% <https://uk.mathworks.com/help/matlab/ref/datenum.html datenum>).  This
% is usually set during experiment cleanup, in the Experiment's |cleanup|
% method.
%
% *endDateTimeStr* - 
% The end datetime of the experiment as a date string in the following
% format 'dd-mmm-yyyy HH:MM:SS' (day-month-year hour:minute:second, see
% <https://uk.mathworks.com/help/matlab/ref/datestr.html datestr>).  This
% is usually set during experiment cleanuo, in the Experiments |cleanup|
% method.
%
% *duration* - 
% The duration of the experiment in seconds calculated as the difference
% between startDateTime and endDateTime, i.e. the length of time between
% initialization and cleanup.
%
% *endStatus* - 
% The status of the experiment when ended (char).  There are three options:
%
% # quit - the experiment was ended normally (i.e. the 'End' button was
% pressed in mc, or the quit key was pressed once).  In this situation the
% experiment post-delay was allowed to elapse before cleanup. 
% # abort - the experiment was ended with urgency (i.e. the 'Abort' button
% was pressed in mc, or the quit key was repeatedly pressed).  In this
% situation the post-delay is aborted and the experiment cleanup routine
% happens immediately.
% # exception - an exception was caught during the experiement and the thus
% was ended early.
%
% *exceptionMessage* - 
% The error message of the exception thrown during the experiment (char).
% If no exception occured this field is absent.

%%%
% The main experiment phases are also recorded.  These are in absolute
% seconds according to the <./clocks.html rig Clock>.  These are usually
% relative to when the runExp command was recieved by expSever.  Below is
% brief description of these fields.
%
% *experimentInitTime* - 
% The time in absolute seconds that experiment initialization occured (see
% |exp.Experiment/init|).  We enter the main experiment loop immediately
% after this.
%
% *experimentStartedTime* - 
% The time in absolute seconds that the experiment officially started.  When the
% pre-delay is set to 0 this happens immedietly after initialization.  In
% the Signals Experiment Framework this event triggers the expRef to be
% posted to the expStart event signal.
%
% *experimentEndedTime* - 
% The time in absolute seconds that the experiment officially ended, that
% is, when the quit command was received.  In the Signals Experiment
% Framework this event occurs just after the expEnd event signal updates.
%
% *experimentCleanupTime* - 
% The time in absolute seconds that we exited the main loop and began the
% cleanup routine (see |exp.Experiment/cleanup|).
%
% *stimWindowUpdateTimes* - 
% An array of times in absolute seconds when each Screen flip occured.  See
% Screen Flip? for more details.

%% SignalsExp block structure
% Signals block files can be identified by the presence of an 'expDef'
% field.  Below is an example of a typical Signals block file.
%
%     block = 
%
%       struct with fields:
% 
%                        expDef: 'C:\Users\User\Documents\Github\rigbox\signals\docs\examples\advancedChoiceWorld.m'
%         stimWindowUpdateTimes: [65×1 double]
%         stimWindowRenderTimes: [65×1 double]
%                       rigName: 'desktop-c6p85d3'
%                 startDateTime: 7.3786e+05
%              startDateTimeStr: '06-Mar-2020 13:37:46'
%                     endStatus: 'quit'
%                        expRef: '2020-03-06_1_test'
%            experimentInitTime: 1.3031e+06
%         experimentStartedTime: 1.3031e+06
%           experimentEndedTime: 1.3031e+06
%         experimentCleanupTime: 1.3031e+06
%                        events: [1×1 struct]
%                  paramsValues: [1×6 struct]
%                   paramsTimes: [1.3031e+06 1.3031e+06 1.3031e+06 1.3031e+06 1.3031e+06 1.3031e+06]
%                        inputs: [1×1 struct]
%                       outputs: [1×1 struct]
%                   endDateTime: 7.3786e+05
%                endDateTimeStr: '06-Mar-2020 13:38:03'
%                      duration: 16.3700
%
%
% Below are descriptions of all fields unique to Signals block files.  All
% fields ending in 'Times' (not 'DateTimes') are in absolute seconds.
%
% *expDef* - 
% The full path of the experiment definition function (char).
%
% *stimWindowRenderTimes* - 
% The times at which the textures finished rendering.  Subtracting these
% from the update times will give you the software window update lags.

%%%
% The other fields unique to the Signals block file contain the values and
% timestamps of various signals updates throughout the session.  Generally,
% recorded signals (a.k.a. registries) have two fields associated with
% them: one ending in 'Values' which contains an array of the values that
% signal took, and 'Times' which contains an array of equal length of the
% times in absolute seconds that the signal updated.
%
% *events* - 
% A scalar struct of values and times of the signals subassigned to the
% subscriptable events signal.  The essential events are 'expStart',
% 'expStop', 'newTrial', 'endTrial', 'repeatNum' and 'trialNum'.  Other
% fields may be present depending on the expDef.  To make future analysis
% simpler it is worth keeping the names of your event signals consistent.
%
% *inputs* - 
% A scalar struct of values and times of the input signals.  The essential
% inputs are 'wheel', 'wheelDeg' and 'wheelRad'.  If configured, there may
% also be 'lickDetector' fields (see the <./hardware_config.html#29
% hardware config guide>).  The input signals are the only recorded signals
% to update exactly once per iteration of the main experiment loop and
% therefore looking at the update times of these signals can be
% informative.
%
% *outputs* - 
% A scalar struct of values and times of the signals subassigned to the
% subscriptable outputs signal.  The fieldnames of the outputs typically
% match the ChannelNames property of the daqController object used for that
% experiment. If no outputs were triggered during the experiment this will
% be a struct with no fields.
%
% *paramsValues* -
% A non-scalar struct of all parameter values for each trial.  The length
% of this struct matches the length of block.events.newTrialTimes.  Each
% field is the name of each parameter.  Global parameters are those
% parameters for which all values are equal (e.g.
% |numel(unique([block.paramsValues.rewardKey])) == 1|).
%
% *paramsTimes* - 
% An array of all parameter update times.  Each trial all parameters update
% simultaneously.

%% ChoiceWorld block structure
% ChoiceWorld block files can be identified by the expType field.  Below is
% an example of a typical ChoiceWorld block file.
%
%     block = 
% 
%       struct with fields:
% 
%                          expType: 'ChoiceWorld'
%                            trial: [1×202 struct]
%            stimWindowUpdateTimes: [8885×1 double]
%             stimWindowUpdateLags: [8885×1 double]
%                    startDateTime: 7.3686e+05
%                 startDateTimeStr: '14-Jun-2017 14:39:04'
%                       parameters: [1×1 struct]
%                        endStatus: 'quit'
%             rewardDeliveredSizes: [162×2 double]
%              rewardDeliveryTimes: [1×162 double]
%                          rigName: 'zredone'
%                           expRef: '2017-06-14_2_ALK051'
%               experimentInitTime: 0.2818
%            experimentStartedTime: 0.3033
%              experimentEndedTime: 1.6009e+03
%            experimentCleanupTime: 1.6009e+03
%                      endDateTime: 7.3686e+05
%                   endDateTimeStr: '14-Jun-2017 15:05:45'
%               numCompletedTrials: 201
%                         duration: 1.6007e+03
%             inputSensorPositions: [476057×1 double]
%         inputSensorPositionTimes: [476057×1 double]
%                  inputSensorGain: 2.0309
%                       lickCounts: []
%                   lickCountTimes: []
%
%
% Below are descriptions of all fields unique to ChoiceWorld block files.
% The blocks of other experiment types follow a broadly similar structure.
% All fields ending in 'Times' (not 'DateTimes') are in absolute seconds.
%
% *expType* - 
% The experiment type (char), i.e. the name of the experiment chosen from
% the 'type' dropdown in mc.  Strictly speaking this is the value of the
% 'type' parameter.  For ChoiceWorld experiments this is obviously
% 'ChoiceWorld'.
%
% *inputSensorGain* - 
% The gain of the input with respect to the stimulus (double).  This is a
% multiplier with the units of visual pixles per rotary encoder 'tick'.  In
% ChoiceWorld this is set by the |calibrateInputGain| method of
% |exp.ChoiceWorld|.  It is calculated using the input sensor's
% 'MillimetersFactor' property, the 'visWheelGain' parameter and the visual
% pixel density determined by by the stimViewingModel.
%
% *inputSensorPositions* - 
% An array of absolute values of the input sensor (i.e.
% '<./hardware_config.html#27 mouseInput>' field of the rig object).  
%
% *inputSensorPositionTimes* - 
% The update times in absolute seconds of the input sensor.  The input
% sensor is the only recorded event to update exactly once per iteration of
% the main experiment loop and can therefore be used to determine the
% performance of the experiment.
%
% *lickCounts* - 
% The values recorded from the 'lickDetector' field of the rig object (see
% the <./hardware_config.html#29 hardware config guide>).  If no
% lickDetector is present this is just an empty double.
%
% *lickCountTimes* - 
% The update times in absolute seconds of the lickDetector sensor.  If no
% lickDetector is present this is just an empty double.
%
% *numCompletedTrials* - 
% The total number of completed trials.  The last trial is often incomplete
% if the experiment is ended by the experimenter.  Therefore this value can
% be used to trim the 'trials' struct array.
%
% *parameters* - 
% A copy of the <./glossary.html global parameters> used for this
% experiment.  See the <./Parameters.html Parameters guide> for more info.
%
% *rewardDeliveredSizes* - 
% An array of reward delivery sizes in microlitres.  Related to the
% 'rewardVolume' parameter.
%
% *rewardDeliveryTimes* - 
% An array of reward delivery times in absolute seconds.  That is, the
% times at which the command was sent to the hw.DaqController object.  
%
% *stimWindowUpdateLags* - 
% An array of times in seconds between the stimulus window being
% invalidated and the buffer getting flipped to the screen.
%
% *trial* - 
% A nonscalar struct of times and outcomes for each trial.  Its length is
% equal to or one greater than the value of block.numCompleteTrials.  All
% trial phases and events have fields containing the times in absolute
% seconds that they occured.  For example 'feebackNegativeStartedTime' and
% 'inputThresholdCrossedTime'.  The IDs of some of these events are also
% included (e.g. 'responseMadeID' and 'inputThresholdCrossedID').  The ID
% value maps for these two fields are defined by the 'responseForThreshold'
% and 'responseForNoGo' parameter fields.  The 'feedbackType' is -1 for
% negative and 1 for positive.  Some fields have empty values for some
% trials indicating that this event didn't occur during that trial (e.g.
% 'positiveFeedbackStartedTime' is empty for incorrect trials).
%
% There is also a 'condition' field whose value is a struct of all
% <./glossary.html conditional parameter> values for that trial:
%
%     block.trial(1).condition
% 
%     ans = 
% 
%       struct with fields:
% 
%                 rewardVolume: [2×1 double]
%               visCueContrast: [2×1 double]
%          feedbackForResponse: [3×1 double]
%         repeatIncorrectTrial: 0
%                    repeatNum: 1
%

%% Processing multiple blocks
% Precessing multiple block can be tricky as some experiments may not have
% a block file associated with them, may be of a different type and may
% have very different parameters(1).  There are a few functions availiable
% in Rigbox for filtering block files, which can make the pre-processing
% stage simpler.  Below are some ways to filter and load blocks using
% functional programming tools(2).
%
% List the expRefs for 'subject'.  NB: dat.listExps can also deal is cell
% arrays of subjects. Filter out all experiments that don't have a block
% file.
blockExists = @(r) file.exists(dat.expFilePath(r, 'block', 'master'));
refs = fun.filter(blockExists, dat.listExps(subject));

%%%
% Create a sequence from this list and specify a loader function.  The
% loader function is only called when required, avoiding premature and
% unnecessary loading.  This is also useful when searching for just one
% specific block.  For ChoiceWorld we can filter blocks using
% |dat.loadBlock(ref, 'ChoiceWorld')|.  Below we show how to filter by
% expDef name.
seq = sequence(refs, @dat.loadBlock);

%%%
% Reverse the sequence so that we search most recent experiments first, and
% filter using a function that checks the expDef field.  Note that the
% filter function must return true or false, and gets the output of the
% loader function (in this case the block file, not the ref) as its input.
expDefType = @(b) endsWith(b.expDef, 'advancedChoiceWorld.m');
seq = seq.reverse.filter(expDefType); 
b = seq.first; % Return the most recent advancedChoiceWorld block file

%%%
% We can return all blocks as a cell array with the following command:
blocks = toCell(seq);

%%%
% If we want only the events structures, we can take them using |map|.  
events = catStructs(seq.map(@(b) b.events).toCell); % Return as array of structs

%%%
% Sometimes those last incomplete trials can be a pain.  Let's trim them
% before returning using structfun, which applies a function to every
% field of a struct, and iff, which is like an if-else statement as a
% one-liner.

% If event one greater than endTrialTimes, trim to the length of
% endTrialTimes, otherwise return the array as normal.
trimTrials = @(evts) structfun(@(e) ...
  iff(length(e) == length(evts.endTrialTimes) + 1, ... 
  @() e(1:numel(evts.endTrialTimes)), e), evts, 'uni', 0);
events = seq.map(@(b) b.events).map(trimTrials).toCell; % Return as cell array

%%%
% Say we only want blocks where a certain event was recorded, simply filter
% by that fieldname.  Below is a sophisticated example where we define an
% anonymous function that searches for a given event.  That way we can
% apply this filter for multiple events:
present = @(e) @(b) isfield(b.events.(e));
seq = seq.filter(present('prefDecrease'));

%%%
% Say we want to return the events struct for the first block where the
% parameter 'rewardSize' was less than 3.  We use the function |getOr| to
% ensure that we don't get an error for blocks that don't have this
% parameter.
lowRwd = @(b) getOr(b.paramsValues, 'rewardSize', 4) < 3;
events = seq.filter(lowRwd).map(@(b) b.events).first;

%%%
% |exp.loadBlock| caches the block file each time it's loaded, meaning that
% filtering multiple times doesn't take much time because as long as the block
% file hasn't been modified since the last time it was retrieved, it is
% returned from memory instead of from disk.  When dealing with many blocks
% this can be memory intensive.  You can clear the cache by calling
% |clearCBToolsCache|.  For some of the above examples it may be better to
% filter based on the parameters file, which is smaller and quicker to
% load than the block file.

% Check for advancedChoiceWorld experiments where reward size was below 3:
filterFn = @(p) ...
  any(getOr(p, 'rewardSize', 4) < 3) && ...
  endsWith(getOr(p, 'expDef'), 'advancedChoiceWorld.m');
seq = filter(sequence(refs, @dat.loadParams), filterFn);

%%%
% This will return parameter structs, but we ultimately want the block, so
% lets map using the expRef field:
blocks = seq.map(@(p) p.expRef).map(@dat.loadBlock).toCell();

%% Notes
% (1) One way to mitigate this is to use ALF files instead.  These files are
% processed versions of standard data found in the block files (e.g. new
% trial times, feddback times, etc.) and are quicker to load.  For more
% information see the analysis with ALF files guide.
%
% (2) If you use Signals you may already be familiar with classic functions
% like map.  Most Rigbox functional programming tools can be found in the
% <matlab:doc('fun') +fun package>.

%% Etc.
% Author: Miles Wells
%
% v0.0.2
%
% <index.html Home> > Analysis > Block Files

%#ok<*NASGU>