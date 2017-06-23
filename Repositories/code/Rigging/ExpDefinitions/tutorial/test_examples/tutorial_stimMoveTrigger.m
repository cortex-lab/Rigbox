function tutorial_stimMove(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Set up wheel 
% why is it necessary to do .skipRepeats? does the same if it's not there
wheel = inputs.wheel;

%% Visual stim

% stim_azimuth = wheel - ...
%     cond( ...
%     events.newTrial, wheel.at(events.newTrial), ...
%     true, 0);

%stim_azimuth = wheel; works
%stim_azimuth = wheel - wheel.at(events.newTrial);
%stim_azimuth = wheel.at(events.newTrial); % doesn't display (can't be
% concurrent?)
%stim_azimuth = wheel.at(events.newTrial.identity()); % doesn't work - same
% issue?
%stim_azimuth = wheel.at(events.newTrial.delay(0));% displays stim
stim_azimuth = wheel - wheel.at(events.newTrial.delay(0)); % THIS WORKS!

stim = vis.grating(t, 'square', 'gaussian');
stim.azimuth = stim_azimuth;
stim.show = events.newTrial;

% NOTE: this combination works!
% this is because the wheel isn't defined at the first newTrial
% stim_azimuth = wheel.at(events.newTrial.delay(0.001));
% stim = vis.grating(t, 'square', 'gaussian');
% stim.azimuth = stim_azimuth;
% stim.show = events.newTrial.keepWhen(stim_azimuth);

target_azimuth = 90;
target = vis.patch(t,'rectangle');
target.azimuth = target_azimuth;
target.show = events.newTrial;

% This will trigger it and then keep it on (but the syntax is totally
% weird, it's from the input signal until the conditional, but it returns
% only true/false, not the input signal. so stim_azimuth is used here, but
% note that it doesn't return stim_azimuth values)
trigger = skipRepeats(stim_azimuth.setTrigger(stim_azimuth > 60));
% This will modulate it based on azimuth
% trigger = skipRepeats(cond( ...
%     stim_azimuth > 60, true, ...
%     stim_azimuth <= 60, false));

trigger_stim_azimuth = -90;
trigger_stim = vis.patch(t,'rectangle');
trigger_stim.azimuth = trigger_stim_azimuth;
trigger_stim.show = trigger;

visStim.stim = stim;
visStim.target = target;
visStim.trigger_stim = trigger_stim;

hit_target = ge(stim_azimuth,target_azimuth);


%% Define events to save

events.wheel = wheel;
% This doesn't work: ???
%events.wheel = wheel.at(events.newTrial);
events.trigger = trigger;
events.stim_azimuth = stim_azimuth;
events.endTrial = hit_target.at(hit_target);
% This doesn't work: it updates the trial every time even if it's not true
%events.endTrial = stim_azimuth.ge(target_azimuth);
























