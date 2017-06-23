function tutorial_sound(t, events, pars, visStim, inputs, outputs, audio)
% 
tone_amplitude = 1;
tone_freq = 500;
tone_duration = 2;
audio_sample_rate = 192e3;

tone_samples = tone_amplitude*events.expStart.map(@(x) aud.pureTone(tone_freq, tone_duration, audio_sample_rate));

noise_duration = 1;
noise_amplitude = 1;
noise_samples = noise_amplitude*events.expStart.map(@(x) randn(2, audio_sample_rate*noise_duration));

audio.tone = tone_samples.at(events.newTrial.delay(1));
audio.noiseBurst = noise_samples.at(events.newTrial.delay(2));


%% Define events to save
events.endTrial = events.newTrial.delay(5);















