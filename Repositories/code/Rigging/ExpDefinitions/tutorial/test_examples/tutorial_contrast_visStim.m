function tutorial_contrast_visStim(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Visual stim

% periodic signal
periodic = mod(t,0.5)*2;

% Set stim times
stimOnset = events.newTrial;
stimOffset = stimOnset.delay(2);

% Define three possible stimuli
stim = vis.grating(t, 'sinusoid', 'gaussian');
stim.contrast = periodic.keepWhen(stimOnset.to(stimOffset));
%stim.contrast = periodic.keepWhen(stimOnset.to(stimOffset));

stim.show = stimOnset.to(stimOffset);

visStim.stim = stim;


%% Define events to save
events.endTrial = stimOffset.delay(1);















