function tutorial_intro(t, events, pars, visStim, inputs, outputs, audio)
% Signals tutorial
%
% Welcome to Signals! From this point on, it's useful to have the Signals
% documentation open that lists the available methods: 
% type 'doc sig.node.signal'
%
% Signals operates by using objects called signals (a class defined by
% sig.Signals) which have user-defined relationships with each other for
% when and to what values they update. 
%
%% ORIGIN SIGNALS %%
%
% There are a few 'origin' signals, on which all other signals depend.
% Origin signals are set up by exp.SignalsExp and include the following:
%
% t - time, this is a clock that carries time in seconds (note that this is
% the first input argument in a Signals protocol)
%
% events.expStart - sets to 1 at the start of the experiment (note that
% 'events' are the second input argument in a Signals protocol)
%
% events.newTrial - sets to 1 at the start of each new trial
%
% events.trialNum - sets to the trial number at the start of each trial
%
% events.expStop - sets to 1 and the end of the experiment
%
% inputs.wheel - this is the rotary encoder (note that 'inputs' is the
% fifth input argument in a Signals protocol)
%
%% PROTOCOL INPUT ARGUMENTS %%
% Signals protocols are functions defined as 
% signalsProtocol(t, events, pars, visStim, inputs, outputs, audio)
% Note that as with any function, these input arguments can be named
% anything and the only thing that matters is the order (e.g. events could
% be named evts).
%
% Every Signals protocol needs the following input arguments:
% 
% t - This is the time origin signal
%
% events - This is a structure which contains origin signals as described
% above by default, and the user adds new fields in the procol (e.g.
% events.newField). NOTE: the only aspects of a running Signals protocol
% which are saved are in events structure (and these are saved to the Block
% file). This means if you have a signal which is important to know in
% order to do analysis, you MUST package it into the events structure
% somewhere in the protocol (commonly all relevant events are packaged at
% the end of a protocol script). 
%
% pars - These are user defined parameters. MC (the master control program
% that is the wrapper to run signals) will search for pars within each
% script and make those editable values. For example, if 'pars.userValue'
% appears in the protocol script, an editable field called 'userValue'
% will be made available and the signals protocol will use that value to
% run the experiment. 
%
% visStim - This is the handler for visual stimuli that will be described
% later
%
% inputs - These are the hardware inputs that signals receives. As above,
% inputs.wheel is pre-defined
%
% outputs - These are the hardware outputs that signals puts out. As will
% be discussed later, outputs.reward is predefined to control the water
% valve
%
% audio - this is the handler for auditory stimuli that will be described
% later
%
%% DEFINING SIGNALS %%
% 
% The experimental protocol is made by creating new signals which depend on
% the origin signals which can be modified or manipulated by signals
% methods. Signals methods can be called with two syntaxes:
% 1) dependent_signal = independent_signal.method(arguments);
% 2) dependent_signal = method(independent_signal, arguments);
%
% The only signal which is mandatory to define is the end of a trial, which
% needs to be packaged in events.endTrial
% 
% We'll learn our first signal method here: delay
% The delay method creats a new signal which is exactly another signal
% except delayed by a set about of time. We only have origin signals to
% work with at the moment, so let's have the end of our trial be 2 seconds
% after the start of each new trial. Uncomment the following lines, then
% try running 'exp.test' and choosing this protocol: 
% 
% -- UNCOMMENT --
endTrial = events.newTrial.delay(2); % could also write delay(events.newTrial,1)
events.endTrial = endTrial;
% ---------------
% 
% Hopefully you're using the plotting version of test signals which plots
% out signals over time: notice three of the origin signals (expStart,
% newTrial, and trialNum), and our new signal (endTrial). Why do other
% signals (like the origin signal t) not show up? That's because they're
% not packaged into the events structure, so they're not saved or
% displayed. If you wanted to save/display t, you could write events.t = t,
% and it will show up. Also remember that events.endTrial is mandatory: try
% commenting that out and running this protocol, you'll get an error. 
% 
% You'll notice that a new trial starts every 2 seconds now. Leave those
% lines uncommented from now on to keep this as the basis of the protocol.
% 
%% SIGNAL METHODS %%
%
% Let's try adding in some new signals to learn some other common methods.
% Signals can be manipulated by some common matlab functions, a few are
% illustrated below: addition, multiplication, inequality, and modulus
% Uncomment below and check out their signal values as they update
%
% -- UNCOMMENT --
% trial_offset = events.trialNum + 1;
% trial_multiple = events.trialNum * 10;
% trial_over3 = events.trialNum > 3;
% trial_mod2 = mod(events.trialNum,2);
% 
% events.trial_offset = trial_offset;
% events.trial_multiple = trial_multiple;
% events.trial_over3 = trial_over3;
% events.trial_mod2 = trial_mod2;
% ---------------
%
% Now we've got one signal which is the current trial number offset by 1,
% another which is the current trial number multiplied by 10, another which
% is 0 and becomes 1 after trial 4, and another which flips
% between 0 and 1 on every other trial. 
%
% You can re-comment those signals out so we can clear up our plotting. 
%
% We'll look at three more common methods here: skipRepeats, at, and delta
% Let's say we wanted to derive a signal which reported how much time has
% elapsed between every 3 trials. Uncomment below and check out one way
% that we can do this
% 
% -- UNCOMMENT --
% % Create a signal which increases by 1 every 3 trials
% trial_div3 = floor(events.trialNum/3);
% % We only care when that signal changes values and do not want our later
% % signals to update when it reports the same value twice in a row. We'll
% % ignore repeated values with the method 'skipRepeats'
% trial_div3_skipRepeats = trial_div3.skipRepeats;
% % Now we want to report the time that every 3rd trial occurs at. In order
% % to get the value of one signal when another signal changes, we use the
% % method 'at' with the syntax reported_signal.at(changing_signal). [Note
% % that 'at' normally triggers whenever changing_signal changes values, but
% % this DOES NOT apply only when changing_signal becomes 0]
% trial_div3_t = t.at(trial_div3_skipRepeats);
% % Finally, we'll get the difference in time between the last value and the
% % current value for the 3rd trial times (this will always report the same
% % value for us because we set the trial time to be constant).
% trial_div3_t_delta = trial_div3_t.delta;
% 
% events.trial_div3 = trial_div3;
% events.trial_div3_skipRepeats = trial_div3_skipRepeats;
% events.trial_div3_t = trial_div3_t;
% events.trial_div3_t_delta = trial_div3_t_delta;
% ---------------
%
% Note that methods can be stacked, so another more compact way to execute
% the same steps can be seen below (re-comment above, uncomment below)
%
% -- UNCOMMENT --
% trial_div3 = floor(events.trialNum/3);
% trial_div3_t_delta = t.at(skipRepeats(trial_div3)).delta;
% 
% events.trial_div3_t_delta = trial_div3_t_delta;
% ---------------
%
% Re-comment the above, and we'll learn about initializing signals and the
% method 'cond'
% 
% You might have noticed in the plotting window that there were no values
% (and in fact no labels) for trial_div3_t_delta above until the third
% trial was reached. This is because the chain of signals means that
% trial_div3_t_delta is undefined until the third trial. Sometimes this can
% be a problem and cause things to crash depending on signal relationships,
% or other times you just want to set a starting value before it's defined
% otherwise. One way we can do this is with the conditional method 'cond'
% using the syntax dependent_signal = cond(contingency 1, value 1,
% contingency 2, value 2 ...). This sets the value for the first true
% listed contingency. A contingency of 'true' is valid to use to
% essentially establish an 'else' case (but make sure it's last, since it's
% always true). 
% 
% Below, we will make the same signal as before, but we will set the
% default value to 0.
%
% -- UNCOMMENT --
% trial_div3 = floor(events.trialNum/3);
% trial_div3_t_delta = t.at(skipRepeats(trial_div3)).delta;
% trial_div3_t_delta_cond = cond( ...
%     skipRepeats(events.trialNum >= 6), trial_div3_t_delta, ...
%     true, 0);
% 
% events.trial_div3_t_delta = trial_div3_t_delta_cond;
% ---------------
% 
% Try taking out the skipRepeats inside of the conditional.
% Note that now trial_div3_t_delta_cond updates every trial instead of
% tracking only the changes of trial_div3_t_delta. This is because the new
% cond signal is polling the values whenever the conditional statements
% update. So for example on trial 7, events.trialNum >= 6 will update to
% true (from true, because it updates wenever events.trialNum updates), and
% it will set the value to whatever is currently held in
% trial_div3_t_delta.
% 
% It might be worth trying to think of other ways to write the conditional
% above (try having the default condition be set at events.expStart, try
% thinking of different true signals which could be used to set the value):
% a lot of them probably won't work for various reasons and it can be
% useful to try to figure out why.
% 
% Now you can re-comment those signals (but keep the endTrial signal) and
% we'll move on to stimuli.

%% SOUND STIMULI %%
%
% Sound stimuli are handled by the 7th input argument, here called 'audio'.
% Sounds are defined waveforms over time and then passed to 'audio' as a
% signal which is triggered whenever the sound is meant to play. 
%
% Let's start by making a pure tone which will be played 1 second after the
% start of each new trial and last for 200 ms.
%
% -- UNCOMMENT --
% % Define when to start the sound
% soundTrigger = events.newTrial.delay(1);
% % Define necessary parameters of the sound
% audioSampleRate = 192e3;
% toneAmplitude = 0.5;
% toneFreq = 500;
% toneDuration = 0.2;
% % Make the waveform of the tone (this uses a function in burgbox: try
% % running this code outside of signals and make sure to see that it's just
% % a vector that defines a sine wave)
% toneSamples = toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate);
% % This below has two important signals lessons:
% % 1) We have a vector which at the moment is just a double, and we want to
% % convert it into a signal (which is a constant and not dependent on
% % anything). We can do this by using the method 'map', which has the syntax
% % independent_signal.map(@function). This allows a signal to be passed
% % through any matlab function, e.g. t_sin = t.map(@sin) will create a new
% % signal t_sin which is the sine of the origin signal t. We are using 'map'
% % here to convert toneSamples from a double into an object at the start of
% % an experiment. 
% % 2) Signals do not have to have one value at a time: they can be any size.
% % For example, a signal can take on the value [2,2], but note that at the
% % moment this isn't plotted in the plotting tool. Here, the signal
% % toneSamplesSignal is going to have the size length(toneSamples).
% toneSamplesSignal = events.expStart.mapn(@(x) toneSamples);
% % Finally, we will trigger our waveform signal whenever soundTrigger
% % updates, and pass that into the audio handler.
% audio.tone = toneSamplesSignal.at(soundTrigger);
% ---------------
%
% As usual, these things can be condensed while keeping the same
% principles, see another way to execute this below:
%
% -- UNCOMMENT --
% soundTrigger = events.newTrial.delay(1);
% audioSampleRate = 192e3;
% toneAmplitude = 0.5;
% toneFreq = 500;
% toneDuration = 0.2;
% 
% audio.tone = soundTrigger.map(@(x) toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate));
% ---------------
%
% Note that 'audio.tone' that we passed to the audio handler above is an
% arbitrarily chosen name, it can be audio.anything, and in fact multiple
% sounds can be stored in audio.sound1/audio.sound2. Re-comment the above
% and let's make two different sounds:
%
% -- UNCOMMENT --
% soundTrigger1 = events.newTrial.delay(1);
% soundTrigger2 = events.newTrial.delay(1.5);
% 
% audioSampleRate = 192e3;
% toneAmplitude = 0.5;
% toneDuration = 0.2;
% 
% toneFreq1 = 500;
% toneFreq2 = 200;
% 
% audio.tone1 = soundTrigger1.map(@(x) toneAmplitude*aud.pureTone(toneFreq1, toneDuration, audioSampleRate));
% audio.tone2 = soundTrigger2.map(@(x) toneAmplitude*aud.pureTone(toneFreq2, toneDuration, audioSampleRate));
% ---------------
%
% You can re-comment the sound section now.
%
%% VISUAL STIMULI %%
%
% Visual stimuli are handled very similarly to audio stimuli. 
% At the moment there are a set number of available stimuli that are
% generated using the +vis package in signals. Below we will generate a
% gabor and a square which flicker oppositely from each other.
%
% -- UNCOMMENT --
% % Define when the stimuli should be displayed. This illustrates the new
% % method 'to', which is defined a signal which is true when one signal
% % changes until a second signal changes in the syntax signal1.to(signal2)
% stimOnset = events.newTrial;
% stimOffset = events.newTrial.delay(1);
% stimOnOff = stimOnset.to(stimOffset);
% 
% % We will greate the gabor with the signals function vis.grating.
% % Parameters have default values if not explicitely defined, check out
% % vis.grating for the available parameters
% gaborStim = vis.grating(t, 'sinusoid', 'gaussian');
% gaborStim.azimuth = -20;
% % This parameter 'show' we will make a signal which varies with when
% % we want our stimulus to be on and off. Note that any parameters can be
% % constants or signals. 
% gaborStim.show = stimOnOff;
% 
% % Pass our defined stimulus object to the visual stimuli handler
% % Here's another example type of visual stimulus
% rectStim = vis.patch(t, 'rect');
% rectStim.azimuth = 20;
% % We will turn this stimulus on and off opposite to our gabor
% rectStim.show = ~stimOnOff;
% 
% % Pass our defined stimulus objects to the visual stimuli handler
% visStim.gaborStim = gaborStim;
% visStim.rectStim = rectStim;
% ---------------
%
% You can re-comment this section now. 
%
%% WHEEL INPUT %%
% 
% The major (or only, for now) input of signals will be the rotary encoder.
% The signal from the rotary encoder is an origin signal and therefore can
% be used to define other signals. Let's make a visual stimulus which can
% be controlled by the wheel (note that in exp.test the 'wheel' is the
% scroll bar in the GUI).
%
% Try uncommenting the below code and running it. Where's the stimulus??
% This is an instance of a bug from no initialization: the wheel value is
% undefined at some point around the experiment initialization and breaks
% the stimulus. Try fixing this by using 'cond' to initialize the azimuth
% to zero by default (or look below to cheat). Once you have the stimulus
% appearing, you'll now be able to control it's azimuth with the wheel.
%
% -- UNCOMMENT --
% % The wheel is commonly set up as a signal with skipRepeats, though this
% % may not be necessary
% wheel = inputs.wheel.skipRepeats;
% 
% % We will define a visual stimulus, but we will set the azimuth to be
% % controlled by the wheel signal
% stim = vis.grating(t, 'sinusoid', 'gaussian');
% stim.azimuth = wheel;
% stim.show = true;
% 
% visStim.gaborStim = stim;
% ---------------
%
% Re-comment the above. You might have noticed that you could go off-screen
% forever - so let's reset the stimulus position when it reaches a certain
% point. We can conceptually hit one of the weak points in Signals here: it
% is impossible to make co-dependent signals. For example: the stimulus
% azimuth should be reset when it reaches a point, but 
% 
% -- UNCOMMENT --
wheel = inputs.wheel.skipRepeats;
stim = vis.grating(t, 'sinusoid', 'gaussian');

stim_azimuth = wheel - wheel.at(
stim.azimuth = cond( ...
    events.expStart,wheel, ...
    true, 0);

stim.show = true;
visStim.gaborStim = stim;
% ---------------


% THINGS TO COVER HERE:
% what a signal is
% all the inputs to the function:
% t, events, and origin signals
% visual stimulus
% wheel input 
% outputs?
% audio?
% 
% functions:
% sum, modulus
% 
% give the order of later tutorials:
% - time
% - sound
% - visStim
% - contrast visStim
% - flicker visStim
% - stimMove
% - map?
% - stimMoveTrigger (includes keepWhen and setTrigger)?
% - scan
% - params (not made yet)

















