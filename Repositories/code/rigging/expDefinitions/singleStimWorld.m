function singleStimWorld(t, evts, p, vs, in, out, audio)
%% Very simple exp to test signals
% stimulusOn = evts.newTrial.delay(p.stimulusDelay);
stimOn = evts.newTrial;
stimOff = stimOn.delay(p.stimDelay);

% Stim
stim = vis.grating(t, 'sinusoid', 'none'); % create a full field grating
stim.orientation = 45;
stim.spatialFrequency = 1;
stim.phase = 0;
stim.contrast = 1;
stim.show = stimOn.to(stimOff);
vs.stim = stim;

evts.endTrial = stimOff.delay(5);
end