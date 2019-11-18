classdef SignalsExp < exp.Experiment
  %EXP.SIGNALSEXP Base class for stimuli-delivering experiments
  %   The class defines a framework for event- and state-based experiments.
  %   Visual and auditory stimuli can be controlled by experiment phases.
  %   Phases changes are managed by an event-handling system.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  properties
    % Holds the wheel object, 'mouseInput' from the rig object.  See also
    % USERIG, HW.DAQROTARYENCODER
    Wheel
    
    % Holds the object for interating with the lick detector.  See also
    % HW.DAQEDGECOUNTER
    LickDetector
    
    % Holds the object for interating with the DAQ outputs (reward valve,
    % etc.)  See also HW.DAQCONTROLLER
    DaqController
    
    % The layer textureId names mapped to their numerical GL texture ids
    TextureById
    
    % A map of stimulus element layers whose keys are the entry names in
    % the Visual StructRef object
    LayersByStim
        
    Time
    
    Inputs
    
    Outputs
    
    Events
    
    Visual
    
%     Audio % = aud.AudioRegistry
    
    % Holds the parameters structure for this experiment
    Params
    
    ParamsLog

    % Index into SyncColourCycle for next sync colour
    NextSyncIdx
        
    Debug matlab.lang.OnOffSwitchState = 'on'
  end
  
  properties (SetAccess = protected)     
    SignalUpdates = struct('name', cell(500,1), 'value', cell(500,1), 'timestamp', cell(500,1))
    NumSignalUpdates = 0
        
    GlobalPars
    
    ConditionalPars
    
    ExpStop
  end
  
  properties (Access = protected)
    %Set triggers awaiting activation: a list of Triggered objects, which
    %are awaiting activation pending completion of their delay period.
    AsyncFlipping = false
    
    StimWindowInvalid = false
    
    Listeners
    
    Net
    
    PauseTime
  end
  
  methods
    function obj = SignalsExp(paramStruct, rig, debug)
      % TODO Move all rig related stuff out of constructor to useRig method.
      % @body This will require a change to audstream.Registry: should work
      % in a similar way to the visual stucture whereby the names of the
      % devices are looked up at runtime.
      if nargin > 2; obj.Debug = debug; end % Set debug mode
      clock = rig.clock;
      clockFun = @clock.now;
      obj.QuitKey = KbName('q');
      obj.TextureById = containers.Map('KeyType', 'char', 'ValueType', 'uint32');
      obj.LayersByStim = containers.Map;
      obj.Inputs = sig.Registry(clockFun);
      obj.Outputs = sig.Registry(clockFun);
      obj.Visual = StructRef;
      obj.Audio = audstream.Registry(rig.audioDevices);
      obj.Events = sig.Registry(clockFun);
      %% configure signals
      net = sig.Net;
      net.Debug = obj.Debug;
      obj.Net = net;
      obj.Time = net.origin('t');
      obj.Events.expStart = net.origin('expStart');
      obj.Events.newTrial = net.origin('newTrial');
      % TODO Generalize inputs
      obj.Inputs.wheel = net.origin('wheel');
      obj.Inputs.wheelMM = obj.Inputs.wheel.map(@...
        (x)obj.Wheel.MillimetresFactor*(x-obj.Wheel.ZeroOffset)).skipRepeats();
      obj.Inputs.wheelDeg = obj.Inputs.wheel.map(...
        @(x)((x-obj.Wheel.ZeroOffset) / (obj.Wheel.EncoderResolution*4))*360).skipRepeats();
      obj.Inputs.lick = net.origin('lick');
      obj.Inputs.keyboard = net.origin('keyboard');
      % get global parameters & conditional parameters structs
      [~, globalStruct, allCondStruct] = toConditionServer(...
        exp.Parameters(paramStruct));
      % start the first trial after expStart
      advanceTrial = net.origin('advanceTrial');
      % configure parameters signal
      obj.GlobalPars = net.origin('globalPars');
      obj.ConditionalPars = net.origin('condPars');
      [obj.Params, hasNext, obj.Events.repeatNum] = exp.trialConditions(...
        obj.GlobalPars, obj.ConditionalPars, advanceTrial);
      obj.Events.trialNum = obj.Events.newTrial.scan(@plus, 0); % track trial number
      lastTrialOver = then(~hasNext, true);
      obj.Events.expStop = lastTrialOver; %net.origin('expStop');
      % run experiment definition
      if ischar(paramStruct.defFunction)
        expDefFun = fileFunction(paramStruct.defFunction);
        obj.Data.expDef = paramStruct.defFunction;
      else
        expDefFun = paramStruct.defFunction;
        obj.Data.expDef = func2str(expDefFun);
      end
      expDefFun(obj.Time, obj.Events, obj.Params, obj.Visual, obj.Inputs,...
          obj.Outputs, obj.Audio);
      % if user defined 'expStop' in their exp def, allow 'expStop' to also
      % take value at 'lastTrialOver', else just set to 'lastTrialOver'
      if isequal(obj.Events.expStop, lastTrialOver)
        obj.ExpStop = lastTrialOver;
      else
        obj.ExpStop = obj.Events.expStop;
        obj.Events.expStop = merge(obj.Events.expStop, lastTrialOver);
        entryAdded(obj.Events, 'expStop', obj.Events.expStop);
      end
%       if isfield(obj.Events, 'expStop')
%         obj.Events.expStop = merge(obj.Events.expStop, lastTrialOver);
%         entryAdded(obj.Events, 'expStop', obj.Events.expStop);
%       else
%         obj.Events.expStop = lastTrialOver;
%       end
      % listeners
      obj.Listeners = [
        obj.Events.expStart.map(true).into(advanceTrial) %expStart signals advance
        obj.Events.endTrial.into(advanceTrial) %endTrial signals advance
        advanceTrial.map(true).keepWhen(hasNext).into(obj.Events.newTrial) %newTrial if more
        obj.Events.expStop.onValue(@(~)quit(obj))];
      % initialise the parameter signals
      try
        obj.GlobalPars.post(rmfield(globalStruct, 'defFunction'))
        obj.ConditionalPars.post(allCondStruct)
      catch ex
        rethrow(obj.addErrorCause(ex))
      end
      %% data struct
      %initialise stim window frame times array, large enough for ~2 hours
      obj.Data.stimWindowUpdateTimes = zeros(60*60*60*2, 1);
      obj.Data.stimWindowRenderTimes = zeros(60*60*60*2, 1);
%       obj.Data.stimWindowUpdateLags = zeros(60*60*60*2, 1);
      obj.ParamsLog = obj.Params.log();
      obj.useRig(rig);
    end
    
    function useRig(obj, rig)
      obj.Clock = rig.clock;
      obj.Data.rigName = rig.name;
      obj.NextSyncIdx = 1;
      obj.StimWindow = rig.stimWindow;
      obj.StimViewingModel = vis.init(obj.StimWindow.PtbHandle);
      if isfield(rig, 'screens')
        obj.StimViewingModel.screens = rig.screens;
      else
        warning('Rigbox:exp:SignalsExp:NoScreenConfig', ...
          'No screen configuration specified. Visual locations will be wrong.');
      end
      obj.DaqController = rig.daqController;
      obj.Wheel = rig.mouseInput;
      obj.Wheel.zero();
      if isfield(rig, 'lickDetector')
        obj.LickDetector = rig.lickDetector;
        obj.LickDetector.zero();
      end
      if ~isempty(obj.DaqController.SignalGenerators)
          outputNames = fieldnames(obj.Outputs); % Get list of all outputs specified in expDef function
          for m = 1:length(outputNames)
              id = find(strcmp(outputNames{m},...
                  obj.DaqController.ChannelNames)); % Find matching channel from rig hardware file
              if id % if the output is present, create callback 
                  obj.Listeners = [obj.Listeners
                    obj.Outputs.(outputNames{m}).onValue(@(v)obj.DaqController.command([zeros(size(v,1),id-1) v])) % pad value with zeros in order to output to correct channel
                    obj.Outputs.(outputNames{m}).onValue(@(v)fprintf('delivering output of %.2f\n',v))
                    ];   
              elseif strcmp(outputNames{m}, 'reward') % special case; rewardValve is always first signals generator in list 
                  obj.Listeners = [obj.Listeners
                    obj.Outputs.reward.onValue(@(v)obj.DaqController.command(v))
                    obj.Outputs.reward.onValue(@(v)fprintf('delivering reward of %.2f\n', v))
                    ];   
              end
          end
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
      
      % Ensure experiment ref exists
      if ~isempty(ref) && ~dat.expExists(ref)
        % If in debug mode, throw warning, otherwise throw as error
        % TODO Propogate debug behaviour to exp.Experiment
        id = 'Rigbox:exp:SignalsExp:experimenDoesNotExist';
        msg = 'Experiment ref ''%s'' does not exist';
        iff(obj.Debug, @() warning(id,msg,ref), @() error(id,msg,ref))
      end
      
      %do initialisation
      init(obj);
      
      obj.Data.expRef = ref; %record the experiment reference
      
      %Trigger the 'experimentInit' event so any handlers will be called
      initInfo = exp.EventInfo('experimentInit', obj.Clock.now, obj);
      fireEvent(obj, initInfo);
      
      %set pending handler to begin the experiment 'PreDelay' secs from now
      start = exp.EventHandler('experimentInit', exp.StartPhase('experiment'));
      
      % Add callback to update Time is necessary
      start.addCallback(...
        @(~,t)iff(obj.Time.Node.CurrValue, [], @()obj.Time.post(t)));
      % Add callback to update expStart
      start.addCallback(@(varargin)obj.Events.expStart.post(ref));
      obj.Pending = dueHandlerInfo(obj, start, initInfo, obj.Clock.now + obj.PreDelay);
      
      %refresh the stimulus window
      Screen('Flip', obj.StimWindow.PtbHandle);
      
      try
        % start the experiment loop
        mainLoop(obj);
        
        %post comms notification with event name and time
        if isempty(obj.AlyxInstance) || ~obj.AlyxInstance.IsLoggedIn
          post(obj, 'AlyxRequest', obj.Data.expRef); %request token from client
          pause(0.2) 
        end
        
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
        obj.IsLooping = false;
        %mark that an exception occured in the block data, then save
        obj.Data.endStatus = 'exception';
        obj.Data.exceptionMessage = ex.message;
        if ~isempty(ref)
          saveData(obj); %save the data
        end
        ensureWindowReady(obj); % complete any outstanding refresh
        %rethrow the exception
        rethrow(obj.addErrorCause(ex))
      end
    end
    
    function quit(obj, immediately)
      % if the experiment was stopped via 'mc' or 'q' key
      if isempty(obj.Events.expStop.Node.CurrValue)
        stopNode = obj.ExpStop.Node;
        if isempty(stopNode.CurrValue)
          % sneak in and update node value
          affectedIdxs = submit(obj.Net.Id, stopNode.Id, true);
          applyNodes(obj.Net.Id, affectedIdxs);
        end
      end
      
      % set any pending handlers inactive
      abortPendingHandlers(obj);
      
      % clear all phases except 'experiment' "dirtily", i.e. without
      % setting off any triggers for those phases.
      % *** IN FUTURE MAY CHANGE SO THAT WE DO END TRIAL CLEANLY ***
      if nargin < 2
        immediately = false;
      end
      
      if inPhase(obj, 'experiment')
        obj.ActivePhases = {'experiment'}; % clear active phases except experiment
        % end the experiment phase "cleanly", i.e. with triggers
        endPhase(obj, 'experiment', obj.Clock.now);
      else
        obj.ActivePhases = {}; %clear active phases
      end
      
      if immediately
        %flag as 'aborted' meaning terminated early, and as quickly as possible
        obj.Data.endStatus = 'aborted';
      else
        %flag as 'quit', meaning quit before all trials were naturally complete,
        %but still shut down with usual cleanup delays etc
        obj.Data.endStatus = 'quit';
      end

      if immediately || obj.PostDelay == 0
        obj.IsLooping = false; %unset looping flag now
      else
        %add a pending handler to unset looping flag
        %NB, since we create a pending item directly, the EventHandler delay
        %and triggering event name are only set for clarity and wont be
        %used
        endExp = exp.EventHandler('experimentEnded'); %event name just for clarity
        endExp.Delay = obj.PostDelay; %delay just for clarity
        endExp.addCallback(@(~,~)obj.stopLooping);
        pending = dueHandlerInfo(obj, endExp, [], obj.Clock.now + obj.PostDelay);
        obj.Pending = [obj.Pending, pending];
      end
      
    end
    
    function pause(obj)
      % In the future this will be handled by exp.Experiment
      if ~obj.IsPaused
        obj.PauseTime = obj.Clock.now;
        obj.abortPendingHandlers()
        obj.IsPaused = true;
      end
    end
    
    function resume(obj)
      breakLength = obj.Clock.now - obj.PauseTime;
      newTimes = num2cell([obj.Net.Schedule.when] + breakLength);
      [obj.Net.Schedule.when] = deal(newTimes{:});
      obj.IsPaused = false;
    end
    
    function ensureWindowReady(obj)
      % complete any outstanding asynchronous flip
      if obj.AsyncFlipping
        % wait for flip to complete, and record the time
        time = Screen('AsyncFlipEnd', obj.StimWindow.PtbHandle);
        obj.AsyncFlipping = false;
        time = fromPtb(obj.Clock, time); %convert ptb/sys time to our clock's time
%         assert(obj.Data.stimWindowUpdateTimes(obj.StimWindowUpdateCount) == 0);
        obj.Data.stimWindowUpdateTimes(obj.StimWindowUpdateCount) = time;
%         lag = time - obj.Data.stimWindowRenderTimes(obj.StimWindowUpdateCount);
%         obj.Data.stimWindowUpdateLags(obj.StimWindowUpdateCount) = lag;
      end
    end
    
    function queueSignalUpdate(obj, name, value)
      timestamp = clock;
      nupdates = obj.NumSignalUpdates;
      if nupdates == length(obj.SignalUpdates)
        %grow message queue by doubling in size
        obj.SignalUpdates(2*end+1).value = [];
      end
      idx = nupdates + 1;
      obj.SignalUpdates(idx).name = name;
      obj.SignalUpdates(idx).value = value;
      obj.SignalUpdates(idx).timestamp = timestamp;
      obj.NumSignalUpdates = idx;
    end
      
    function post(obj, id, msg)
      send(obj.Communicator, id, msg);
    end
    
    function sendSignalUpdates(obj)
      try
        if obj.NumSignalUpdates > 0
          post(obj, 'signals', obj.SignalUpdates(1:obj.NumSignalUpdates));
        end
      catch ex
        warning(getReport(ex));
      end
      obj.NumSignalUpdates = 0;
    end
    
    function loadVisual(obj, name)
      %% configure signals
      layersSig = obj.Visual.(name).Node.CurrValue.layers;
      obj.Listeners = [obj.Listeners
        layersSig.onValue(fun.partial(@obj.newLayerValues, name))];
      newLayerValues(obj, name, layersSig.Node.CurrValue);

%       %% load textures
%       layerData = obj.LayersByStim(name);
%       Screen('BeginOpenGL', win);
%       try
%         for ii = 1:numel(layerData)
%           id = layerData(ii).textureId;
%           if ~obj.TextureById.isKey(id)
%             obj.TextureById(id) = ...
%               vis.loadLayerTextures(layerData(ii));
%           end
%         end
%       catch glEx
%         Screen('EndOpenGL', win);
%         rethrow(glEx);
%       end
%       Screen('EndOpenGL', win);
    end
    
    function newLayerValues(obj, name, val)
      % NEWLAYERVALUES Callback for layer updates for window invalidation
      %  When a visual element's layers change, store the new values and
      %  check whether stim window needs redrawing.  The following two
      %  conditions invalidate the stim window:
      %    1. Any of the layers have show == true
      %    2. Show has changed from true to false for any layer
      %
      %  Inputs:
      %    name (char) : The name of the stimulus (entry name in
      %      obj.Visual StructRef)
      %    val (struct) : A struct array of layers with new values
      %
      % See also LOADVISUAL, VIS.DRAW, VIS.EMPTYLAYER
      if isKey(obj.LayersByStim, name)
        prev = obj.LayersByStim(name);
        prevshow = any([prev.show]);
      else
        prevshow = false;
      end
      obj.LayersByStim(name) = val;
      
      if any([val.show]) || prevshow
        obj.StimWindowInvalid = true;
      end
      
    end

    function delete(obj)
      if obj.Debug
        disp('delete exp.SignalsExp');
      end
      obj.Net.delete();
    end
  end
  
  methods (Access = protected)
    function init(obj)
      % Performs initialisation before running
      %
      % init() is called when the experiment is run before the experiment
      % loop begins. Subclasses can override to perform their own
      % initialisation, but must chain a call to this.
            
      % create and initialise a key press queue for responding to input
      KbQueueCreate();
      KbQueueStart();
      
      % MATLAB time stamp for starting the experiment
      obj.Data.startDateTime = now;
      obj.Data.startDateTimeStr = datestr(obj.Data.startDateTime);
      
      %init end status to nothing
      obj.Data.endStatus = [];
      
      % load each visual stimulus
      cellfun(@obj.loadVisual, fieldnames(obj.Visual));
      % each event signal should send signal updates
      queuefun = @(n,s)s.onValue(fun.partial(@queueSignalUpdate, obj, n));
      evtlist = mapToCell(@(n,v)queuefun(['events.' n],v),...
          fieldnames(obj.Events), struct2cell(obj.Events));
      outlist = mapToCell(@(n,v)queuefun(['outputs.' n],v),...
          fieldnames(obj.Outputs), struct2cell(obj.Outputs));
      inlist = mapToCell(@(n,v)queuefun(['inputs.' n],v),...
          fieldnames(obj.Inputs), struct2cell(obj.Inputs));
      parslist = queuefun('pars', obj.Params);
      obj.Listeners = vertcat(obj.Listeners, ...
          evtlist(:), outlist(:), inlist(:), parslist(:));
    end
    
    function cleanup(obj)
      % Performs cleanup after experiment completes
      %
      % cleanup() is called when the experiment is run after the experiment
      % loop completes. Subclasses can override to perform their own 
      % cleanup, but must chain a call to this.
      
      stopdatetime = now;
      %clear the stimulus window
      Screen('Flip', obj.StimWindow.PtbHandle);
      
      % collate the logs
      %events
      obj.Data.events = logs(obj.Events);
      %params
      parsLog = obj.ParamsLog.Node.CurrValue;
      obj.Data.paramsValues = [parsLog.value];
      obj.Data.paramsTimes = [parsLog.time];
      %inputs
      obj.Data.inputs = logs(obj.Inputs);
      %outputs
      obj.Data.outputs = logs(obj.Outputs);
      %audio
%       obj.Data.audio = logs(audio);
      
      % MATLAB time stamp for ending the experiment
      obj.Data.endDateTime = stopdatetime;
      obj.Data.endDateTimeStr = datestr(obj.Data.endDateTime);
      
      % some useful data
      obj.Data.duration = etime(...
        datevec(obj.Data.endDateTime), datevec(obj.Data.startDateTime));
      
      %clip the stim window update times array
      obj.Data.stimWindowUpdateTimes((obj.StimWindowUpdateCount + 1):end) = [];
%       obj.Data.stimWindowUpdateLags((obj.StimWindowUpdateCount + 1):end) = [];
      obj.Data.stimWindowRenderTimes((obj.StimWindowUpdateCount + 1):end) = [];
      
      % release resources
      obj.Listeners = [];
      deleteGlTextures(obj);
      KbQueueStop();
      KbQueueRelease();
      
      % delete cached experiment definition function from memory
      [~, exp_func] = fileparts(obj.Data.expDef);
      clear(exp_func)
    end
    
    function deleteGlTextures(obj)
      tex = cell2mat(obj.TextureById.values);
      win = obj.StimWindow.PtbHandle;
      fprintf('Deleting %i textures\n', numel(tex));
      Screen('AsyncFlipEnd', win);
      Screen('BeginOpenGL', win);
      glDeleteTextures(numel(tex), tex);
      obj.TextureById.remove(obj.TextureById.keys);
      Screen('EndOpenGL', win);
    end
    
    function mainLoop(obj)
      % Executes the main experiment loop
      %
      % mainLoop() enters a loop that updates the stimulus window, checks
      % for and deals with inputs, updates state and activates triggers.
      % Will run until the experiment completes (phase 'experiment' ends).
      
      %set looping flag
      obj.IsLooping = true;
      t = obj.Clock.now;
      % begin the loop
      while obj.IsLooping
        %% Check whether we're paused
        while obj.IsPaused
          drawnow
          pause(0.25);
          checkInput(obj);
        end
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
        
        %% signalling
%         tic
        wx = obj.Wheel.readAbsolutePosition();
        post(obj.Inputs.wheel, wx);
        if ~isempty(obj.LickDetector)
          % read and log the current lick count
          [nlicks, ~, licked] = readPosition(obj.LickDetector);
          if licked
            post(obj.Inputs.lick, nlicks);
            fprintf('lick count now %i\n', nlicks);
          end
        end
        post(obj.Time, now(obj.Clock));
        runSchedule(obj.Net);
        
%         runSchedule(obj.Net);
%         nChars = overfprintf(nChars, 'post took %.1fms\n', 1000*toc);
        
        %% redraw the stimulus window if it has been invalidated
        if obj.StimWindowInvalid
          ensureWindowReady(obj); % complete any outstanding refresh
          % draw the visual frame
%           tic
          drawFrame(obj);
%           toc;
          if ~isempty(obj.StimWindow.SyncBounds) % render sync rectangle
            % render sync region with next colour in cycle
            col = obj.StimWindow.SyncColourCycle(obj.NextSyncIdx,:);
            % render rectangle in the sync region bounds in the required colour
            Screen('FillRect', obj.StimWindow.PtbHandle, col, obj.StimWindow.SyncBounds);
            % cyclically increment the next sync idx
            obj.NextSyncIdx = mod(obj.NextSyncIdx, size(obj.StimWindow.SyncColourCycle, 1)) + 1;
          end
          renderTime = now(obj.Clock);
          % start the 'flip' of the frame onto the screen
          Screen('AsyncFlipBegin', obj.StimWindow.PtbHandle);
          obj.AsyncFlipping = true;
          obj.StimWindowUpdateCount = obj.StimWindowUpdateCount + 1;
          obj.Data.stimWindowRenderTimes(obj.StimWindowUpdateCount) = renderTime;
          obj.StimWindowInvalid = false;
        end
        % make sure some minimum time passes before updating signals, to 
        % improve performance on MC
        if (obj.Clock.now - t) > 0.1 || obj.IsLooping == false
          sendSignalUpdates(obj);
          t = obj.Clock.now;
        end
        
%         q = toc;
%         if q>0.005
%             fprintf(1, 'send updates took %.1fms\n', 1000*toc);
%         end
        drawnow; % allow other callbacks to execute
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
      [pressed, keysPressed] = KbQueueCheck();
      if pressed
        if any(keysPressed(obj.QuitKey))
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
        else
          % Post key presses to inputs.keyboard signal
          key = KbName(keysPressed);
          if ~obj.IsPaused && ~isempty(key)
            if ischar(key) % Post single key press
              post(obj.Inputs.keyboard, key);
            else % Post each key press in order
              [~, I] = sort(keysPressed(keysPressed > 0));
              cellfun(@(k)obj.Inputs.keyboard.post(k), key(I));
            end
          end
        end
      end
    end
    
    function drawFrame(obj)
      % Called to draw current stimulus window frame
      %
      % drawFrame(obj) does nothing in this class but can be overrriden
      % in a subclass to draw the stimulus frame when it is invalidated
      win = obj.StimWindow.PtbHandle;
      layerValues = cell2mat(obj.LayersByStim.values());
      Screen('BeginOpenGL', win);
      vis.draw(win, obj.StimViewingModel, layerValues, obj.TextureById);
      Screen('EndOpenGL', win);
    end
    
    function ex = addErrorCause(obj, ex)
      sigExId = cellfun(@(e) isa(e,'sig.Exception'), ex.cause);
      if any(sigExId) && obj.Net.Debug
        nodeid = ex.cause{sigExId}.Node;
        expdef = iff(ischar(obj.Data.expDef), ...
          obj.Data.expDef, @()which(func2str(obj.Data.expDef)));
        ex = ex.addCause(MException(...
          'Rigbox:exp:SignalsExp:expDefError', ...
          'Error in %s (line %d)\n%s', ...
          expdef, obj.Net.NodeLine(nodeid), obj.Net.NodeName(nodeid)));
      end
    end
    
    function saveData(obj)
      % save the data to the appropriate locations indicated by expRef
      savepaths = dat.expFilePath(obj.Data.expRef, 'block');
      superSave(savepaths, struct('block', obj.Data));
      subject = dat.parseExpRef(obj.Data.expRef);
      
      % Save out for relevant data for basic behavioural analysis and
      % register them to Alyx.
      if ~strcmp(subject, 'default') && isfield(obj.Data, 'events') ...
          && ~strcmp(obj.Data.endStatus,'aborted')
        try
          fullpath = alf.block2ALF(obj.Data);
          obj.AlyxInstance.registerFile(fullpath);
        catch ex
          % If Alyx URL not set, simply return
          if isempty(getOr(dat.paths, 'databaseURL')); return; end
          % Otherwise throw warning and continue registration process
          warning(ex.identifier, 'Failed to register alf files: %s.', ex.message);
        end
      end
      
      if isempty(obj.AlyxInstance)
        warning('Rigbox:exp:SignalsExp:noTokenSet', 'No Alyx token set');
      else
        try
          subject = dat.parseExpRef(obj.Data.expRef);
          if strcmp(subject, 'default'); return; end
          % Register saved files
          obj.AlyxInstance.registerFile(savepaths{end});
          % Save the session end time
          url = obj.AlyxInstance.SessionURL;
          if isempty(url)
            % Infer from date session and retrieve using expFilePath
            url = getOr(obj.AlyxInstance.getSessions(obj.Data.expRef), 'url');
            assert(~isempty(url), 'Failed to determine session url')
          end
          numCorrect = [];
          if isfield(obj.Data, 'events')
            numTrials = length(obj.Data.events.endTrialValues);
            if isfield(obj.Data.events, 'feedbackValues')
              numCorrect = sum(obj.Data.events.feedbackValues == 1);
            end
          else
            numTrials = 0;
            numCorrect = 0;
          end
          % Update Alyx session with end time, trial counts and water tye
          sessionData = struct('end_time', obj.AlyxInstance.datestr(now));
          if ~isempty(numTrials); sessionData.n_trials = numTrials; end
          if ~isempty(numCorrect); sessionData.n_correct_trials = numCorrect; end
          obj.AlyxInstance.postData(url, sessionData, 'patch');
        catch ex
          warning(ex.identifier, 'Failed to register files to Alyx: %s', ex.message);
        end
        % Post water to Alyx
        try
          valve_controller = obj.DaqController.SignalGenerators(strcmp(obj.DaqController.ChannelNames,'rewardValve'));
          type = pick(valve_controller, 'WaterType', 'def', 'Water');
          if isfield(obj.Data.outputs, 'rewardValues')
            amount = sum(obj.Data.outputs.rewardValues)*0.001;
          else
            amount = 0;
          end
          obj.AlyxInstance.postWater(subject, amount, now, type, url);
        catch ex
          warning(ex.identifier, 'Failed to post water to Alyx: %s', ex.message);
        end
      end
    end
  end
  
end