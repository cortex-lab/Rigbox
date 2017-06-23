function tutorial_visStim(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Visual stim

stimOnset = events.newTrial;
stimOffset = stimOnset.delay(2);

% Define stimulus
stim = vis.grating(t, 'sinusoid', 'gaussian');
stim.show = stimOnset.to(stimOffset);
% visStim.ANYTHING works???!? why????
visStim.stim = stim;


%% Define events to save
events.endTrial = stimOffset.delay(1);















