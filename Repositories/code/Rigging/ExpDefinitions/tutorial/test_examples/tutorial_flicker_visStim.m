function tutorial_flicker_visStim(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Set up wheel 
wheel = inputs.wheel.skipRepeats();

%% Visual stim

% periodic signal
flicker_period = 0.3;
flicker = map(mod(t,flicker_period)/flicker_period,@round)*90;%t.map(@(x) mod(x,0.2)).map(@(x) round(x))*180;
periodic = 0.5-mod(t,0.5);

% Set stim times
stimOn = events.newTrial.to(events.newTrial.delay(2));
azimuthMove = stimOn.delay(0.5).to(stimOn.delay(1));

% This won't run on a real rig because azimuth undefined in beginning
% IMPORTANT LESSON: signals aren't initialized, this can fuck up the first
% trial and give errors
% azimuth = flicker.keepWhen(azimuthMove);
azimuth = cond( ...
    azimuthMove,flicker.keepWhen(azimuthMove), ...
    events.expStart,0);

% Define three possible stimuli
stim = vis.grating(t, 'square', 'gaussian');
stim.contrast = periodic.keepWhen(stimOn);
stim.azimuth = azimuth;
stim.show = stimOn;

visStim.stim = stim;


%% Define events to save
%events.azimuth = azimuth;
events.flicker = flicker;
events.periodic = periodic;
events.azimuth = azimuth;
events.endTrial = events.newTrial.delay(4);













