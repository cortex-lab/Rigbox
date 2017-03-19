function [ handlers ] = basicWorldEventHandlers(bgCueDelay, trialDelay,...
  quiescentPeriod, stimOnsetDelay, cueInteractiveDelay, holdWatch,...
  responseWindow, posFeedbackPeriod, negFeedbackPeriod, hideCueDelay)
%EXP.BASICWORLDEVENTHANDLERS Basic stimulus-response experiment structure
%   Creates a set of event handlers for a basic stimulus-response-feedback
%   experiment.
%
% Part of Cortex Lab Rigbox customisations

% 2012-10 CB created

if nargin < 1 || isempty(bgCueDelay)
  bgCueDelay = 0.3;
end

if nargin < 2 || isempty(trialDelay)
  trialDelay = 0;
end

if nargin < 3 || isempty(quiescentPeriod)
  quiescentPeriod = 3;
end

if nargin < 4 || isempty(stimOnsetDelay)
  stimOnsetDelay = false;
end

if nargin < 5 || isempty(cueInteractiveDelay)
  cueInteractiveDelay = false;
end

if nargin < 6
  holdWatch = false;
end

if nargin < 7
  responseWindow = inf;
end

if nargin < 8
  posFeedbackPeriod = 1;
end

if nargin < 9
  negFeedbackPeriod = 2;
end

if nargin < 10
  hideCueDelay = inf;
end

%If not already, convert quiescentPeriod to an appropriate TimeSampler
quiescentPeriod = exp.TimeSampler.using(quiescentPeriod);

handlers = [];

%% When the experiment first starts running, begin a trial
h = exp.EventHandler('experimentStarted', exp.StartTrial);
h.InvalidateStimWindow = true; % make sure the first frame gets drawn
handlers = [handlers, h];

%% When a trial starts running, start the intermission before stimuli
h = exp.EventHandler('trialStarted', exp.StartPhase('intermission'));
handlers = [handlers, h];

%% When a trial starts running, carry out trial preparations
%This includes:
% - begin a quiescence watch (i.e. trigger an event after specified period
%   of no input)
% - calling the prepareStim function (e.g. to prepare textures etc)
% - load the 'onsetTone' onto audio device ready for playback
h = exp.EventHandler('trialStarted');
%Callback to initiate a quiescence period (i.e. period of no input) watch
%The period required will be drawn from the quiescentPeriod sampler
h.addCallback(@(info, due) startQuiescenceWatch(...
  info.Experiment, 'quiescent', quiescentPeriod.secs));
%Callback to call experiment's prepareStim function
h.addCallback(@(info, due) prepareStim(info.Experiment));
%Action to load onsetTone samples, using the conditional amplitude
%parameter
h.addAction(exp.LoadSound('onsetToneSamples', 'onsetToneRelAmp'));
%Use a zero, rather than false delay, so that this will not execute
%chained to previous handlers (as this prolonged operation may potentially
%hold up screen updates)
h.Delay = 0;
handlers = [handlers, h];

%% End intermission after a quiescent period
% stimuli phases
h = exp.EventHandler('quiescentEpoch', exp.EndPhase('intermission'));
h.Delay = false;
handlers = [handlers, h];

%% Play loaded sound immediately when intermission ends
%The samples played will be the last samples loaded (using the loadSound
%function), presumably during prepareStim. This sound event is recorded as
%'onsetTone'.
h = exp.EventHandler('intermissionEnded', exp.PlaySound('onsetTone', false));

if stimOnsetDelay < 0
  h.Delay = abs(stimOnsetDelay); %...configurable delay
else
  h.Delay = false; %...configurable delay
end
handlers = [handlers, h];

%% Start stimulus-background after auditory cue begins
%If no tone->stim delay is required, begin stimulusBackground immediately
%following intermissionEnded. Otherwise wait for the tone started event,
%and begin stimulusBackground after specified delay.
%TODO: for more accurate presentation we should time the auditory tone
%to play relative to the next graphics sync time
% if stimOnsetDelay > 0
h = exp.EventHandler('onsetToneSoundPlayed', exp.StartPhase('stimulusBackground'));
h.Delay = stimOnsetDelay; %...configurable delay
% else
%   h = exp.EventHandler('intermissionEnded', exp.StartPhase('stimulusBackground'));
%   h.Delay = false; %...configurable delay
% end
%Request that the stimulus window gets marked invalid
h.InvalidateStimWindow = true;
handlers = [handlers, h];

%% Start stimulus-cue after intermission ends
h = exp.EventHandler('stimulusBackgroundStarted', exp.StartPhase('stimulusCue'));
%request that the stimulus window gets invalidated
h.InvalidateStimWindow = true;
h.Delay = bgCueDelay; %...configurable delay
handlers = [handlers, h];

%% Start interactive after stimulus-cue starts
if holdWatch
  %If not already, convert cueInteractiveDelay to an appropriate TimeSampler
  cueInteractiveDelay = exp.TimeSampler.using(cueInteractiveDelay);
  % start watch for no movement (hold period)
  h = exp.EventHandler('stimulusBackgroundStarted');
  h.addCallback(@(info, due) startQuiescenceWatch(...
    info.Experiment, 'hold', cueInteractiveDelay.secs));
  handlers = [handlers, h];
  % if hold period met, begin interactive
  interactive = exp.EventHandler('holdEpoch', exp.StartPhase('interactive'));
  handlers = [handlers, interactive];
%   % if hold period violated (i.e. movement during it), abort trial
%   h = exp.EventHandler('holdMovement');
%   h.addCallback(@(info, due) abortPendingHandlers(info.Experiment));
%   h.addAction({exp.EndPhase('stimulusBackground') exp.EndPhase('stimulusCue') exp.EndTrial});
%   h.Delay = false;
%   handlers = [handlers, h];
else
  % just start interactive after cueInteractiveDelay
  h = exp.EventHandler('stimulusBackgroundStarted', exp.StartPhase('interactive'));
  h.Delay = cueInteractiveDelay; %...configurable delay
  handlers = [handlers, h];
end

%% Hide stimulus cue after 
if isfinite(hideCueDelay)
  h = exp.EventHandler('stimulusBackgroundStarted', exp.EndPhase('stimulusCue'));
  %request that the stimulus window gets invalidated
  h.InvalidateStimWindow = true;
  h.Delay = hideCueDelay;
  handlers = [handlers, h];
end

%% When response window is expired, register as a no go 'response'
if isfinite(responseWindow)
  nogo = exp.EventHandler('interactiveStarted');
  nogo.Delay = responseWindow;
  nogo.addAction(exp.EndPhase('interactive'),...
    exp.RegisterNoGoResponse);
  %request that the stimulus window gets invalidated
  nogo.InvalidateStimWindow = true;
  handlers = [handlers, nogo];
end

%% When input threshold is crossed, end interactive and register it as a response
%the 'inputThresholdCrossed' event is specific to LIARExperiment
h = exp.EventHandler('inputThresholdCrossed');
if isfinite(responseWindow)
  % cancel the nogo window timer since a response was made
  h.addCallback(@(info, due) abortPendingHandlers(info.Experiment, nogo));
end
h.addAction(exp.EndPhase('interactive'), exp.RegisterThresholdResponse);
handlers = [handlers, h];

%% When response is made, begin positive or negative feedback as appropriate
h = exp.EventHandler('responseMade');
h.addAction(exp.StartPhase('feedback'), exp.StartResponseFeedback);
handlers = [handlers, h];

%% Leave feedback after a time dependent on positive or negative state
% Postive (e.g. to trigger water delivery):
h = exp.EventHandler('feedbackPositiveStarted');
h.Delay = posFeedbackPeriod; % seconds
h.addAction(exp.EndPhase('feedbackPositive'), exp.EndPhase('feedback'));
handlers = [handlers, h];

% Negative (e.g. to play noise burst):
h = exp.EventHandler('feedbackNegativeStarted');
h.Delay = negFeedbackPeriod; % seconds
h.addAction(exp.EndPhase('feedbackNegative'), exp.EndPhase('feedback'));
handlers = [handlers, h];

%% Upon leaving feedback, clear stimuli and end the trial
h = exp.EventHandler('feedbackEnded');
h.addAction(exp.EndPhase('stimulusCue'), exp.EndPhase('stimulusBackground'), exp.EndTrial);
%request that the stimulus window gets invalidated
h.InvalidateStimWindow = true;
handlers = [handlers, h];

%% Start a new trial when the previous
h = exp.EventHandler('trialEnded', exp.StartTrial);
h.Delay = trialDelay; %...configurable delay
handlers = [handlers, h];

end

