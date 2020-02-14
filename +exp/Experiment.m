classdef Experiment < handle
  %EXP.EXPERIMENT Base class for stimuli-delivering experiments
  %   The class defines a framework for event- and state-based experiments.
  %   Visual and auditory stimuli can be controlled by experiment phases.
  %   Phases changes are managed by an event-handling system.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    % An array of event handlers. Each should specify the name of the
    % event that activates it, callback functions to be executed when
    % activated and an optional delay between the event and activation.
    % They should be objects of class EventHandler.
    EventHandlers = exp.EventHandler.empty;
    
    % Timekeeper used by the experiment. Clocks return the current time. See
    % the Clock class definition for more information.
    Clock = hw.ptb.Clock;
    
    % A stimulus window for rendering visual stimuli during the experiment.
    % Must be of Window class.
    StimWindow;
    
    % Handles conversion between graphics and visual field coordinates of
    % the stimulus window. Must be an object of ViewingModel class.
    StimViewingModel;
    
    % Key for terminating an experiment whilst running. Shoud be a
    % Psychtoolbox keyscan code (see PTB KbName function).
    QuitKey = KbName('esc')
    
    % Key for pausing an experiment
    PauseKey = KbName('esc')
    
    % Possible phases of the experiment. Cell array of the names (strings) of the phases.
    % not currently used
%     Phases = {};
    
    % Display debugging information
    DisplayDebugInfo = false;

    % Provides the conditions (parameters etc) for each trial. Must be an
    % object of class exp.ConditionServer
    ConditionServer;
    
    % String description of the type of experiment, to be saved into the
    % block data field 'expType'.
    Type = '';
    
    % Reference for the rig that this experiment is being run on, to be
    % saved into the block data field 'rigName'.
    RigName
    
    Communicator = io.DummyCommunicator
    
    Audio
    
    % Delay (secs) before starting main experiment phase after experiment
    % init phase has completed
    PreDelay = 0 
    
    % Delay (secs) before beginning experiment cleanup phase after
    % main experiment phase has completed (assuming an immediate abort
    % wasn't requested).
    PostDelay = 0
    
    % Flag indicating whether the experiment is paused.
    % FIXME Protect access to IsPaused property
    % @body This should be set only via the pause and resume methods
    IsPaused = false
    
    % AlyxToken from client
    AlyxInstance
  end
  
  properties (SetAccess = protected)
    %Currently active phases of the experiment. Cell array of their names
    %(i.e. strings)
    ActivePhases = {}
    
    %Current trial number of the experiment. Zero if not currently in a
    %trial
    TrialNum;
    
    %Number of complete trials in the experiment so far.
    TrialCount = 0
    
    %Number of stimulus window flips
    StimWindowUpdateCount
    
    %Data from the currently running experiment, if any.
    Data
    
  end
  
  properties (Access = protected)
    %Set triggers awaiting activation: a list of Triggered objects, which
    %are awaiting activation pending completion of their delay period.
    Pending
    
    IsLooping = false %flag indicating whether to continue in experiment loop
  end
  
  methods
    function useRig(obj, rig)
      obj.RigName = rig.name;
      obj.Clock = rig.clock;
      obj.StimWindow = rig.stimWindow;
      obj.StimViewingModel = rig.stimViewingModel;
      obj.Audio = rig.audio;
    end

    function loadSound(obj, samples)
      % Loads sound samples onto the audio device
      %
      % loadSound(SAMPLES) loads samples onto the audio device.
      PsychPortAudio('FillBuffer', obj.Audio, samples);
    end
    
    function pause(obj)
      if ~obj.IsPaused
        abortPendingHandlers(obj);
        obj.IsPaused = true;
        disp('*** Experiment paused ***');
      end
    end
    
    function resume(obj)
      if obj.IsPaused
        disp('*** Experiment resumed ***');
        obj.IsPaused = false;
      end
    end
    
    function abortPendingHandlers(obj, handler)
      if nargin < 2
        % Sets all pending triggers inactive
        [obj.Pending(:).isActive] = deal(false);
      else
        % Sets pending triggers for specified handler inactive
        abortList = ([obj.Pending.handler] == handler);
        [obj.Pending(abortList).isActive] = deal(false);
      end
    end
    
    function startTime = playSound(obj, name, nreps, when, waitForStart)
      % Plays the currently loaded sound on the audio device
      %
      % playSound(NAME, [NREPS], [WHEN], [WAITFORSTART]) plays the currently
      % loaded sound samples on the audio device. All parameters are
      % optional except the first. Name specifies a name that will become part
      % of a triggered event. If playing immediatley, it is advisable to set 
      % WAITFORSTART to true for a more accurate recorded start time
      if nargin < 2
        nreps = 1;
      end
      
      if nargin < 3
        when = 0;
      end
      
      if nargin < 4
        waitForStart = false;
      end
      
      if waitForStart
        startTime = PsychPortAudio('Start', obj.Audio, nreps,...
          toPtb(obj.Clock, when), double(waitForStart));
        % play should have happened at startTime but needs converting to
        % native clock
        startTime = fromPtb(obj.Clock, startTime);
      else
        PsychPortAudio('Start', obj.Audio, nreps, toPtb(obj.Clock, when),...
          double(waitForStart));
        if isempty(when) || when <= 0
          % immediate start was requested so assume play happened about now
          startTime = obj.Clock.now;
        else
          % assume play happened when requested to
          startTime = when;
        end
      end
      event = [name 'SoundPlayed'];
      % log the time the sound started (or should start at).
      log(obj, [event 'Time'], startTime);
      % notify event handlers waiting for this sound to start 
      fireEvent(obj, exp.EventInfo(event, startTime, obj), false);
    end

    function startPhase(obj, name, time)
      % Starts a phase
      %
      % startPhase(NAME, TIME) causes a phase to start. The phase is added
      % to the list of active phases. The change is also signalled to any 
      % interested triggers as having occured at TIME.
      % 
      % Note: The time specified is signalled to the triggers, which is
      % important for maintaining rigid timing offsets even if there are
      % delays in calling this function. e.g. if a trigger is set to go off
      % one second after a phase starts, the trigger will become due one
      % second after the time specified, *not* one second from calling this
      % function.

      % make sure the phase isn't already active
      if ~any(strcmpi(obj.ActivePhases, name))      
        % add the phase from list
        obj.ActivePhases = [obj.ActivePhases; name];

        % action any triggers contingent on this phase change
        fireEvent(obj, exp.EventInfo([name 'Started'], time, obj));
      end
    end

    function endPhase(obj, name, time)
      % Ends a phase
      %
      % endPhase(NAME, TIME) causes a phase to end. The phase is removed 
      % from the list of active phases. The event is also signalled to any
      % interested triggers as having occured at TIME.
      % 
      % Note: The time specified is signalled to the triggers, which is
      % important for maintaining rigid timing offsets even if there are
      % delays in calling this function. e.g. if a trigger is set to go off
      % one second after a phase starts, the trigger will become due one
      % second after the time specified, *not* one second from calling this
      % function.
      
      % make sure the phase is active
      if any(strcmpi(obj.ActivePhases, name))      
        % remove the phase from list
        obj.ActivePhases(strcmpi(obj.ActivePhases, name)) = [];

        % action any triggers contingent on this phase change
        fireEvent(obj, exp.EventInfo([name 'Ended'], time, obj));
      end
    end     
    
    function addEventHandler(obj, handler, varargin)
      % Adds one or more event handlers
      %
      % addEventHandler(HANLDER) adds one or more handlers specified by the 
      % HANLDER parameter (either a single object of class EventHandler, or
      % an array of them), to this experiment's list of handlers.
      if iscell(handler)
        handler = cell2mat(handler);
      end
      obj.EventHandlers = [obj.EventHandlers; handler(:)];
      if ~isempty(varargin)
        % deal with extra handle arguments recursively
        addEventHandler(obj, varargin{:});
      end
    end
    
    function data = run(obj, ref)
      % Runs the experiment
      %
      % run(REF) will start the experiment running, first initialising
      % everything, then running the experiment loop until the experiment
      % is complete. REF is a reference to be saved with the block data
      % under the 'expRef' field, and will be used to ascertain the
      % location to save the data into. If REF is an empty, i.e. [], the
      % data won't be saved.
      
      if ~isempty(ref)
        %ensure experiment ref exists
        assert(dat.expExists(ref), 'Experiment ref ''%s'' does not exist', ref);
      end
      
      %do initialisation
      init(obj);
      
      obj.Data.rigName = obj.RigName;
      obj.Data.expRef = ref; %record the experiment reference
      
      %Trigger the 'experimentInit' event so any handlers will be called
      initInfo = exp.EventInfo('experimentInit', obj.Clock.now, obj);
      fireEvent(obj, initInfo);
      
      %set pending handler to begin the experiment 'PreDelay' secs from now
      start = exp.EventHandler('experimentInit', exp.StartPhase('experiment'));
      obj.Pending = dueHandlerInfo(obj, start, initInfo, obj.Clock.now + obj.PreDelay);
      
      %refresh the stimulus window
      flip(obj.StimWindow);
      
      % start the experiment loop
      mainLoop(obj);
      
      % last flip, if needed
      if obj.StimWindow.Invalid
        flip(obj.StimWindow);
      end
      
        %post comms notification with event name and time
      if isempty(obj.AlyxInstance) || ~obj.AlyxInstance.IsLoggedIn
        post(obj, 'AlyxRequest', obj.Data.expRef); %request token from client
        pause(0.2) 
      end
      try
        %Trigger the 'experimentCleanup' event so any handlers will be called
        cleanupInfo = exp.EventInfo('experimentCleanup', obj.Clock.now, obj);
        fireEvent(obj, cleanupInfo);
        
        %do our cleanup
        cleanup(obj);
        
        %return the data structure that has been built up
        data = obj.Data;
        
        if ~isempty(ref)
          saveData(obj); %save the data
        end
      catch ex
        %mark that an exception occured in the block data, then save
        obj.Data.endStatus = 'exception';
        obj.Data.exceptionMessage = ex.message;
        if ~isempty(ref)
          saveData(obj); %save the data
        end
        %rethrow the exception
        rethrow(ex)
      end
    end

    function startTrial(obj, time) 
      % Signals the next trial to start
      %
      % startTrial(TIME) causes the current experimental trial to start if
      % there are more trial conditions available from the condition
      % server. If so the trial number is incremented, a trial started 
      % event is signalled as having occurred at TIME specified, (setting
      % off any associated triggers).
      % 
      % Note: The time specified is signalled to the triggers, which is
      % important for maintaining rigid timing offsets even if there are
      % delays in calling this function. e.g. if a trigger is set to go off
      % one second after a trial starts, the trigger will become due one
      % second after the time specified, *not* one second from calling this
      % function.
      
      if moreTrials(obj.ConditionServer)
        nextTrial(obj.ConditionServer);
        obj.TrialNum = obj.TrialCount + 1;
        cond = obj.ConditionServer.trialSpecificParams;
        obj.Data.trial(obj.TrialNum).condition = cond;
        %post notification about next trial condition
        post(obj, 'status', {'update', obj.Data.expRef, 'newTrial', cond});
        fireEvent(obj, exp.TrialEventInfo('trialStarted', time, obj, obj.TrialNum));
      else
        % if there are no more trial conditions then end the experiment
        obj.quit();
        obj.Data.endStatus = 'completed'; %flag as run to completion
      end
    end
    
    function endTrial(obj, time)
      % Signals the current trial to end
      %
      % endTrial(TIME) causes the current experimental trial to end by
      % signalling the occurrence at TIME specified, of the corresponding
      % event (setting off any associated triggers).
      % 
      % Note: The time specified is signalled to the triggers, which is
      % important for maintaining rigid timing offsets even if there are
      % delays in calling this function. e.g. if a trigger is set to go off
      % one second after a trial ends, the trigger will become due one
      % second after the time specified, *not* one second from calling this
      % function.
      
      % need to log manually *before* removing trial flag (otherwise log
      % entry ends up not in the trial substruct).
      log(obj, 'trialEndedTime', obj.Clock.now);
      
      currTrial = obj.TrialNum;
      obj.TrialCount = obj.TrialCount + 1; % increment trial count
      obj.TrialNum = 0; % current trial number is zero between trials
      
      % submit data to condition server from the completed trial
      update(obj.ConditionServer, obj.Data.trial(obj.TrialCount));
      %post notification with trial data
      post(obj, 'status',...
        {'update', obj.Data.expRef, 'trialData', obj.Data.trial(obj.TrialCount)});
      
      % activate handlers without logging this event (see above)
      fireEvent(obj, exp.TrialEventInfo('trialEnded', time, obj, currTrial), false);
    end
    
    function bool = inPhase(obj, name)
      % Reports whether currently in specified phase
      %
      % inPhase(NAME) checks whether the experiment is currently in the
      % phase called NAME.    
      bool = any(strcmpi(obj.ActivePhases, name));
    end
    
    function set.StimWindow(obj, value)
      % make sure the protocol isn't running when we try to change this
      assert(~inPhase(obj, 'experiment'), '');
      
      % now change the value of the property
      obj.StimWindow = value;
    end  
    
    function log(obj, field, value)
      % Logs the value in the experiment data
      if obj.TrialNum > 0
        if isfield(obj.Data.trial, field) && numel(obj.Data.trial) >= obj.TrialNum
          obj.Data.trial(obj.TrialNum).(field) = ...
            [obj.Data.trial(obj.TrialNum).(field) value];
        else
          obj.Data.trial(obj.TrialNum).(field) = value;
        end
      else
        if isfield(obj.Data, field)
          obj.Data.(field) = [obj.Data.(field) value];
        else
          obj.Data.(field) = value;
        end
      end
    end
    
    function quit(obj, immediately)
      % clear all phases except 'experiment' "dirtily', i.e. without
      % setting off any triggers for those phases.
      % *** IN FUTURE MAY CHANGE SO THAT WE DO END TRIAL CLEANLY ***
      if nargin < 2
        immediately = false;
      end
      
      % set any pending handlers inactive
      abortPendingHandlers(obj);

      % no longer in a trial
      obj.TrialNum = 0;
      
      if inPhase(obj, 'experiment')
        obj.ActivePhases = {'experiment'}; % clear active phases except experiment
        % end the experiment phase "cleanly", i.e. with triggers
        endPhase(obj, 'experiment', obj.Clock.now);
      else
        obj.ActivePhases = {}; %clear active phases
      end
      
      obj.StimWindow.invalidate; % make sure screen gets updated
      
      if immediately
        %flag as 'aborted' meaning terminated early, and as quickly as possible
        obj.Data.endStatus = 'aborted';
      else
        %flag as 'quit', meaning quit before all trials were naturally complete,
        %but still shut down with usual cleanup delays etc
        obj.Data.endStatus = 'quit';
      end
      
      if immediately || obj.PostDelay == 0
        %unset looping flag now
        stopLooping(obj);
      else
        %add a pending handler to unset looping flag
        %NB, since we create a pending item directly, the EventHandler delay
        %and triggering event name are only set for clarity and wont be
        %used
        stop = exp.EventHandler('experimentEnded'); %event name just for clarity
        stop.Delay = obj.PostDelay; %delay just for clarity
        stop.addCallback(@(~, ~) stopLooping(obj));
        pending = dueHandlerInfo(obj, stop, [], obj.Clock.now + obj.PostDelay);
        obj.Pending = [obj.Pending, pending];
      end
    end
    
    function ensureWindowReady(obj)
      % complete any outstanding asynchronous flip
      if obj.StimWindow.AsyncFlipping
        % ensure flip is complete, and record the time
        [time, ~, lag] = asyncFlipEnd(obj.StimWindow);
        time = fromPtb(obj.Clock, time); %convert ptb/sys time to our clock's time
        obj.StimWindowUpdateCount = obj.StimWindowUpdateCount + 1;
        obj.Data.stimWindowUpdateTimes(obj.StimWindowUpdateCount) = time;
        obj.Data.stimWindowUpdateLags(obj.StimWindowUpdateCount) = lag;
      end
    end
    
    function post(obj, id, msg)
      send(obj.Communicator, id, msg);
    end
  end
  
  methods (Access = protected)
    function init(obj)
      % Performs initialisation before running
      %
      % init() is called when the experiment is run before the experiment
      % loop begins. Subclasses can override to perform their own
      % initialisation, but must chain a call to this.
      
      % create a new experiment data struct array
      obj.Data = struct();
      obj.Data.expType = obj.Type; % record the type description
      obj.Data.trial = struct([]);
      %initialise stim window frame times array, large enough for ~2 hours
      obj.Data.stimWindowUpdateTimes = zeros(60*60*60*2, 1);
      obj.Data.stimWindowUpdateLags = zeros(60*60*60*2, 1);
      
      % reset the trial number & count and the condition server
      obj.TrialCount = 0;
      obj.TrialNum = 0;
      obj.ConditionServer.reset();
      obj.StimWindowUpdateCount = 0;
      
      % clear phases & init pending triggers empty
      obj.ActivePhases = {};
      
      % create and initialise a key press queue for responding to input
      KbQueueCreate();
      KbQueueStart();
      
      % MATLAB time stamp for starting the experiment
      obj.Data.startDateTime = now;
      obj.Data.startDateTimeStr = datestr(obj.Data.startDateTime);
      
      % record global parameters
      obj.Data.parameters = obj.ConditionServer.globalParams;
      
      %init end status to nothing
      obj.Data.endStatus = [];
      
      % *** TODO: save details of event handlers in some nice way?
    end
    
    function cleanup(obj)
      % Performs cleanup after experiment completes
      %
      % cleanup() is called when the experiment is run after the experiment
      % loop completes. Subclasses can override to perform their own 
      % cleanup, but must chain a call to this.
      
      % MATLAB time stamp for ending the experiment
      obj.Data.endDateTime = now;
      obj.Data.endDateTimeStr = datestr(obj.Data.endDateTime);
      
      % some useful data
      obj.Data.numCompletedTrials = obj.TrialCount;
      obj.Data.duration = etime(...
        datevec(obj.Data.endDateTime), datevec(obj.Data.startDateTime));
      
      %clip the stim window update times array
      obj.Data.stimWindowUpdateTimes((obj.StimWindowUpdateCount + 1):end) = [];
      obj.Data.stimWindowUpdateLags((obj.StimWindowUpdateCount + 1):end) = [];
      
      % clear phases
      obj.ActivePhases = {};
      
      % stop listening to kb events and release resources
      KbQueueStop();
      KbQueueRelease();

      % destroy video texures created during intialisation
      deleteTextures(obj.StimWindow);
      
      % close audio
      aud.close(obj.Audio);
    end
    
    function mainLoop(obj)
      % Executes the main experiment loop
      %
      % mainLoop() enters a loop that updates the stimulus window, checks
      % for and deals with inputs, updates state and activates triggers.
      % Will run until the experiment completes (phase 'experiment' ends).
      
      %set looping flag
      obj.IsLooping = true;
      % begin the loop
      while obj.IsLooping
        %% create a list of handlers that have become due
        dueIdx = find([obj.Pending.dueTime] <= now(obj.Clock));
        ndue = length(dueIdx);
        
        %% check for and process any input
        checkInput(obj);

        %% execute pending event handlers that have become due
        for i = 1:ndue
          due = obj.Pending(dueIdx(i));
          if due.isActive % check handler is still active
            activateEventHandler(obj, due.handler, due.eventInfo, due.dueTime);
            obj.Pending(dueIdx(i)).isActive = false; % set as inactive in pending
          end
        end

        % now remove executed (or otherwise inactived) ones from pending
        inactiveIdx = ~[obj.Pending.isActive];
        obj.Pending(inactiveIdx) = [];
        
        %% update any miscellaneous state
        updateState(obj);
        
        %% redraw the stimulus window if it has been invalidated
        ensureWindowReady(obj); % complete any outstanding refresh
        if obj.StimWindow.Invalid || obj.DisplayDebugInfo
          % draw the visual frame
          drawFrame(obj);
          % draw debugging info if requested
          if obj.DisplayDebugInfo
            drawDebugInfo(obj);
          end   

          % do the actual 'flip' of the frame onto the screen. This will
          % also clear the screen to background colour
          asyncFlipBegin(obj.StimWindow);
        end
        %% If no handlers are due soon, allow callbacks etc to execute
        dueIn = [obj.Pending.dueTime] - now(obj.Clock);
        %currently we check nothing is due for at least 100ms
        if all(dueIn > 100/1000)
          drawnow; % allow other callbacks to execute
        end
      end
      ensureWindowReady(obj); % complete any outstanding refresh
    end
    
    function checkInput(obj)
      % Checks for and handles inputs during experiment
      %
      % checkInput() is called during the experiment loop to check for and
      % handle any inputs. This function specifically checks for any 
      % keyboard input that occurred since the last check, and passes that
      % information on to handleKeyboardInput. Subclasses should override
      % this function to check for any non-keyboard inputs of interest, but
      % must chain a call to this function.
      [pressed, firstPress, firstRelease, lastPress, lastRelease] = KbQueueCheck();
%       lastPress(lastPress > 0) = lastPress(lastPress > 0) - obj.Clock.ReferenceTime;
%       handleKeyboardInput(obj, lastPress, lastRelease);
      handleKeyboardInput(obj, lastPress > 0, lastRelease > 0);
    end

    function handleKeyboardInput(obj, keysPressed, keysReleased)
      if any(keysPressed(obj.QuitKey)) || any(keysPressed(KbName('q')))
        % handle the quit key being pressed
        if strcmp(obj.Data.endStatus, 'quit')
          %quitting already in progress - a second time means fast abort
          fprintf('Abort fast (quit key pressed during quitting)\n');
          obj.quit(true);
        else
          fprintf('Quit key pressed\n');
          obj.quit(false);
        end
      elseif any(keysPressed(obj.PauseKey))
        fprintf('Pause key pressed\n');
        if obj.IsPaused
          resume(obj);
        else
          pause(obj);
        end
      end
    end
    
    function fireEvent(obj, eventInfo, logEvent)
      %fireEvent Called when an event occurs to log and handle them
      %   fireEvent(EVENTINFO) logs the time of the event, and checks the list 
      %   of experiment event handlers for any that are listening to the event 
      %   detailed in EVENTINFO. Those that are will be activated after their 
      %   desired delay period. EVENTINFO must be an object of class EventInfo.
      
      event = eventInfo.Event;
      
      %post comms notification with event name and time
      tnow = now(obj.Clock);
      msg = {'update', obj.Data.expRef, 'event', event, tnow};
      post(obj, 'status', msg);
      
      if nargin < 3
        % log events by default
        logEvent = true;
      end
      
      if logEvent
        % Save the actual time the event completed. For events that occur
        % during a trial, timestamps are saved within the trial data, otherwise
        % we just save in experiment-wide data.
        log(obj, [event 'Time'], tnow);
      end
      
      % create a list of handlers for this event
      if isempty(obj.EventHandlers)
        % handle special case bug in matlab
        % if EventHandlers is empty, the alternate case below will fail so
        % we handle it here
        handleEventNames = {};
      else
        handleEventNames = {obj.EventHandlers.Event};
      end
      
      evexp = ['(^|\|)' event '($|\|)'];
      match = ~strcmp(regexp(handleEventNames, evexp, 'match', 'once'), '');
      handlers = obj.EventHandlers(match);
      nhandlers = length(handlers);
      for i = 1:nhandlers
        if islogical(handlers(i).Delay) && handlers(i).Delay == false
          % delay is false, so activate immediately
          due = eventInfo.Time;
          immediate = true;
        else
          % delayed handler
          due = eventInfo.Time + handlers(i).Delay.secs;
          immediate = false;
        end

        % if the handler has no delay, then activate it now,
        % otherwise add it to our pending list
        if immediate
          activateEventHandler(obj, handlers(i), eventInfo, due);
        else
          pending = dueHandlerInfo(obj, handlers(i), eventInfo, due);
          obj.Pending = [obj.Pending, pending]; % append to pending handlers
        end
      end
    end
    
    function s = dueHandlerInfo(~, handler, eventInfo, dueTime)
      s = struct('handler', handler,...
        'eventInfo', eventInfo,...
        'dueTime', dueTime,...
        'isActive', true); % handlers starts active
    end

    function drawFrame(obj)
      % Called to draw current stimulus window frame
      %
      % drawFrame(obj) does nothing in this class but can be overrriden
      % in a subclass to draw the stimulus frame when it is invalidated
    end
    
    function activateEventHandler(obj, handler, eventInfo, dueTime)
      activate(handler, eventInfo, dueTime);
      % if the handler requests the stimulus window be invalided, do so.
      if handler.InvalidateStimWindow
        obj.StimWindow.invalidate;
      end
    end
    
    function drawDebugInfo(obj)
      if isempty(obj.ActivePhases)
        phases = {};
      else
        phases = obj.ActivePhases;
      end
      textLines = cat(1, {sprintf('Experiment time=%.2fs', obj.Clock.now) ;...
        sprintf('Trial num=%i', obj.TrialNum) ;...
        'Active phases:'}, phases);
      
      x = 0;
      y = 0;
      
      textColour = obj.StimWindow.White;
      
      for i = 1:length(textLines)
        [x, y] = obj.StimWindow.drawText([textLines{i} '\n'], x, y, textColour, 1.1);
      end
    end
    
    function updateState(obj)
     % Called to update miscellaneous experiment state
     %
     % updateState(obj) does nothing in this class but can be overrriden
     % in a subclass to update state every loop iteration.
    end
    
    function stopLooping(obj)
      %convenience function to unset looping flag
      obj.IsLooping = false;
    end
    
    function saveData(obj)
        % save the data to the appropriate locations indicated by expRef
        savepaths = dat.expFilePath(obj.Data.expRef, 'block');
        superSave(savepaths, struct('block', obj.Data));
    end
  end
  
end

