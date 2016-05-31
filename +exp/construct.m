function construct(useTimelineOverride, bgColour)
%EXP.CONSTRUCT Start the construct
%   TODO
%
% Part of Rigbox

% 2013-06 CB created

%% Parameters
quitKey = KbName('q');
rewardToggleKey = KbName('w');
rewardPulseKey = KbName('space');
rewardCalibrationKey = KbName('m');
timelineToggleKey = KbName('t');
useTimeline = false;
rewardId = 1;

%% Initialisation
% communicator for receiving commands from clients
communicator = io.WSCommunicator.server;
communicator.open();

% set PsychPortAudio verbosity to warning level
oldPpaVerbosity = PsychPortAudio('Verbosity', 2);
Priority(1); % increase thread priority level

% OpenGL
InitializeMatlabOpenGL;

% listen to keyboard events
KbQueueCreate();
KbQueueStart();

% get rig hardware
rig = hw.devices;

cleanup = onCleanup(fun.run(...
  @ShowCursor,...
  @KbQueueRelease,...
  @() rig.stimWindow.close(),...
  @() communicator.close(),...
  @() aud.close(rig.audio),...
  @() Priority(0),... %set back to normal priority level
  @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
  ));

HideCursor();

if nargin < 2
  bgColour = 127*[1 1 1];
end
% open the stimulus window
rig.stimWindow.BackgroundColour = bgColour;
rig.stimWindow.open();

fprintf('\nStarted experiment service:\n');
fprintf('<q> quit, <w> toggle reward, <t> toggle timeline\n');
fprintf('<%s> reward pulse, <%s> perform reward calibration\n',...
  KbName(rewardPulseKey), KbName(rewardCalibrationKey));

if nargin < 1 || isempty(useTimelineOverride)
  % toggle use of timeline according to rig default setting
  toggleTimeline(rig.useTimeline);
else
  toggleTimeline(useTimelineOverride);
end

running = true;

%% Main loop for service
while running
  % check for new messages from the connected client
  if communicator.IsMessageAvailable
    % process the new message
    [msgid, message, host] = communicator.receive;
    if strcmp(msgid, 'goodbye')
      % client disconnected
      log('''%s'' disconnected', host);
    else
      command = message{1};
      args = message(2:end);
      if ~strcmp(command, 'status')
        log the command received
        log(sprintf('Received ''%s''', command));
      end
      switch command
        case 'status'
          % status request
          communicator.send(msgid, {'idle'});
        case 'run'
          % exp run request
          [expRef, preDelay, postDelay] = args{:};
          if dat.expExists(expRef)
            log('Starting experiment ''%s''', expRef);
            communicator.send(msgid, []);
            try
              runExp(expRef, preDelay, postDelay);
              log('Experiment ''%s'' completed', expRef);
              communicator.send('status', {'completed', expRef});
            catch runEx
              communicator.send('status', {'expException', expRef, runEx.message});
              log('Exception during experiment ''%s'' because ''%s''', expRef, runEx.message);
              rethrow(runEx);%rethrow for now to get more detailed error handling
            end
          else
            log('Failed because experiment ref ''%s'' does not exist', expRef);
            communicator.send(msgid, {'fail', expRef,...
              sprintf('Experiment ref ''%s'' does not exist', expRef)});
          end
      end
    end
  end
  % listen for connection attempts from clients
  %       log(sprintf('Connection made from: %s', communicator.RemoteHost));
  
  [~, firstPress] = KbQueueCheck;
% firstPress = @(~) false;
  
  % check if the quit key was pressed
  if firstPress(quitKey) > 0
    log('Quitting (quit key pressed)');
    running = false;
  end
  
  % check if the quit key was pressed
  if firstPress(timelineToggleKey) > 0
    toggleTimeline();
  end
  
  % check for reward toggle
  if firstPress(rewardToggleKey) > 0
    log('Toggling reward valve');
    curr = rig.daqController.Value(rewardId);
    sig = rig.daqController.SignalGenerators(rewardId);
    if curr == sig.OpenValue
      rig.daqController.Value(rewardId) = sig.ClosedValue;
    else
      rig.daqController.Value(rewardId) = sig.OpenValue;
    end
  end
  
  % check for reward pulse
  if firstPress(rewardPulseKey) > 0
    log('Delivering default reward');
    def = [rig.daqController.SignalGenerators(rewardId).DefaultCommand];
    %     def = rewardSig.DefaultCommand;
    rig.daqController.command(def);
  end
  
  % check for reward calibration
  if firstPress(rewardCalibrationKey) > 0
    log('Performing a reward delivery calibration');
    calibrateWaterDelivery();
  end
  
  if firstPress(KbName('1')) > 0
    rewardId = 1;
  end
  if firstPress(KbName('2')) > 0
    rewardId = 2;
  end
  
  % pause a little while to allow other OS processing
  pause(5e-3);
end

%% Helper functions
  function runExp(expRef, preDelay, postDelay)
    % disable ptb keyboard listening
    KbQueueRelease();
    
    rig.stimWindow.flip(); % clear the screen before
    
    if useTimeline
      %start the timeline system
      tl.start(expRef, 'rotaryEncoder');
    else
      %otherwise using system clock, so zero it
      rig.clock.zero();
    end
    
    % run the experiment
    srv.runExp(expRef, rig, preDelay, postDelay, communicator);
    rig.stimWindow.BackgroundColour = bgColour;
    rig.stimWindow.flip(); % clear the screen after
    
    if useTimeline
      %stop the timeline system
      tl.stop();
    end
    
    % re-enable ptb keyboard listening
    KbQueueCreate();
    KbQueueStart();
  end

  function calibrateWaterDelivery()
    daqController = rig.daqController;
    chan = daqController.ChannelNames(rewardId);
    %perform measured deliveries
    rig.scale.init();
    calibration = hw.calibrate(chan, daqController, rig.scale, 40e-3, 200e-3);
    rig.scale.cleanup();
    %different delivery durations appear in each column, repeats in each row
    %from the data, make a measuredDelivery structure
    ul = [calibration.volumeMicroLitres];
    log('Delivered volumes ranged from %.1ful to %.1ful', min(ul), max(ul));
    
    %     rigData = load(fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat'));
    rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
    
    save(rigHwFile, 'daqController', '-append');
    %     disp('TODO: implement saving');
    %save the updated rewardCalibrations struct
    %     save(, 'rewardCalibrations', '-append');
    %apply the calibration to rewardcontroller
    %     rig.rewardController.MeasuredDeliveries = calibration;
    %     log('Measured deliveries for reward calibrations saved');
  end

  function log(varargin)
    message = sprintf(varargin{:});
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    fprintf('[%s] %s\n', timestamp, message);
  end

  function setClock(user, clock)
    if isfield(rig, user)
      rig.(user).Clock = clock;
    end
  end

  function t = toggleTimeline(enable)
    if nargin < 1
      enable = ~useTimeline;
    end
    if ~enable
      useTimeline = false;
      clock = hw.ptb.Clock; % use psychtoolbox clock
    else
      useTimeline = true;
      clock = hw.TimelineClock; % use timeline clock
    end
    rig.clock = clock;
    cellfun(@(user) setClock(user, clock),...
      {'mouseInput', 'rewardController', 'lickDetector'});
    
    t = useTimeline;
    if enable
      log('Use of timeline enabled');
    else
      log('Use of timeline disabled');
    end
  end
end