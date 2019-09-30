function rig = devices(name, init)
%HW.DEVICES Returns hardware interfaces configured for rig
%   rig = HW.DEVICES([name], [init])
%
% Part of Rigbox

% 2012-11 CB created
% 2013-02 CB modified

global IsPsychSoundInitialize;

if nargin < 1 || isempty(name)
  name = hostname;
end

if nargin < 2
  init = true;
end

paths = dat.paths(name);

%% Basic initialisation
fn = fullfile(paths.rigConfig, 'hardware.mat');
if ~file.exists(fn)
   warning(['hardware config not found for hostname ', hostname]);
   rig = [];
  return
end
rig = load(fn);
rig.name = name;
if isfield(rig, 'timeline')&&rig.timeline.UseTimeline
    rig.clock = hw.TimelineClock(rig.timeline);
else
    rig.clock = hw.ptb.Clock;
end
rig.useDaq = pick(rig, 'useDaq', 'def', true);

%% If Git is installed, determine hash of latest commit to code
[status, hash] = system(sprintf('git -C "%s" rev-parse HEAD',...
  fileparts(which('addRigboxPaths'))));
if status == 0
  rig.GitHash = strtrim(hash);
end

%% Configure common devices, if present
configure('mouseInput');
configure('lickDetector');

%% Set up controllers
if init 
  if isfield(rig, 'daqController')
    rig.daqController.createDaqChannels();
    sg = rig.daqController.SignalGenerators(1);
    if isprop(sg,'Calibrations')
      [newestDate, ~] = max([sg.Calibrations.dateTime]);
      fprintf('\nApplying reward calibration performed on %s\n', datestr(newestDate));
    end
  else
    rig.daqController = hw.DaqController; % create a dummy DaqController
  end
end

%% Audio
if init
  % intialise psychportaudio
  if isempty(IsPsychSoundInitialize) || ~IsPsychSoundInitialize
    InitializePsychSound
    IsPsychSoundInitialize = true;
  end
  % Get list of audio devices
  devs = getOr(rig, 'audioDevices', PsychPortAudio('GetDevices'));
  % Sanitize the names
  names = matlab.lang.makeValidName({devs.DeviceName}, 'ReplacementStyle', 'delete');
  names = iff(ismember('default', names), names, @()[{'default'} names(2:end)]);
  for i = 1:length(names); devs(i).DeviceName = names{i}; end
  rig.audioDevices = devs;
end

rig.paths = paths;

%% Helper function
  function configure(deviceName, usedaq)
    if isfield(rig, deviceName)
      device = rig.(deviceName);
      device.Clock = rig.clock;
      if init && rig.useDaq
        if nargin < 2
          device.DaqSession = daq.createSession('ni');
        else
          device.DaqSession = usedaq;
        end
        device.createDaqChannel();
      end
    end
  end

end
