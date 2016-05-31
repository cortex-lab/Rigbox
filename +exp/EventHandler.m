classdef (Sealed) EventHandler < handle
  %EXP.EVENTHANDLER Performs actions following an event
  %   Contains callbacks that will be executed following an event,
  %   optionally with a specific delay after the event occurs.
  %
  % The Event property contains the name of the event that is handled. The
  % Delay property specifies a delay before executing the callbacks. If the 
  % delay is set to 'false', the event will execute callbacks immediately.
  %
  % Use addCallback(callback) to add callback functions that get called on
  % triggering, and addAction(action) to add a TriggerAction (which used to
  % perform common actions). See also EXP.EXPERIMENT.
  %
  % Part of Rigbox

  % 2012-11 CB created
  % 2013-02 CB modified
  
  properties
    %The event to be handled
    Event

    %Delay following the handled event, after which the callbacks will be
    %executed. This can be false (which requests actions happen immediately 
    %after the event), or an object with a secs() function specifying the 
    %delay (which e.g. can change each time the event occurs). Setting the 
    %Delay to some number, NUM is shorthand for setting it to
    %an exp.FixedTime(NUM). Setting it to a two element vector, [MIN, MAX]
    %is shorthand for setting it to an exp.UniformInterval(MIN, MAX).
    Delay = false

    %If true, the stimulus window of the experiment will be invalidated
    %after this handler's callback functions are executed.
    InvalidateStimWindow = false
  end
  
  properties (Access = protected)
    %A cell array of callback functions. These will be called when 
    %activated. The functions are always called in order.
    Callback = {}
  end
  
  methods
    function obj = EventHandler(event, action)
      obj.Event = event;
      if nargin > 1
        obj.addAction(action)
      end
    end
    
    function activate(obj, eventInfo, dueTime)
      n = numel(obj.Callback);
      for i = 1:n
        obj.Callback{i}(eventInfo, dueTime);
      end
    end
    
    function addAction(obj, action, varargin)
      % Adds one or more actions to be performed when activated
      %
      % addAction(ACTION) adds the action, ACTION, to be performed when
      % activated. ACTION must be an object of class Action, or a cell
      % array of them.
            
      if ~iscell(action)
        action = {action}; % so we can use same code below
      end
      
      % add callbacks for performing each action
      for i = 1:numel(action)
        a = action{i};
        obj.addCallback(@a.perform);
      end
      
      % handle varargs (of extra actions) recursively
      if ~isempty(varargin)
        addAction(obj, varargin{:});
      end
    end

    function addCallback(obj, callback)
      % Adds one or more functions to be called when fired
      %
      % addAction(CALLBACK) adds the specified function, CALLBACK, to be
      % called when the trigger is set off. CALLBACK must be a function
      % (or cell array of functions) that takes two arguments: 1) an 
      % EventInfo object containing useful information about the event, 2)
      % the time event handler was actually due to be activated.

      obj.Callback = cat(2, obj.Callback, {callback});
    end

    function set.Delay(obj, value)
      if (islogical(value) && value == false)
        % Delay is false means handler executes immediately after the event
        obj.Delay = false;
      else
        obj.Delay = exp.TimeSampler.using(value);
      end
    end
  end
  
end

