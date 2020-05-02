function rig = devices(name, init)
%HW.DEVICES Returns hardware interfaces configured for rig
%   RIG = HW.DEVICES([NAME, INIT])
%
%   Inputs (Optional):
%     name (char): The name of the rig whose hardware to load.  Default is
%       the current computer's hostname.
%     init (logical): Whether to initialize the hardware.  This includes
%       PsychPortAudio, creating sessions and adding channels on the DAQ
%       devices.  Default is to initialize.
%
%   Output:
%     rig (struct): The configured hardware settings and interfaces.
%
%   Default rig fields:
%     paths (struct): The paths for the rig.
%     name (char): The name of the rig.
%     timeline (hw.Timeline): A timeline object.  If no such object is 
%       saved, a new one is instantiated.
%     clock (hw.Clock): The clock object to use.  Unless timeline is 
%       activated, the PTB clock is used.
%     useDaq (logical): Whether any DAQ devices are active and/or initialized.
%     GitHash (char): The commit of the current Rigbox code.  NB: Requires
%       the repo to have been cloned via Git Bash.
%     daqController (hw.DaqController): A DaqController object.  If no such
%       object is saved, a new one is instantiated.
%     audioDevices (struct): A struct of available audio devices.  If no
%       such object is saved, a new struct is returned using
%       PsychPortAudio('GetDevices').
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
   warning('Rigbox:hw:devices:missingHardware', ...
     ['hardware config not found for hostname ', name]);
   rig = [];
  return
end
rig = load(fn);
rig.name = name;

% If no timeline exists, create one
if ~isfield(rig, 'timeline'), rig.timeline = hw.Timeline; end
% Set the clock depending on whether Timeline is active
useTL = rig.timeline.UseTimeline; % Timeline active flag
rig.clock = iff(useTL, @()hw.TimelineClock(rig.timeline), @()hw.ptb.Clock);
rig.useDaq = pick(rig, 'useDaq', 'def', true);
rig.paths = paths;

%% If Git is installed, determine hash of latest commit to code
getHash = sprintf('git -C "%s" rev-parse HEAD', paths.rigbox);
[status, hash] = system(getHash);
if status == 0, rig.GitHash = strtrim(hash); end

%% Configure common devices, if present
configure('mouseInput');
configure('lickDetector');

%% Set up controllers
% If no daqController exists, create a dummy DaqController
if ~isfield(rig, 'daqController'), rig.daqController = hw.DaqController; end

% If required, set up daq session and add channels
if init && rig.useDaq
    rig.daqController.createDaqChannels();
    sg = rig.daqController.SignalGenerators(1);
    if isprop(sg,'Calibrations')
      newestDate = max([sg.Calibrations.dateTime]);
      fprintf('\nApplying reward calibration performed on %s\n', datestr(newestDate));
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
  % If no 'default' DeviceName present, rename output device with lowest latency
  if ~ismember('default', names)
    outputLatency = [devs.LowOutputLatency];
    outputLatency([devs.NrOutputChannels] == 0) = nan; % output channel mask
    [~,I] = nanmin(outputLatency);
    names{I} = 'default';
  end
  % Assign sanitized names
  for i = 1:length(names)
    devs(i).DeviceName = names{i};
  end
  rig.audioDevices = devs; % Assign to rig object
end

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
