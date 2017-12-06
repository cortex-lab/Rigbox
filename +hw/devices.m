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

% if strcmp(name, 'zen')
%   baseDir = 'D:\Users\Chris\Documents\MATLAB\Experiments';
%   configDir = fullfile(fullfile(baseDir, 'config'), name);
% else
%   baseDir = '\\zserver\code\Rigging';
%   configDir = fullfile(fullfile(baseDir, 'config'), name);
% end
%% Basic initialisation
fn = fullfile(paths.rigConfig, 'hardware.mat');
if ~file.exists(fn)
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

%% Configure common devices, if present
configure('mouseInput');
% configure('rewardController');
configure('lickDetector');
if isfield(rig, 'laser')
  configure('laser', rig.rewardController.DaqSession);
end

%% Deal with reward controller calibrations
% if init && isfield(rig, 'rewardController')
%   if isfield(rig, 'rewardCalibrations')
%     % use most recent reward calibration
%     [newestDate, idx] = max([rig.rewardCalibrations.dateTime]);
%     rig.rewardController.MeasuredDeliveries =...
%       rig.rewardCalibrations(idx).measuredDeliveries;
%     fprintf('\nApplying reward calibration performed on %s\n', datestr(newestDate));
%   else
%     %create an empty structure
%     rig.rewardCalibrations = struct('dateTime', {}, 'measuredDeliveries', {});
%     warning('Rigbox:hw:calibration', 'No reward calibrations found');
%   end
% end

%% Set up controllers
if isfield(rig, 'rewardCalibrations') && isfield(rig, 'rewardController')...
    && ~isfield(rig, 'daqController') &&...
    ~isa(rig.rewardController, 'hw.DummyFeedback')
  % create a daq controller based on legacy rig.rewardController
  rig.daqController = hw.daqControllerForValve(...
      rig.rewardController, rig.rewardCalibrations);
end

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
    InitializePsychSound;
    IsPsychSoundInitialize = true;
  end
  idx = pick(rig, 'audioDevice', 'def', 0);
  rig.audioDevice = PsychPortAudio('GetDevices', [], idx);
  % setup playback audio device - no configurable settings for now
  % 96kHz sampling rate, 2 channels, try to very low audio latency
  rig.audio = aud.open(rig.audioDevice.DeviceIndex,...
  rig.audioDevice.NrOutputChannels,...
  rig.audioDevice.DefaultSampleRate, 1);
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

