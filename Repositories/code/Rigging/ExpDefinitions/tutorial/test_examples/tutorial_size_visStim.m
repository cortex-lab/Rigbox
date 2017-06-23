function tutorial_size_visStim(t, events, pars, visStim, inputs, outputs, audio)
% Testing visual stimuli in signals

%% Set up wheel 

wheel = inputs.wheel.skipRepeats();

%% Visual stim

% NOTE: this adds 2 values every time, but at the moment this isn't plotted
starting_sigma = [1,3];
sigma = starting_sigma+[(events.trialNum-1)*20,0];

% Define three possible stimuli
stim = vis.grating(t, 'square', 'gaussian');
stim.sigma = sigma;
stim.show = events.newTrial.to(events.newTrial.delay(2));

visStim.stim = stim;

%% Define events to save

events.sigma = sigma;
events.endTrial = events.newTrial.delay(4);













