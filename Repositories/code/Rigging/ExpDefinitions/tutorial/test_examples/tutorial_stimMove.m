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

visStim.stim = stim;
visStim.target = target;

hit_target = ge(stim_azimuth,target_azimuth);

%% Define events to save

events.wheel = wheel;
% This doesn't work: ???
%events.wheel = wheel.at(events.newTrial);
events.stim_azimuth = stim_azimuth;
events.test = stim_azimuth.ge(target_azimuth);
events.endTrial = hit_target.at(hit_target);
% This doesn't work: it updates the trial every time even if it's not true
%events.endTrial = stim_azimuth.ge(target_azimuth);
























