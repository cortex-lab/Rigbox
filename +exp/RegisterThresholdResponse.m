classdef RegisterThresholdResponse < exp.Action
  %EXP.REGISTERTHRESHOLDRESPONSE Register the appropriate response
  %   Convenience action for use with an EventHandler. This maps a
  %   threshold event (the triggering event), to a response (if any), and
  %   registers the response with the experiment. The threshold's ID is
  %   used as an index to lookup the response type. The lookup occurs in
  %   the field 'responseForThreshold' of the current trial's condition.
  %   Any value > 0 is counted as a response, and registered as such with
  %   the experiment. Nothing is done for any other value.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  methods
    function perform(obj, eventInfo, dueTime)
      thresholdCrossed = eventInfo.Id;
      responseForThreshold = param(eventInfo.Experiment.ConditionServer,...
        'responseForThreshold');
      response = responseForThreshold(thresholdCrossed);
      
      if response > 0
        registerResponse(eventInfo.Experiment, response, dueTime)
      end
    end
  end
  
end

