function d = findDevice()
InitializePsychSound
audDevs = PsychPortAudio('GetDevices');
output = [audDevs.NrOutputChannels] > 0;

outputDevs = audDevs(output);
[~,I] = sort([outputDevs.LowOutputLatency]);
outputDevs = outputDevs(I);

duration = 2;

KbQueueCreate

for i = 1:length(outputDevs)
  d = outputDevs(i);
  h = [];
  try
    h = aud.open(d.DeviceIndex, d.NrOutputChannels, d.DefaultSampleRate);
    aud.load(h, rand(d.NrOutputChannels, d.DefaultSampleRate*duration));
    fprintf('Playing noise through device %i (%s)\n', d.DeviceIndex, d.DeviceName);
    aud.play(h);
    [~, keys] = KbWait;
    key = KbName(keys);
    if any(strcmp(key, 'space'))
      break
    end
  catch
  end
  if ~isempty(h); aud.close(h); end
end