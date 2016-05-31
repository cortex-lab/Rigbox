classdef RegisterNoGoResponse < exp.Action
  %EXP.REGISTERNOGORESPONSE Register the appropriate response
  %   Convenience action for use with an EventHandler. This maps a
  %   no go event, to a response ID, and registers the response with the
  %   experiment. The lookup occurs in the field 'responseForNoGo' of the
  %   current trial's condition.
  %   Any value > 0 is counted as a response, and registered as such with
  %   the experiment. Nothing is done for any other value.
  %
  % Part of Rigbox

  % 2012-11 CB created
  
  methods
    function perform(obj, eventInfo, dueTime)
      noGoResponse = param(eventInfo.Experiment.ConditionServer,...
        'responseForNoGo');
      if noGoResponse > 0
        registerResponse(eventInfo.Experiment, noGoResponse, dueTime);
      end
    end
  end
  
end

