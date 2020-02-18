function expServer(varargin)
%SRV.EXPSERVER Start the presentation server
%   The principle function for running experiments.  expServer listens for
%   commands via TCP/IP Web sockets to start, stop and pause stimulus
%   presentation experiments.  expServer can also be called with an expRef
%   for running a specific experiment.
%   
%
%   Inputs (Optional Name-Value Parameters):
%     useTimelineOverride (logical) - Flag indicating whether to start
%       Timeline.  If empty the default is the UseTimeline flag in the
%       hardware file.  Timeline may still be toggled by pressing the 't'
%       key.
%     bgColour (1-by-3 double) - The background colour of the stimulus
%       window.  If not specified the background colour specified in the
%       harware file is used.
%     expRef (char) - An experiment reference string for starting an
%       experiment in 'single-shot mode'.
%     preDelay (double) - The delay between initialization and experiment
%       start.  This parameter is only used with the 'expRef' parameter.
%       Default is 0.
%     postDelay (double) - The delay between stop signal and experiment
%       cleanup.  This parameter is only used with the 'expRef' parameter.
%       Default is 0.
%     alyx (Alyx) - An instance of Alyx for communicating with the
%       database.  This parameter is only used with the 'expRef' parameter.
%
%   Key bindings:
%     t - Toggle Timeline on and off.  The default state is defined in the
%       hardware file but may be overridden as the first input argument.
%     w - Toggle reward on and off.  This switches the output of the first
%       DAQ output channel between its 'high' and 'low' state.  The
%       specific DAQ channel and its default state are set in the hardware
%       file.
%     space - Deliver default reward, specified by the DefaultCommand
%       property in the hardware file.
%     m - Perform water calibration. 
%     b - Toggle the background colour between the default and white.
%     g - Perform gamma correction
%     
%   Example 1: Run in listener mode with Timeline disabled
%     srv.expServer('UseTimelineOverride', false)
%
%   Example 2: Run in single-shot mode with 10 second delay
%     ref = dat.newExp('test', now, exp.choiceWorldParams);
%     srv.expServer('expRef', ref, 'preDelay', 10)
%
% See also MC, io.WSJCommunicator, hw.devices, srv.prepareExp, hw.Timeline
%
% Part of Rigbox

% 2013-06 CB created

%% Fixed Parameters
global AGL GL GLU %#ok<NUSED>
quitKey = KbName('q');
rewardToggleKey = KbName('w');
rewardPulseKey = KbName('space');
rewardCalibrationKey = KbName('m');
gammaCalibrationKey = KbName('g');
timelineToggleKey = KbName('t');
toggleBackground = KbName('b');
% Function for constructing a full ID for warnings and errors
fullID = @(id) strjoin([{'Rigbox:srv:expServer'}, ensureCell(id)],':');

%% User parameters
p = inputParser;
p.addParameter('expRef', [], @ischar)
p.addParameter('alyx', Alyx('',''), @(v)isa(v,'Alyx'))
p.addParameter('preDelay', 0, @isnumeric)
p.addParameter('postDelay', 0, @isnumeric)
p.addParameter('rewardId', 1, @isnumeric) % May be changed via keypress
p.addParameter('useTimelineOverride', [])
checkBgColour = @(x)validateattributes(x,...
  "numeric", {'nonnegative', '<=', 255, 'vector'}, mfilename, 'bgColour');
p.addParameter('bgColour', 127*[1 1 1], checkBgColour) % mid gray by default
p.parse(varargin{:})

singleShot = ~isempty(p.Results.expRef);
if ~singleShot
  % The following parameters are only relevent when an expRef is provided.
  irrelevent = {'alyx', 'preDelay', 'postDelay'};
  defined = ~ismember(irrelevent, p.UsingDefaults);
  ignored = strcat('''', irrelevent(defined), '''');
  if ~isempty(ignored)
    delim = iff(numel(ignored) > 2, {', ', ' and '}, ' and ');
    warning(...
      fullID('ignoredParameters'), ...
      'The input parameter(s) %s will be ignored', ...
      strjoin(ignored, delim))
  end
end

p = p.Results;
rewardId = p.rewardId;
bgColour = p.bgColour;

%% Initialisation
% Pull latest changes from remote
git.update();
% random seed random number generator
rng('shuffle');
experiment = []; % currently running experiment, if any

% get rig hardware
rig = hw.devices;
required = {'stimWindow', 'timeline', 'daqController'};
present = isfield(iff(isempty(rig), struct, rig), required);
if ~all(present)
  error(fullID('missingHardware'), ['Rig''s ''hardware.mat'''...
    ' file not set up correctly. The following objects are missing:\n\r%s'],...
    strjoin(required(~present), '\n'))
end

% communicator for receiving commands from clients
communicator = getOr(rig, 'communicator', io.WSJCommunicator.server);
listener = event.listener(communicator, 'MessageReceived',...
  @(~,msg) handleMessage(msg.Id, msg.Data, msg.Sender));
communicator.EventMode = false;
communicator.open();

% set PsychPortAudio verbosity to warning level
oldPpaVerbosity = PsychPortAudio('Verbosity', 2);
Priority(1); % increase thread priority level

cleanup = onCleanup(@() fun.applyForce({
  @() communicator.close(),...
  @ShowCursor,...
  @KbQueueRelease,...
  @() delete(listener),...
  @() Screen('CloseAll'),...
  @() PsychPortAudio('Close'),...
  @() Priority(0),... %set back to normal priority level
  @() PsychPortAudio('Verbosity', oldPpaVerbosity)...
  @() delete(listener),...
  @() rig.stimWindow.close(),...
  @() aud.close(rig.audio),...
  @() rig.scale.cleanup()
  }));

% OpenGL
InitializeMatlabOpenGL;

% listen to keyboard events
KbQueueCreate();
KbQueueStart();

HideCursor();

% open the stimulus window
rig.stimWindow.BackgroundColour = bgColour;
rig.stimWindow.open();

fprintf('\n<q> quit, <w> toggle reward, <t> toggle timeline\n');
fprintf(['<%s> reward pulse, <%s> perform reward calibration\n' ...
  '<%s> perform gamma calibration\n'], KbName(rewardPulseKey), ...
  KbName(rewardCalibrationKey), KbName(gammaCalibrationKey));
log('Started presentation server on port %i', communicator.DefaultListenPort);

if nargin < 1 || isempty(p.useTimelineOverride)
  % toggle use of timeline according to rig default setting
  toggleTimeline(rig.timeline.UseTimeline);
else
  toggleTimeline(p.useTimelineOverride);
end

%% If running single experiment mode immediately start the experiment
if singleShot
  assert(dat.expExists(p.expRef), fullID('expRefNotFound'), ...
    'Experiment ref ''%s'' does not exist', p.expRef)
  runExp(p.expRef, p.preDelay, p.postDelay, p.alyx);
end

%% Main loop for service
running = ~singleShot;
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
            communicator.send(id, {'fail', expRef, fullID('expRefNotFound') ...
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
            if AlyxInstance.IsLoggedIn && ~experiment.AlyxInstance.IsLoggedIn
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

  function aborted = runExp(expRef, preDelay, postDelay, alyx)
    % disable ptb keyboard listening
    KbQueueRelease();
    
    rig.stimWindow.flip(); % clear the screen before
    
    % start the timeline system
    if rig.timeline.UseTimeline
      % turn off rotary encoder recording in timeline by default so
      % experiment can access it
      idx = ~strcmp('rotaryEncoder', rig.timeline.UseInputs);
      if ~isempty(idx)
        rig.timeline.UseInputs = rig.timeline.UseInputs(idx);
      end
      rig.timeline.start(expRef, alyx);
    else
      %otherwise using system clock, so zero it
      rig.clock.zero();
    end
    
    % prepare the experiment
    params = dat.expParams(expRef);
    experiment = srv.prepareExp(params, rig, preDelay, postDelay,...
      communicator);
    communicator.EventMode = true; % use event-based callback mode
    experiment.AlyxInstance = alyx; % add Alyx Instance
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
    if ~strcmp(dat.parseExpRef(expRef), 'default') && ~isempty(getOr(dat.paths, 'databaseURL'))
      try
        alyx.registerFile(hwInfo);
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
    
    rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
    
    save(rigHwFile, 'daqController', '-append');
  end

  function whiteScreen()
    % WHITESCREEN Changes screen background to white
    rig.stimWindow.BackgroundColour = rig.stimWindow.White;
    rig.stimWindow.flip();
    rig.stimWindow.BackgroundColour = bgColour;
  end

  function calibrateGamma()
    % CALIBRATEGAMMA Perform gamma correction and save to hardware file
    %   Performs a gamma correction, applies the new values and saves them
    %   to the rig hardware config file.
    %
    % See also saveGamma, hw.ptb.Window/calibration

    stimWindow = rig.stimWindow;
    
    % Parameters for calibration
    DaqDev = rig.daqController.DaqIds; % device id to which photodiode connects
    lightIn = 'ai1'; % defaults from hw.ptb.Window
    clockIn = 'ai0';
    clockOut = 'port1/line0';
    clockOutHint = 'PFI4';
    plotFig = false; % Supress plot to avoid taskbar coming to foreground
    
    % Print to log and screen in case window covers prompt
    msg = sprintf(['Please connect photodiode to %s, clockIn to %s and '...
                  'clockOut to %s (%s).\r\n Press any key to contiue\n'], ...
                  lightIn, clockIn, clockOut, clockOutHint);
    % Draw white text to centre of screen at 40 chars per line, 1px spacing 
    stimWindow.drawText(msg, 'center', 'center', stimWindow.White, 1, 40);
    log(msg); % Log message to command window

    pause; % wait for keypress
    stimWindow.Calibration = ...
      stimWindow.calibration(DaqDev, lightIn, clockIn, clockOut, plotFig);
    pause(1);
    
    % Save calibration to file and apply to current object
    saveGamma(stimWindow.Calibration);
    stimWindow.applyCalibration(stimWindow.Calibration);
    clear('lightIn','clockIn','clockOut','cal');
    log('Gamma calibration complete');
  end

  function saveGamma(cal)
    % SAVEGAMMA Save calibration struct to saved stimWindow object
    %  Loads saved stimWindow object from this rig's hardware file, updates
    %  the Calibration property with input, then saves.
    rigHwFile = fullfile(pick(dat.paths, 'rigConfig'), 'hardware.mat');
    stimWindow = load(rigHwFile,'stimWindow');
    stimWindow = stimWindow.stimWindow;
    stimWindow.Calibration = cal;
    save(rigHwFile, 'stimWindow', '-append');
  end

  function log(varargin)
    % LOG Print timestamped message to command prompt
    message = sprintf(varargin{:});
    timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
    fprintf('[%s] %s\n', timestamp, message);
  end

  function setClock(user, clock)
    % SETCLOCK Set Clock property of rig device object
    if isfield(rig, user)
      rig.(user).Clock = clock;
    end
  end

  function t = toggleTimeline(enable)
    % TOGGLETIMELINE Enable/disable Timeline
    %  If Timeline is currently enabled, disable and replace rig clock with
    %  default.  Otherwise enable Timeline and pass Timeline Clock to other
    %  rig objects.
    %
    % See also HW.CLOCK, HW.TIMELINE, SETCLOCK
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
