function signals_tutorial_basic(t, events, pars, visStim, inputs, outputs, audio)
% Signals tutorial 2
% 170328 - AP
%
% This tutorial continues from tutorial 1. 
% 
%% Trial contingencies %%
%
% Now that we can use basic signals, let's define an actual task. We'll
% make a movable stimulus and a target, and when the stimulus hits the
% target we will advance the trial and reset the stimulus. 
% 
% -- UNCOMMENT --
% % Set up the wheel
% wheel = inputs.wheel;
% 
% % Define the stimulus azimuth by the offset between the wheel and where the
% % wheel was at the beginning of the trial. Why the delay? Turns out that
% % some things cannot be exactly concurrent with newTrial, so this is one
% % workaround (try getting rid of the delay and see what happens)
% stim_azimuth = wheel - wheel.at(events.newTrial.delay(0));
% 
% % Create the movable stimulus
% stim = vis.grating(t, 'square', 'gaussian');
% stim.azimuth = stim_azimuth;
% stim.show = true;
% 
% % Create the target square
% target_azimuth = 90;
% target = vis.patch(t,'rectangle');
% target.azimuth = target_azimuth;
% % Why isn't this true all the time as well? This is another strange bug:
% % concurrent stimuli can sometimes not display properly. Try setting this
% % value to true and see what happens.
% target.show = events.expStart;
% 
% % Send the stimuli to the visual stimuli handler
% visStim.stim = stim;
% visStim.target = target;
% 
% % Define the 'hit' condition, when the stim hits the target
% hit_target = stim_azimuth >= target_azimuth;
% 
% % When the hit happens, end the trial
% events.endTrial = at(true,hit_target);
% ---------------
%
% Note that there were a few weird bugs in that protocol: this happens a
% decent amount in Signals. It would be great to catch any existing bugs
% and eventually pass them on to be fixed by whoever is working in Signals.
% 
% Re-comment the above example. 
%
% Another way to to trigger events from other events is using the method
% 'setTrigger', which arms a trigger with signal_arm and updates the
% trigger with a true value when signal_release updates, with the syntax
% signal_arm.setTrigger(signal_release). In the below example, a new visual
% stimulus appears on each trial when the movable stimulus moves halfway to
% the target.
%
% -- UNCOMMENT --
% % Set up the wheel
% wheel = inputs.wheel;
% stim_azimuth = wheel - wheel.at(events.newTrial.delay(0));
% 
% % Create the movable stimulus
% stim = vis.grating(t, 'square', 'gaussian');
% stim.azimuth = stim_azimuth;
% stim.show = true;
% 
% % Create the target square
% target_azimuth = 90;
% target = vis.patch(t,'rectangle');
% target.azimuth = target_azimuth;
% target.show = events.expStart;
% 
% % Make a third stimulus: this will appear whenever the movable stimulus
% % moves half-way to the target
% trigger = events.newTrial.setTrigger(stim_azimuth > 45);
% 
% trigger_stim_azimuth = 90;
% trigger_stim = vis.patch(t,'rectangle');
% trigger_stim.azimuth = 90;
% trigger_stim.altitude = 10;
% trigger_stim.dims = [5,5];
% % We want this stimulus to turn on at the trigger and turn off at the start
% % of the next trial
% trigger_stim.show = trigger.to(events.newTrial);
% 
% % Send the stimuli to the visual stimuli handler
% visStim.stim = stim;
% visStim.target = target;
% visStim.trigger_stim = trigger_stim;
% 
% % Define the 'hit' condition, when the stim hits the target
% hit_target = stim_azimuth >= target_azimuth;
% 
% % When the hit happens, end the trial
% events.endTrial = at(true,hit_target);
% events.test = trigger;
% ---------------
%
% Note that the arming signal for the trigger is a new trial,
% so once the trigger is released it cannot be released again until a new
% trial starts. This means that if you move the movable stimulus forward to
% turn on the trigger stimulus, moving the movable stimulus back does not
% turn off the trigger stimulus.
%
% Re-comment the above example.
%
%% UPDATING VARIABLES AND USING STRUCTURES AS SIGNALS %%
% 
% It is often the case that you'd want to execute a function on a value
% which can change over the course of an experiment. In these cases you
% cannot use the 'map' method because the input arguments would not change:
% instead we'll use the 'scan' method which uses updating variables. 
%
% In this example we will make two counters: one each for counting the 
% number of even and odd trials elapsed. Note that this will use a few
% self-contained functions which are at the bottom of this script: when you
% are running these examples, you can debug into these functions and check
% out the values that are passed to them. 
%
% Let's set up a simple timer to progress trials here: uncomment this and
% leave it uncommented throughout this example.
%
% -- UNCOMMENT --
% events.endTrial = events.newTrial.delay(1);
% ---------------
%
% Now we'll make simple counters for even and odd trials using scan. Scan
% has the syntax of updating_signal = input_signal.scan(@function,seed_value),
% which executes @function whenever input_signal updates. @function receives 
% the starting value of seed value, and takes the input argument of
% input_signal whenever input_signal changes. It will be important to note
% later that while mapn can pass any number of input arguments, scan can
% only pass one (whatever's in input_signal), so any relevant values will
% have to be packaged into input_signal.
%
% -- UNCOMMENT --
% % Initialize the value at 0
% oddTrialsInit = 0;
% evenTrialsInit = 0;
% 
% % Whenever there's a new trial, update the value
% oddTrials = events.trialNum.scan(@odd_trial,oddTrialsInit).skipRepeats;
% evenTrials = events.trialNum.scan(@even_trial,evenTrialsInit).skipRepeats;
% 
% % Plot these counters. Watch them in the plotter: each one only updates on
% % it's pertinent trial because of the skipRepeats, even though it would
% % otherwise be queried every trial because it is based on events.trialNum
% % changing values
% events.oddTrials = oddTrials;
% events.evenTrials = evenTrials;
% ---------------
%
% Re-comment the above example.
% 
% The above example works for updating independent values, but it is
% usually the case that whatever you want to update will contain
% co-dependent signals. In this case, you will need to update multiple
% variables simultaneously, which can be made easy to organize in a
% structure. Structures take an extra step to use as signals though, which
% involves calling the method 'subscriptable' which makes it possible to
% access their fields using dots as normal.
%
% -- UNCOMMENT --
% Initialize the structure and values
trials = struct;
trials.odd = 0;
trials.even = 0;

% Currently 'trials' is a structure and not an object. We will use the map
% trick from the first tutorial to convert this into a signal.
initial_trials_signal = events.expStart.map(@(x) trials);

% We will now set up the scan as before, the only difference here is the
% use of the method 'subscriptable' which makes the fields of this
% structure-signal accessible
trials_signal = events.trialNum.scan(@struct_update,initial_trials_signal).subscriptable;

% Plot out the updating values. Note that the dots here (e.g.
% trial_signal.odd) is used to access a field and not a signals method
% because of the 'subscriptable' command above (try omitting it and seeing
% the error when it gets to this step), but we can still use a method in
% this syntax (skipRepeats here)
events.odd = trials_signal.odd.skipRepeats;
events.even = trials_signal.even.skipRepeats;
% ---------------
% 
% If you want to play around to see why 'map' doesn't work here, you can
% use the function below nTrials_struct: this will always pass through the
% initial seed input every time instead of updating each iteration. 
% 
% That's all for the examples, try moving on to signals_tutorial_pong and
% writing pong for Signals. A working example if you get into trouble is
% provided in signals_tutorial_pong_example
%
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These are functions contained and referenced only in this protocol
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function nTrials = odd_trial(nTrials,trialNum)
% Add 1 on every odd numbered trial
nTrials = nTrials + mod(trialNum,2);
end

function nTrials = even_trial(nTrials,trialNum)
% Add 1 on every even numbered trial
nTrials = nTrials + mod(trialNum-1,2);
end

function nTrials_struct = struct_update(nTrials_struct,trialNum)
% Add 1 on even and odd trials respectively
nTrials_struct.odd = nTrials_struct.odd + mod(trialNum,2);
nTrials_struct.even = nTrials_struct.even + mod(trialNum-1,2);
end

function nTrials_struct = struct_update_map(trialNum,nTrials_struct)
% Add 1 on even and odd trials respectively
nTrials_struct.odd = nTrials_struct.odd + mod(trialNum,2);
nTrials_struct.even = nTrials_struct.even + mod(trialNum-1,2);
end









