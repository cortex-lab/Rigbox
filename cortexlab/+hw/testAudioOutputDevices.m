function d = testAudioOutputDevices(varargin)
% HW.TESTAUDIOOUTPUTDEVICES Test available output audio devices
%   D = HW.TESTAUDIOOUTPUTDEVICES(SAVEASDEFAULT) plays white noise through
%   all channels for 2 seconds, for each available output device.  The
%   lowest latency devices are selected first. If the user presses the
%   space bar the current device is returned, which may then be saved into
%   the rig hardware file.  Press any other key to proceed to the next
%   device.
%
%   Input:
%     saveAsDefault (logical): If true, the selected device is saved into
%       the hardware file's audioDevices struct with the device name
%       'default'.
%
%   Output:
%     d (struct): The selected PortAudio output device.
%
%   Examples:
%     % Manually save selected device into hardware file
%     audioDevices = hw.testAudioOutputDevices(); % Select an output device by ear
%     audioDevices.DeviceName = 'default'; % Rename device for easy reference
%     hwPath = getOr(dat.paths, 'rigConfig'); % Get rig hardware file path
%     save(fullfile(hwPath,'hardware'), 'audioDevices', '-append')
%
%     % Automatically save the selected device into the hardware file
%     hw.testAudioOutputDevices('SaveAsDefault', true);
%
% See also PsychPortAudio('GetDevices?')

p = inputParser;
p.addOptional('saveAsDefault', false)
p.parse(varargin{:})

InitializePsychSound
audDevs = PsychPortAudio('GetDevices');
output = [audDevs.NrOutputChannels] > 0; % Find output devices
outputDevs = audDevs(output); % Select only the output audio devices
[~,I] = sort([outputDevs.LowOutputLatency]); % Sort by latency
outputDevs = outputDevs(I);

duration = 2; % How long to play each noise burst for
KbQueueCreate % Prepare for keyboard input

% Open each device and play the noise
for i = 1:length(outputDevs)
  d = outputDevs(i); % Select the next device
  h = []; % Initialize the device handle
  try
    h = aud.open(d.DeviceIndex, d.NrOutputChannels, d.DefaultSampleRate);
    aud.load(h, rand(d.NrOutputChannels, d.DefaultSampleRate*duration));
    fprintf('<strong>Playing noise through device %i (%s)</strong>\n', ...
      d.DeviceIndex, d.DeviceName);
    aud.play(h); % Play the loaded samples
    [~, keys] = KbWait; % Wait for user input
    key = KbName(keys); % Return key press info
    if any(strcmp(key, 'space'))
      break % If <space> was pressed, break loop and return the current device
    end
  catch
  end
  if ~isempty(h), aud.close(h); end % Close the device
end

% Save the selected device into the audioDevices struct of the hardware
% file.
if p.Results.saveAsDefault
  % Turn off unnecessary warning
  orig = warning('off', 'Rigbox:hw:devices:missingHardware');
  mess = onCleanup(@() warning(orig)); % Restore warning on exit
  
  d.DeviceName = 'default'; % Rename device to 'default' for easy reference
  def = fieldnames(d)'; def{2, 1} = {}; % Default to be an empty struct
  % Load the audioDevices from the hardware file, otherwise return empty struct
  audioDevices = getOr(hw.devices([],0), 'audioDevices', struct(def{:}));
  I = strcmp({audioDevices.DeviceName}, 'default'); % Find default device
  if any(I) % default device defined
    audioDevices(I) = d; % Overwrite it with new default device
  else
    audioDevices = [d audioDevices]; % Append our default device
  end
  
  % Save into the hardware file
  hwPath = getOr(dat.paths, 'rigConfig');
  if exist(hwPath, 'dir') == 0 % Rig config folder doesn't yet exist
    fprintf('Creating rig config directory: %s\n', hwPath)
    assert(mkdir(hwPath), 'Failed to create rigConfig directory')
  end
  hwPath = fullfile(hwPath, 'hardware.mat'); % Complete hardware file path
  appendFlag = iff(file.exists(hwPath), {'-append'}, {}); % Append if exists
  fprintf('Saving ''audioDevices'' to %s\n', hwPath)
  save(hwPath, 'audioDevices', appendFlag{:}) % Save to hardware file
end