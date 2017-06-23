function tutorial_reward(t, events, pars, visStim, inputs, outputs, audio)

outputs.reward = at(3,events.newTrial.delay(0.5));

%% Define events to save
events.endTrial = events.newTrial.delay(1);















