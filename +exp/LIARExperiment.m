classdef LIARExperiment < exp.Experiment
  %EXP.LIAREXPERIMENT Linear Input and Reward experiment
  %   An experiment that receives input from the subject via some kind of
  %   linear position sensor, and provides reward feedback via some special
  %   controller. During the 'interactive' phase, any changes in the input
  %   sensor will 'invalidate' the stimulus window.
  %   See also EXP.EXPERIMENT, HW.WINDOW, HW.POSITIONSENSOR.
  %
  % Part of Rigbox
  
  % 2012-11 CB created
  
  properties
    %An input device for the subject to provide responses. This should be a
    %liner position sensor of class hw.PositionSensor.
    InputSensor
    InputGain = 1 %Input position gain factor
    %A device for delivering reward to the subject. Must be of class
    %hw.RewardController
    RewardController
    LickDetector %A device for recording the number of licks
    %threshold for InputSensor triggering inputThresholdCrossed event
    %during interactive phase
    InputThreshold = []
    RewardPulseKey = KbName('space')
  end
  
  properties (SetAccess = protected)
    InputOffset %Current offset for input sensor position - used for zeroing
    InteractiveInputs % a sequence of columns [t;x]
    
    % A quiescentEpoch event will be triggered when there is no input for
    % this amount of time. When this occurs, the period will then be reset
    % to Inf (i.e. turning off checking)
    RequiredQuiescentPeriod = Inf
    
    % the time (in Clock units) we accrue quiescence from. When this reaches
    % at least RequiredQuiescentPeriod ago, a quiescentEpoch event is
    % triggered. Each time input is made, this will be reset to the current
    % time.
    QuiescentFrom
    QuiescentStartPos % the input pos when the quiescence watch began
    QuiescentWatchName = [] % tag to identify quiescence watch events
    
    LastInputSensorPostTime
  end
  
  methods
    function obj = LIARExperiment()
      setupTriggers(obj);
    end
    
    function deliverReward(obj, sz)
      % TODO make a reward event or something?
      t = obj.Clock.now;
      if nargin < 2
        n = numel(param(obj.ConditionServer, 'rewardVolume'));
        sz = [obj.RewardController.SignalGenerators(1:n).DefaultCommand];
      end
      command(obj.RewardController, sz);
      obj.Data.rewardDeliveredSizes(end + 1,:) = sz;
      obj.Data.rewardDeliveryTimes(end + 1) = t;
      post(obj, 'status',...
        {'update', obj.Data.expRef, 'rewardDelivered', sz, t});
    end
    
    function x = position(obj)
      x = obj.InputGain*(obj.InputSensor.LastPosition - obj.InputOffset);
    end
    
    function registerQuiescentEpoch(obj, time)
      fireEvent(obj, exp.EventInfo([obj.QuiescentWatchName 'Epoch'], time, obj));
    end
    
    function registerQuiescentMovement(obj, time)
      fireEvent(obj, exp.EventInfo([obj.QuiescentWatchName 'Movement'], time, obj));
    end
    
    function registerInteractiveMovement(obj, time)
      fireEvent(obj, exp.EventInfo('interactiveMovement', time, obj));
    end
    
    function registerThresholdCrossing(obj, name, id, time)
      fireEvent(obj, exp.ThresholdEventInfo([name 'ThresholdCrossed'], time, obj, id));
      log(obj, [name 'ThresholdCrossedID'], id);
    end
    
    function registerResponse(obj, id, time)
      fireEvent(obj, exp.ResponseEventInfo('responseMade', time, obj, id));
      log(obj, 'responseMadeID', id);
    end
    
    function calibrateInputGain(obj)
      % set gain to identity, subclasses can override
      obj.InputGain = 1;
    end
    
    function startQuiescenceWatch(obj, name, period)
      %Starts quiescent timer from now, with requested period
      obj.QuiescentFrom = obj.Clock.now;
      obj.RequiredQuiescentPeriod = period;
      obj.QuiescentWatchName = name;
      obj.QuiescentStartPos = readPosition(obj.InputSensor);
      startPhase(obj, 'quiescenceWatch', obj.QuiescentFrom);
    end

    function zeroInputOffset(obj, delta)
      if nargin < 2
        delta = 0;
      end
      [off, t] = readPosition(obj.InputSensor);
%       g = obj.InputGain;
      obj.InputOffset = off - delta;
      log(obj, 'interactiveZeroInputPos', obj.InputOffset);
      %notification into outbox
      post(obj, 'status', {'update', obj.Data.expRef, 'inputSensorPos', 0, t});
      obj.InteractiveInputs = zeros(2, 0);
    end    
  end
  
  methods (Access = protected)
    function checkInput(obj)
      % Checks for and handles inputs during experiment
      
      % let superclass do its input check
      checkInput@exp.Experiment(obj);
      
      if ~isempty(obj.LickDetector)
        % read and log the current lick count
        [nlicks, ~, licked] = readPosition(obj.LickDetector);
        if licked
          fprintf('lick count now %i\n', nlicks);
        end
      end
      
      % read and log the current input position
      [xAbs, time, changed] = readPosition(obj.InputSensor);
      
      if inPhase(obj, 'quiescenceWatch')
        if changed &&... % there was some input change
            abs(xAbs - obj.QuiescentStartPos) >= param(... %and it was over threshold
              obj.ConditionServer, 'quiescenceThreshold')
          % fire event that movement occured during quiescence watch
          obj.QuiescentFrom = time; %reset quiescent time
          obj.QuiescentStartPos = xAbs; % and pos
%           registerQuiescentMovement(obj, time);%disable for now: too slow
        elseif time - obj.QuiescentFrom >= obj.RequiredQuiescentPeriod
          % no movement for at least RequiredQuiescentPeriod, so this counts
          % as a quiescentEpoch - notify any handlers, and reset the quiescent
          % period to Inf (i.e. turn off monitoring)
          endPhase(obj, 'quiescenceWatch', time);
          registerQuiescentEpoch(obj, time);
          obj.RequiredQuiescentPeriod = Inf;
        end
      end
      
      % offset and apply gain to position
      x = obj.InputGain*(xAbs - obj.InputOffset);
      % if in interactive phase, the stimulus can change depending on input
      % position so we invalidate the window if the position has changed
      % since we last checked.
      if inPhase(obj, 'interactive')
        obj.InteractiveInputs(:,end+1) = [time; x];
        if changed
          registerInteractiveMovement(obj, time); 
          % check for threshold crossing
          crossed = find(((obj.InputThreshold < 0) & x <= obj.InputThreshold) |...
            ((obj.InputThreshold > 0) & x >= obj.InputThreshold), 1);
          if ~isempty(crossed)
            % now register the threshold crossing event, the id is the index
            % of the threshold crossed
            registerThresholdCrossing(obj, 'input', crossed, time);
          end
          invalidate(obj.StimWindow);
        end
      end

      % post input sensor updates at ~25Hz/every ~40ms
      if isempty(obj.LastInputSensorPostTime) ||...
          (time - obj.LastInputSensorPostTime) > 99e-3 % make slower for now
        %notification into outbox
        if numel(obj.InputThreshold) == 2
          nx = 2*x/diff(obj.InputThreshold); %threshold normalised position
        else
          nx = 0;
        end
        post(obj, 'status', {'update', obj.Data.expRef, 'inputSensorPos', nx, time});
        obj.LastInputSensorPostTime = time;
      end
    end
    
    function setupTriggers(obj)
      % set a trigger to zero the input sensor as soon as interative phase
      % starts
      zeroInput = exp.EventHandler('interactiveStarted');
      zeroInput.addCallback(@(~, ~) zeroInputOffset(obj));
      addEventHandler(obj, zeroInput);
    end
    
    function init(obj)
      init@exp.Experiment(obj); % do superclass init
      % clear the data log in the inputsensor and the reward controller
      obj.InputSensor.clearData();
      %initialise input offset with current position
      obj.InputOffset = readPosition(obj.InputSensor);
      obj.Data.rewardDeliveredSizes = [];
      obj.Data.rewardDeliveryTimes = [];
      obj.RequiredQuiescentPeriod = Inf; % reset quiescence watch
      if ~isempty(obj.LickDetector)
        obj.LickDetector.clearData();
        obj.LickDetector.zero();
      end
    end
    
    function t = lastMovementTime(obj)
      i = find(diff(obj.InputSensor.Positions), 1, 'last') + 1;
      t = obj.InputSensor.PositionTimes(i);
    end
    
    function cleanup(obj)
      cleanup@exp.Experiment(obj);
      % save the logged data from the InputSensor and the RewardController
      obj.Data.inputSensorPositions = obj.InputSensor.Positions;
      obj.Data.inputSensorPositionTimes = obj.InputSensor.PositionTimes;
      obj.Data.inputSensorGain = obj.InputGain;
%       obj.Data.rewardDeliveredSizes = obj.RewardController.DeliveredSizes;
%       obj.Data.rewardDeliveryTimes = obj.RewardController.DeliveryTimes;
      if ~isempty(obj.LickDetector)
        obj.Data.lickCounts = obj.LickDetector.Positions;
        obj.Data.lickCountTimes = obj.LickDetector.PositionTimes;
      else
        obj.Data.lickCounts = [];
        obj.Data.lickCountTimes = [];
      end
    end
    
    function handleKeyboardInput(obj, keysPressed, keysReleased)
      handleKeyboardInput@exp.Experiment(obj, keysPressed, keysReleased);
      if any(keysPressed(obj.RewardPulseKey))
        deliverReward(obj);
      end
    end
  end
  
end

