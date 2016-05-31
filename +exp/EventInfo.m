classdef EventInfo
  %EXP.EVENTINFO Experimental event info base class
  %   Provides information about an experimental event that has occured.
  %   This includes the name of the event (Event property), the time 
  %   of the event (Time property), and the experiment concerned
  %   (Experiment property).
  %
  % Part of Rigbox

  % 2012-11 CB created    
  
  properties (SetAccess = protected)
    Event %The name of the event that occurred
    Time %The time the event occured
    Experiment %The Experiment in which the event occurred
  end
  
  methods
    function obj = EventInfo(event, time, experiment)
      obj.Event = event;
      obj.Time = time;
      obj.Experiment = experiment;
    end
    
    function p = param(obj, name)
      %Convenience function for getting current parameters from the
      %associated experiment's condition server
      p = param(obj.Experiment.ConditionServer, name);
    end
  end
  
end