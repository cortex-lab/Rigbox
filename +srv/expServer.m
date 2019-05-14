function expServer(varargin)
%SRV.EXPSERVER sets up and runs stimulus presentation on the stimulus server 
%   This function sets up the stimulus server to receive communication from
%   the master computer, via a tcp/ip java websocket. This function then 
%   runs the experiment on the stimulus server. Optional name-value paired
%   input arguments can be used (see examples below).

%
% Inputs (optional):
%   'bgColour': a 3-element array specifying the background colour of the
%   screens presenting the visual stimuli. 8-bit precision (element values
%   can range from 0-255). Default: [127 127 127] % gray 
%   
%   'runTimeline': a logical flag specifying whether or not to run
%   hw.timeline during the experiment. Default: 1 % run timeline
%
%   'hideCursor': a logical flag specifying whether or not to disable 
%   MATLAB interaction during the experiment. Default: 1 % disable MATLAB
%   interaction
%
% Key bindings:
%   't' - Toggle Timeline on and off.  The default state is defined in the
%     hardware file but may be overridden as the first input argument.
%   'w' - Toggle reward on and off.  This switches the output of the first
%     DAQ output channel between its 'high' and 'low' state.  The
%     specific DAQ channel and its default state are set in the hardware
%     file.
%   'space' - Deliver default reward, specified by the DefaultCommand
%     property in the hardware.mat file.
%   'm' - Perform water calibration.
%   'b' - Toggle the background color between the default and white.
%   'g' - Perform gamma correction
%
% Examples:
%   % Run expServer with default input arg values:
%   srv.expServer;
%
%   % Run expServer with a black background, disabled timeline, and enabled
%   % MATLAB interaction
%   srv.expServer('bgColour', [255 255 255], 'runTimeline', 0, ...
%   'hideCursor', 0);
%
% See also: io.WSJCommunicator, srv.prepareExp, hw.devices, hw.Timeline
% 
% Part of Rigbox

% 2013-06 CB created

%% Initialisation

% initialise global vars for use by openGL in PTB
global AGL GL GLU %#ok<NUSED> 

% initialise keyboard hotkeys
quitKey = KbName('q');
rewardToggleKey = KbName('w');
rewardPulseKey = KbName('space');
rewardCalibrationKey = KbName('m');
gammaCalibrationKey = KbName('g');
timelineToggleKey = KbName('t');
toggleBackground = KbName('b');
rewardId = 1;

% Pull latest changes from remote
%git.update();

% random seed random number generator
rng('shuffle');

% set-up "communicator" for receiving commands from 'MC' via TCP/IP
% listen port
listenPort = io.WSJCommunicator.DefaultListenPort;
communicator = io.WSJCommunicator.server(listenPort);

% create a listener for "communicator" which runs 'handleMessage' when a
% message is received from 'MC'.
listener = event.listener(communicator, 'MessageReceived',...
  @(~,msg) handleMessage(msg.Id, msg.Data, msg.Sender));
communicator.EventMode = false;
communicator.open(); % open the connection

% initialise "experiment" to hold the experiment that will be run
experiment = [];

% set PsychPortAudio verbosity to warning level
oldPpaVerbosity = PsychPortAudio('Verbosity', 2);
Priority(1); % increase thread priority level

InitializeMatlabOpenGL;

% listen to keyboard events
KbQueueCreate();
KbQueueStart();

% get rig hardware
try
  rig = hw.devices;
catch ME
  fun.applyForce({
  @() communicator.close(),...
  @() delete(listener),...
  @KbQueueRelease,...
  @() Screen('CloseAll'),...
  @() PsychPortAudio('Close'),...
  @() Priority(0),... %set back to normal priority level
  @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
  });
  rethrow(ME)
end

cleanup = onCleanup(@() fun.applyForce({
  @() communicator.close(),...
  @() delete(listener),...
  @ShowCursor,...
  @KbQueueRelease,...
  @() rig.stimWindow.close(),...
  @() aud.close(rig.audio),...
  @() Priority(0),... %set back to normal priority level
  @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
  }));

%% Get/Set Input Args

% define default input args:
argsStruct.bgColour = [127 127 127]; % gray 
argsStruct.runTimeline = 1; % use timeline
argsStruct.hideCursor = 1; % hide cursor

% get input args, reshape into two rows (into name-value pairs): 
% 1st row = arg names, 2nd row = arg values 
pairedArgs = reshape(varargin,2,[]);

% if the name-value pairs don't match up, throw error
if ~all(cellfun(@ischar, (pairedArgs(1,:)))) ||... 
    ~all(cellfun(@isnumeric, (pairedArgs(2,:)))) ||...
    mod(length(varargin),2)
  error(['If using input arguments, %s requires them to be constructed '... 
    'in name-value pairs'], mfilename);
end

% for the specified input args, change default input args to new values 
for pair = pairedArgs
  argName = pair{1};
  if any(strcmpi(argName, fieldnames(argsStruct)))
    argsStruct.(argName) = pair{2};
  end
end

if argsStruct.hideCursor % then disable MATLAB interaction
  HideCursor();
end

if argsStruct.runTimeline % then run timeline
  toggleTimeline(rig.timeline.UseTimeline);
else % don't run timeline
  toggleTimeline(useTimelineOverride);
end

% set screen(s) background colour
bgColour = argsStruct.bgColour;
rig.stimWindow.BackgroundColour = bgColour;
rig.stimWindow.open();

fprintf('\n<q> quit, <w> toggle reward, <t> toggle timeline\n');
fprintf(['<%s> reward pulse, <%s> perform reward calibration\n' ...
  '<%s> perform gamma calibration\n'], KbName(rewardPulseKey), ...
  KbName(rewardCalibrationKey), KbName(gammaCalibrationKey));
log('Started presentation server on port %i', listenPort);

running = true;

%% Main loop for service
while running
  % Check for messages when out of event mode
  if communicator.IsMessageAvailable
    [msgid, msgdata, host] = communicator.receive();
    handleMessage(msgid, msgdata, host);
  end

  [~, firstPress] = KbQueueCheck;
  
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
    rig.daqController.command(def);
  end
  
  % check for reward calibration
  if firstPress(rewardCalibrationKey) > 0
    log('Performing a reward delivery calibration');
    calibrateWaterDelivery();
  end
  
  % check for gamma calibration
  if firstPress(gammaCalibrationKey) > 0
      log('Performing a gamma calibration');
      calibrateGamma();
  end
  
  if firstPress(toggleBackground) > 0
      log('Changing background to white');
      whiteScreen();
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
ShowCursor();

%% Helper functions
  function handleMessage(id, data, host)
    if strcmp(id, 'goodbye')
      % client disconnected
      log('''%s'' disconnected', host);
    else
      command = data{1};
      args = data(2:end);
      if ~strcmp(command, 'status')
        % log the command received
        log(sprintf('Received ''%s''', command));
      end
      switch command
        case 'status'
          % status request
          if isempty(experiment)
            communicator.send(id, {'idle'});
          else
            communicator.send(id, {'running' experiment.Data.expRef});
          end
        case 'run'
          % exp run request
          [expRef, preDelay, postDelay, AlyxInstance] = args{:};
          % assert that experiment not already running
          if ~isempty(experiment)
            failMsg = sprintf(...
              'Failed because another experiment (ref ''%s'') running', ...
              experiment.Data.expRef);
            log(failMsg);
            communicator.send(id, {'fail', expRef, failMsg});
            return
          end
          if isempty(AlyxInstance); AlyxInstance = Alyx('',''); end
          AlyxInstance.Headless = true; % Supress all dialog prompts
          if dat.expExists(expRef)
            log('Starting experiment ''%s''', expRef);
            communicator.send(id, []);
            try
              communicator.send('status', {'starting', expRef});
              aborted = runExp(expRef, preDelay, postDelay, AlyxInstance);
              log('Experiment ''%s'' completed', expRef);
              communicator.send('status', {'completed', expRef, aborted});
            catch runEx
              communicator.send('status', {'expException', expRef, runEx.message});
              log('Exception during experiment ''%s'' because ''%s''', expRef, runEx.message);
              rethrow(runEx);%rethrow for now to get more detailed error handling
            end
          else
            log('Failed because experiment ref ''%s'' does not exist', expRef);
            communicator.send(id, {'fail', expRef,...
              sprintf('Experiment ref ''%s'' does not exist', expRef)});
          end
        case 'quit'
          if ~isempty(experiment)
            immediately = args{1};
            AlyxInstance = iff(isempty(args{2}), Alyx('',''), args{2});
            AlyxInstance.Headless = true;
            if immediately
              log('Aborting experiment');
            else
              log('Ending experiment');
            end
            if ~isempty(AlyxInstance)&&isempty(experiment.AlyxInstance)
              experiment.AlyxInstance = AlyxInstance;
            end
            experiment.quit(immediately);
            send(communicator, id, []);
          else
            log('Quit message received but no experiment is running\n');
          end
        case 'updateAlyxInstance' %recieved new Alyx Instance from Stimulus Control
            AlyxInstance = iff(isempty(args{1}), Alyx('',''), args{1});
            AlyxInstance.Headless = true;
            if ~isempty(AlyxInstance)
              experiment.AlyxInstance = AlyxInstance; %set property for current experiment
            end
            send(communicator, id, []); %notify Stimulus Controllor of success
      end
    end
  end

  function aborted = runExp(expRef, preDelay, postDelay, Alyx)
    % disable ptb keyboard listening
    KbQueueRelease();
    
    rig.stimWindow.flip(); % clear the screen before
    
    if rig.timeline.UseTimeline
      %start the timeline system
      if isfield(rig, 'disregardTimelineInputs') % TODO Depricated, use hw.Timeline.UseInputs instead
        [~, idx] = intersect(rig.timeline.UseInputs, rig.disregardTimelineInputs);
        rig.timeline.UseInputs(idx) = [];
      else
        % turn off rotary encoder recording in timeline by default so
        % experiment can access it
        idx = ~strcmp('rotaryEncoder', rig.timeline.UseInputs);
        rig.timeline.UseInputs = rig.timeline.UseInputs(idx);
      end
      rig.timeline.start(expRef, Alyx);
    else
      %otherwise using system clock, so zero it
      rig.clock.zero();
    end
    
    % prepare the experiment
    params = dat.expParams(expRef);
    experiment = srv.prepareExp(params, rig, preDelay, postDelay,...
      communicator);
    communicator.EventMode = true; % use event-based callback mode
    experiment.AlyxInstance = Alyx; % add Alyx Instance
    experiment.run(expRef); % run the experiment
    communicator.EventMode = false; % back to pull message mode
    aborted = strcmp(experiment.Data.endStatus, 'aborted');
    % clear the active experiment var
    experiment.delete()
    experiment = [];
    rig.stimWindow.BackgroundColour = bgColour;
    rig.stimWindow.flip(); % clear the screen after
    
    % save a copy of the hardware in JSON
    hwInfo = dat.expFilePath(expRef, 'hw-info', 'master', 'json');
    fid = fopen(hwInfo, 'w');
    fprintf(fid, '%s', obj2json(rig));
    fclose(fid);
    if ~strcmp(dat.parseExpRef(expRef), 'default')
      try
        Alyx.registerFile(hwInfo);
      catch ex
        warning(ex.identifier, 'Failed to register hardware info: %s', ex.message);
      end
    end

    if rig.timeline.UseTimeline
      %stop the timeline system
      rig.timeline.stop();
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
    calibration = hw.calibrate(chan, daqController, rig.scale, 20e-3, 150e-3);
    rig.scale.cleanup();
    %different delivery durations appear in each column, repeats in each row
    %from the data, make a measuredDelivery structure
    ul = [calibration.volumeMicroLitres];
    log('Delivered volumes ranged from %.1ful to %.1ful', min(ul), max(ul));
    
    %     rigData = load(fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat'));
    rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
    
    save(rigHwFile, 'daqController', '-append');
  end

  function whiteScreen()
    rig.stimWindow.BackgroundColour = 255;
    rig.stimWindow.flip();
    rig.stimWindow.BackgroundColour = bgColour;
  end

  function calibrateGamma()
    stimWindow = rig.stimWindow;
    DaqDev = rig.daqController.DaqIds;
    lightIn = 'ai0'; % defaults from hw.psy.Window
    clockIn = 'ai1';
    clockOut = 'port1/line0 (PFI4)';
    log(['Please connect photodiode to %s, clockIn to %s and clockOut to %s.\r'...
        'Press any key to contiue\n'],lightIn,clockIn,clockOut);
    pause; % wait for keypress
    stimWindow.Calibration = stimWindow.calibration(DaqDev); % calibration
    pause(1);
    saveGamma(stimWindow.Calibration);
    stimWindow.applyCalibration(stimWindow.Calibration);
    clear('lightIn','clockIn','clockOut','cal');
    log('Gamma calibration complete');
  end

  function saveGamma(cal)
      rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
      stimWindow = load(rigHwFile,'stimWindow');
      stimWindow = stimWindow.stimWindow;
      stimWindow.Calibration = cal;
      save(rigHwFile, 'stimWindow', '-append');
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
      enable = ~rig.timeline.UseTimeline;
    end
    if ~enable
      rig.timeline.UseTimeline = false;
      clock = hw.ptb.Clock; % use psychtoolbox clock
    else
      rig.timeline.UseTimeline = true;
      clock = hw.TimelineClock(rig.timeline); % use timeline clock
    end
    rig.clock = clock;
    cellfun(@(user) setClock(user, clock),...
      {'mouseInput', 'lickDetector'});
    
    t = rig.timeline.UseTimeline;
    if enable
      log('Use of timeline enabled');
    else
      log('Use of timeline disabled');
    end
  end
end
